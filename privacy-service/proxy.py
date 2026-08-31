import asyncio
import codecs
import hashlib
import json
import os
import re
import tempfile
from collections import OrderedDict
from pathlib import Path

import httpx
from fastapi import HTTPException, Request
from fastapi.responses import Response, StreamingResponse

from app import (
    app,
    assign_session_token,
    create_session,
    delete_session,
    local_route,
    nosey_parker_spans,
    presidio_spans,
    resolve_overlaps,
    sessions,
)

UPSTREAM_BASE = os.environ.get(
    "UPSTREAM_BASE",
    "https://chatgpt.com/backend-api/codex",
)

# Protocol identifiers which must never be rewritten.
SKIP_STRING_KEYS = {
    "type",
    "role",
    "id",
    "call_id",
    "name",
    "namespace",
    "status",
    "model",
    "image_url",
    "audio_url",
    "encrypted_content",
}

# Codex tool definitions contain large static schemas/descriptions.
# They are protocol metadata, not conversation/workspace content.
SKIP_SUBTREE_KEYS = {
    "tools",
}

PRESIDIO_CACHE = OrderedDict()
PRESIDIO_CACHE_FILE = "/app/cache/presidio-cache.json"
MAX_REQUEST_BODY_BYTES = int(os.environ.get("MAX_REQUEST_BODY_BYTES", "524288"))
MAX_REQUEST_JSON_DEPTH = int(os.environ.get("MAX_REQUEST_JSON_DEPTH", "32"))
MAX_REQUEST_FIELD_COUNT = int(os.environ.get("MAX_REQUEST_FIELD_COUNT", "4096"))
MAX_REQUEST_TEXT_SLOTS = int(os.environ.get("MAX_REQUEST_TEXT_SLOTS", "512"))
MAX_REQUEST_TEXT_BYTES = int(os.environ.get("MAX_REQUEST_TEXT_BYTES", "200000"))
MAX_RESPONSE_CONCURRENCY = int(os.environ.get("MAX_RESPONSE_CONCURRENCY", "4"))
RESPONSE_QUEUE_WAIT_SECONDS = float(os.environ.get("RESPONSE_QUEUE_WAIT_SECONDS", "0.1"))
PRESIDIO_SCAN_CONCURRENCY = int(os.environ.get("PRESIDIO_SCAN_CONCURRENCY", "1"))
PRESIDIO_CACHE_MAX_ENTRIES = int(os.environ.get("PRESIDIO_CACHE_MAX_ENTRIES", "2048"))
PRESIDIO_CACHE_MAX_BYTES = int(os.environ.get("PRESIDIO_CACHE_MAX_BYTES", "8388608"))
UPSTREAM_CONNECT_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_CONNECT_TIMEOUT_SECONDS", "15"))
UPSTREAM_WRITE_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_WRITE_TIMEOUT_SECONDS", "60"))
UPSTREAM_READ_TIMEOUT_SECONDS = float(os.environ.get("UPSTREAM_READ_TIMEOUT_SECONDS", "300"))
PRESIDIO_CHUNK_SIZE = int(os.environ.get("PRESIDIO_CHUNK_SIZE", "4000"))
PRESIDIO_CHUNK_OVERLAP = int(os.environ.get("PRESIDIO_CHUNK_OVERLAP", "1024"))
PRESIDIO_CACHE_KEY_VERSION = "v2"
PRESIDIO_CACHE_FINGERPRINT_OVERRIDE = os.environ.get("PRESIDIO_CACHE_FINGERPRINT", "").strip()
APP_VERSION_FILE = os.environ.get("APP_VERSION_FILE", "/app/VERSION")
PRESIDIO_CONFIG_FINGERPRINT_FILE = os.environ.get(
    "PRESIDIO_CONFIG_FINGERPRINT_FILE",
    "/app/analyzer-config.yaml",
)

RESPONSE_SEMAPHORE = asyncio.Semaphore(MAX_RESPONSE_CONCURRENCY)
PRESIDIO_SCAN_SEMAPHORE = asyncio.Semaphore(PRESIDIO_SCAN_CONCURRENCY)


def hash_file_if_present(path: str):
    candidate = Path(path)
    if not candidate.is_file():
        return "missing"
    return hashlib.sha256(candidate.read_bytes()).hexdigest()


def build_presidio_cache_fingerprint():
    if PRESIDIO_CACHE_FINGERPRINT_OVERRIDE:
        return PRESIDIO_CACHE_FINGERPRINT_OVERRIDE

    parts = [
        f"version_file={hash_file_if_present(APP_VERSION_FILE)}",
        f"presidio_config={hash_file_if_present(PRESIDIO_CONFIG_FINGERPRINT_FILE)}",
        f"request_text_limit={MAX_REQUEST_TEXT_BYTES}",
        f"chunking={PRESIDIO_CHUNK_SIZE}:{PRESIDIO_CHUNK_OVERLAP}",
    ]
    serialized = "|".join(parts)
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


PRESIDIO_CACHE_FINGERPRINT = build_presidio_cache_fingerprint()

def load_presidio_cache():
    try:
        with open(PRESIDIO_CACHE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict):
                for key, value in data.items():
                    if not key.startswith(f"chunk-{PRESIDIO_CACHE_KEY_VERSION}:"):
                        continue
                    PRESIDIO_CACHE[key] = value
                prune_presidio_cache()
    except FileNotFoundError:
        pass
    except Exception as exc:
        print(json.dumps({"cache_load_error": type(exc).__name__}), flush=True)


def save_presidio_cache():
    try:
        os.makedirs(os.path.dirname(PRESIDIO_CACHE_FILE), exist_ok=True)
        with tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            dir=os.path.dirname(PRESIDIO_CACHE_FILE),
            delete=False,
        ) as tmp:
            json.dump(dict(PRESIDIO_CACHE), tmp, ensure_ascii=False)
            temp_name = tmp.name
        os.replace(temp_name, PRESIDIO_CACHE_FILE)
    except Exception as exc:
        print(json.dumps({"cache_save_error": type(exc).__name__}), flush=True)


def estimate_cache_entry_bytes(cache_key, spans):
    payload = json.dumps(spans, ensure_ascii=False, separators=(",", ":"))
    return len(cache_key.encode("utf-8")) + len(payload.encode("utf-8"))


def cache_size_bytes():
    return sum(
        estimate_cache_entry_bytes(cache_key, spans)
        for cache_key, spans in PRESIDIO_CACHE.items()
    )


def prune_presidio_cache():
    while (
        len(PRESIDIO_CACHE) > PRESIDIO_CACHE_MAX_ENTRIES
        or cache_size_bytes() > PRESIDIO_CACHE_MAX_BYTES
    ):
        PRESIDIO_CACHE.popitem(last=False)


def get_cached_presidio_spans(cache_key):
    spans = PRESIDIO_CACHE.get(cache_key)
    if spans is None:
        return None
    PRESIDIO_CACHE.move_to_end(cache_key)
    return spans


def store_cached_presidio_spans(entries):
    if not entries:
        return

    for cache_key, spans in entries:
        PRESIDIO_CACHE[cache_key] = spans
        PRESIDIO_CACHE.move_to_end(cache_key)

    prune_presidio_cache()
    save_presidio_cache()


def build_presidio_cache_key(chunk_text: str, language: str):
    chunk_hash = hashlib.sha256(chunk_text.encode("utf-8")).hexdigest()
    return (
        f"chunk-{PRESIDIO_CACHE_KEY_VERSION}:"
        f"{PRESIDIO_CACHE_FINGERPRINT}:"
        f"{language}:"
        f"{chunk_hash}"
    )


def enforce_cross_boundary_entity_limit(text: str):
    if len(text) <= PRESIDIO_CHUNK_SIZE:
        return

    for boundary in range(PRESIDIO_CHUNK_SIZE, len(text), PRESIDIO_CHUNK_SIZE):
        left = boundary - 1
        right = boundary

        if left < 0 or right >= len(text):
            continue

        if text[left].isspace() or text[right].isspace():
            continue

        start = left
        while start > 0 and not text[start - 1].isspace():
            start -= 1

        end = right
        while end < len(text) and not text[end].isspace():
            end += 1

        if end - start > PRESIDIO_CHUNK_OVERLAP:
            raise RuntimeError(
                "Potential boundary-crossing entity exceeds supported visibility window"
            )


load_presidio_cache()


HOP_BY_HOP_HEADERS = {
    "host",
    "content-length",
    "connection",
    "transfer-encoding",
    "content-encoding",
    "accept-encoding",
}

ALLOWED_REQUEST_HEADERS = {
    "authorization",
    "content-type",
    "accept",
    "openai-beta",
}

ALLOWED_QUERY_PARAMS = {
    "include",
}

ALLOWED_RESPONSE_TOP_LEVEL_KEYS = {
    "background",
    "conversation",
    "include",
    "input",
    "instructions",
    "max_output_tokens",
    "metadata",
    "model",
    "parallel_tool_calls",
    "previous_response_id",
    "prompt_cache_key",
    "reasoning",
    "service_tier",
    "store",
    "stream",
    "stream_options",
    "temperature",
    "text",
    "tool_choice",
    "tools",
    "top_logprobs",
    "top_p",
    "truncation",
    "user",
}

MAX_STRING_LENGTH = 200000
MAX_ARRAY_LENGTH = 256
MAX_OBJECT_KEYS = 256
MAX_METADATA_KEYS = 16
MAX_METADATA_KEY_LENGTH = 64
MAX_METADATA_VALUE_LENGTH = 512
MAX_TOOL_COUNT = 128
MAX_INCLUDE_COUNT = 32

SUPPORTED_INCLUDE_VALUES = {
    "code_interpreter_call.outputs",
    "computer_call_output.output.image_url",
    "file_search_call.results",
    "message.input_image.image_url",
    "message.output_text.logprobs",
    "reasoning.encrypted_content",
    "web_search_call.action.sources",
}

SUPPORTED_REASONING_EFFORTS = {
    "low",
    "medium",
    "high",
}

SUPPORTED_TEXT_VERBOSITY = {
    "low",
    "medium",
    "high",
}

SUPPORTED_TRUNCATION = {
    "auto",
    "disabled",
}

SUPPORTED_TOOL_CHOICE_STRINGS = {
    "none",
    "auto",
    "required",
}

SUPPORTED_TEXT_FORMAT_TYPES = {
    "text",
    "json_object",
}

SUPPORTED_SIMPLE_TOOL_TYPES = {
    "apply_patch",
    "code_interpreter",
    "computer_use_preview",
    "file_search",
    "image_generation",
    "shell",
    "web_search_preview",
}


def forward_request_headers(request: Request):
    return {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }


def build_upstream_request_headers(request: Request):
    forwarded = {}

    for key, value in request.headers.items():
        lowered = key.lower()

        if lowered in HOP_BY_HOP_HEADERS:
            continue

        if lowered not in ALLOWED_REQUEST_HEADERS:
            continue

        forwarded[key] = value

    return forwarded


def build_upstream_query_params(request: Request):
    forwarded = []

    for key, value in request.query_params.multi_items():
        if key not in ALLOWED_QUERY_PARAMS:
            continue

        forwarded.append((key, value))

    return forwarded


def forward_response_headers(headers):
    return {
        key: value
        for key, value in headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }


def collect_text_slots(value, slots, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            slots.append({
                "text": value,
            })
        return

    if isinstance(value, list):
        for item in value:
            collect_text_slots(item, slots)
        return

    if isinstance(value, dict):
        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                continue

            collect_text_slots(
                child_value,
                slots,
                child_key,
            )


def build_secret_corpus(slots):
    parts = []
    ranges = []
    offset = 0

    for index, slot in enumerate(slots):
        text = slot["text"]

        start = offset
        parts.append(text)
        offset += len(text)
        end = offset

        ranges.append({
            "slot": index,
            "start": start,
            "end": end,
        })

    return "".join(parts), ranges


def enforce_request_limits(payload):
    metrics = {
        "field_count": 0,
        "text_slots": 0,
        "text_bytes": 0,
    }

    def walk(value, depth):
        if depth > MAX_REQUEST_JSON_DEPTH:
            fail_invalid_request("body", "JSON nesting too deep")

        if isinstance(value, dict):
            metrics["field_count"] += len(value)
            if metrics["field_count"] > MAX_REQUEST_FIELD_COUNT:
                fail_invalid_request("body", "too many fields")
            for child in value.values():
                walk(child, depth + 1)
            return

        if isinstance(value, list):
            metrics["field_count"] += len(value)
            if metrics["field_count"] > MAX_REQUEST_FIELD_COUNT:
                fail_invalid_request("body", "too many fields")
            for item in value:
                walk(item, depth + 1)
            return

        if isinstance(value, str) and value.strip():
            metrics["text_slots"] += 1
            if metrics["text_slots"] > MAX_REQUEST_TEXT_SLOTS:
                fail_invalid_request("body", "too many text slots")
            metrics["text_bytes"] += len(value.encode("utf-8"))
            if metrics["text_bytes"] > MAX_REQUEST_TEXT_BYTES:
                fail_invalid_request("body", "aggregate text too large")

    walk(payload, 1)


async def acquire_capacity(semaphore, timeout_seconds, busy_detail):
    try:
        await asyncio.wait_for(
            semaphore.acquire(),
            timeout=timeout_seconds,
        )
    except TimeoutError:
        raise HTTPException(
            status_code=429,
            detail=busy_detail,
        )


async def scan_presidio_unique(slots, language):
    chunk_size = PRESIDIO_CHUNK_SIZE
    overlap = PRESIDIO_CHUNK_OVERLAP

    unique_texts = list(dict.fromkeys(
        slot["text"]
        for slot in slots
    ))

    text_chunks = {}
    missing_chunks = {}
    for text in unique_texts:
        enforce_cross_boundary_entity_limit(text)
        chunks = []

        for core_start in range(0, len(text), chunk_size):
            core_end = min(len(text), core_start + chunk_size)
            scan_start = max(0, core_start - overlap)
            scan_end = min(len(text), core_end + overlap)
            chunk_text = text[scan_start:scan_end]
            cache_key = build_presidio_cache_key(
                chunk_text,
                language,
            )

            hit = get_cached_presidio_spans(cache_key) is not None

            chunks.append({
                "core_start": core_start,
                "core_end": core_end,
                "scan_start": scan_start,
                "cache_key": cache_key,
            })

            if not hit:
                missing_chunks[cache_key] = chunk_text

        text_chunks[text] = chunks

    async def scan(cache_key, chunk_text):
        await acquire_capacity(
            PRESIDIO_SCAN_SEMAPHORE,
            RESPONSE_QUEUE_WAIT_SECONDS,
            "Presidio scanner is busy",
        )
        try:
            spans = await presidio_spans(chunk_text, language)
            return cache_key, spans
        finally:
            PRESIDIO_SCAN_SEMAPHORE.release()

    if missing_chunks:
        scanned = []
        for cache_key, chunk_text in missing_chunks.items():
            scanned.append(
                await scan(
                    cache_key,
                    chunk_text,
                )
            )

        store_cached_presidio_spans(scanned)

    results = {}

    for text, chunks in text_chunks.items():
        mapped = []

        for chunk in chunks:
            spans = get_cached_presidio_spans(chunk["cache_key"])

            for span in spans:
                absolute_start = chunk["scan_start"] + span["start"]
                absolute_end = chunk["scan_start"] + span["end"]

                if chunk["core_start"] <= absolute_start < chunk["core_end"]:
                    mapped.append({
                        **span,
                        "start": absolute_start,
                        "end": absolute_end,
                    })

        results[text] = mapped

    return results

def apply_spans(text, spans, session):
    output = text

    for span in reversed(spans):
        original = text[span["start"]:span["end"]]
        token = assign_token(
            session,
            span["entity_type"],
            original,
        )

        output = (
            output[:span["start"]]
            + token
            + output[span["end"]:]
        )

    return output


def assign_token(session, entity_type, original):
    return assign_session_token(
        session,
        entity_type,
        original,
    )


def apply_corpus_spans_to_slots(corpus, slots, spans, ranges, session):
    replacements = [
        slot["text"]
        for slot in slots
    ]

    for span in reversed(spans):
        original = corpus[span["start"]:span["end"]]
        token = assign_token(
            session,
            span["entity_type"],
            original,
        )

        overlaps = []

        for item in ranges:
            if (
                span["start"] < item["end"]
                and span["end"] > item["start"]
            ):
                overlaps.append(item)

        if not overlaps:
            continue

        for overlap_index, item in enumerate(overlaps):
            slot_index = item["slot"]
            relative_start = max(
                span["start"],
                item["start"],
            ) - item["start"]
            relative_end = min(
                span["end"],
                item["end"],
            ) - item["start"]

            replacement_text = token if overlap_index == 0 else ""
            current = replacements[slot_index]
            replacements[slot_index] = (
                current[:relative_start]
                + replacement_text
                + current[relative_end:]
            )

    return replacements


def replace_text_slots(value, replacements, index_ref, key=None):
    if isinstance(value, str):
        if key not in SKIP_STRING_KEYS and value.strip():
            replacement = replacements[index_ref[0]]
            index_ref[0] += 1
            return replacement

        return value

    if isinstance(value, list):
        return [
            replace_text_slots(
                item,
                replacements,
                index_ref,
            )
            for item in value
        ]

    if isinstance(value, dict):
        result = {}

        for child_key, child_value in value.items():
            if child_key in SKIP_SUBTREE_KEYS:
                result[child_key] = child_value
                continue

            result[child_key] = replace_text_slots(
                child_value,
                replacements,
                index_ref,
                child_key,
            )

        return result

    return value


async def protect_payload_input(value, session, language="lt"):
    slots = []
    collect_text_slots(value, slots)

    if not slots:
        return value

    corpus, ranges = build_secret_corpus(slots)

    nosey_task = asyncio.to_thread(
        nosey_parker_spans,
        corpus,
    )

    presidio_task = scan_presidio_unique([
        {
            "text": corpus,
        }
    ], language)

    secret_spans, pii_by_text = await asyncio.gather(
        nosey_task,
        presidio_task,
    )

    all_spans = resolve_overlaps(
        secret_spans
        + pii_by_text.get(corpus, []),
    )

    replacements = apply_corpus_spans_to_slots(
        corpus,
        slots,
        all_spans,
        ranges,
        session,
    )

    return replace_text_slots(
        value,
        replacements,
        [0],
    )


def fail_invalid_request(path, message):
    raise HTTPException(status_code=400, detail=f"{path}: {message}")


def ensure_type(path, value, expected_type, message):
    if not isinstance(value, expected_type):
        fail_invalid_request(path, message)


def ensure_string(path, value, allow_empty=False, max_length=MAX_STRING_LENGTH):
    ensure_type(path, value, str, "expected string")
    if not allow_empty and not value.strip():
        fail_invalid_request(path, "must not be empty")
    if len(value) > max_length:
        fail_invalid_request(path, "string too long")
    return value


def ensure_bool(path, value):
    ensure_type(path, value, bool, "expected boolean")
    return value


def ensure_number(path, value):
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        fail_invalid_request(path, "expected number")
    return value


def ensure_int(path, value):
    if not isinstance(value, int) or isinstance(value, bool):
        fail_invalid_request(path, "expected integer")
    return value


def ensure_list(path, value, max_length=MAX_ARRAY_LENGTH):
    ensure_type(path, value, list, "expected array")
    if len(value) > max_length:
        fail_invalid_request(path, "array too long")
    return value


def ensure_dict(path, value, max_keys=MAX_OBJECT_KEYS):
    ensure_type(path, value, dict, "expected object")
    if len(value) > max_keys:
        fail_invalid_request(path, "object has too many keys")
    return value


def reject_unknown_keys(path, value, allowed_keys):
    unknown = sorted(set(value.keys()) - allowed_keys)
    if unknown:
        fail_invalid_request(path, "unsupported keys: " + ", ".join(unknown))


async def sanitize_content_field(path, value, session, allow_empty=False):
    if isinstance(value, str):
        ensure_string(path, value, allow_empty=allow_empty)
        return await protect_payload_input(value, session)
    if isinstance(value, list):
        ensure_list(path, value)
        return await protect_payload_input(value, session)
    if isinstance(value, dict):
        ensure_dict(path, value)
        return await protect_payload_input(value, session)
    fail_invalid_request(path, "unsupported content-bearing field type")


def sanitize_metadata(path, value):
    metadata = ensure_dict(path, value, max_keys=MAX_METADATA_KEYS)
    sanitized = {}
    for key, item in metadata.items():
        ensure_string(f"{path}.{key}", key, allow_empty=False, max_length=MAX_METADATA_KEY_LENGTH)
        ensure_string(f"{path}.{key}", item, allow_empty=True, max_length=MAX_METADATA_VALUE_LENGTH)
        sanitized[key] = item
    return sanitized


def sanitize_include(path, value):
    items = ensure_list(path, value, max_length=MAX_INCLUDE_COUNT)
    sanitized = []
    for index, item in enumerate(items):
        item_path = f"{path}[{index}]"
        ensure_string(item_path, item, allow_empty=False)
        if item not in SUPPORTED_INCLUDE_VALUES:
            fail_invalid_request(item_path, "unsupported include value")
        sanitized.append(item)
    return sanitized


def sanitize_conversation(path, value):
    if isinstance(value, str):
        return ensure_string(path, value, allow_empty=False)
    obj = ensure_dict(path, value)
    reject_unknown_keys(path, obj, {"id"})
    conversation_id = ensure_string(f"{path}.id", obj.get("id"), allow_empty=False)
    return {"id": conversation_id}


def sanitize_reasoning(path, value):
    obj = ensure_dict(path, value)
    reject_unknown_keys(path, obj, {"effort", "generate_summary", "summary"})
    sanitized = {}
    if "effort" in obj:
        effort = ensure_string(f"{path}.effort", obj["effort"], allow_empty=False)
        if effort not in SUPPORTED_REASONING_EFFORTS:
            fail_invalid_request(f"{path}.effort", "unsupported reasoning effort")
        sanitized["effort"] = effort
    if "generate_summary" in obj:
        sanitized["generate_summary"] = ensure_bool(f"{path}.generate_summary", obj["generate_summary"])
    if "summary" in obj:
        sanitized["summary"] = ensure_string(f"{path}.summary", obj["summary"], allow_empty=False)
    return sanitized


def sanitize_text_config(path, value):
    obj = ensure_dict(path, value)
    reject_unknown_keys(path, obj, {"format", "verbosity"})
    sanitized = {}
    if "format" in obj:
        sanitized["format"] = sanitize_text_format(
            f"{path}.format",
            obj["format"],
        )
    if "verbosity" in obj:
        verbosity = ensure_string(f"{path}.verbosity", obj["verbosity"], allow_empty=False)
        if verbosity not in SUPPORTED_TEXT_VERBOSITY:
            fail_invalid_request(f"{path}.verbosity", "unsupported verbosity")
        sanitized["verbosity"] = verbosity
    return sanitized


def sanitize_text_format(path, value):
    obj = ensure_dict(path, value)
    reject_unknown_keys(path, obj, {"type"})

    if "type" not in obj:
        fail_invalid_request(path, "format object must include type")

    format_type = ensure_string(
        f"{path}.type",
        obj["type"],
        allow_empty=False,
    )

    if format_type not in SUPPORTED_TEXT_FORMAT_TYPES:
        fail_invalid_request(
            f"{path}.type",
            "unsupported text format type",
        )

    return {
        "type": format_type,
    }


def sanitize_stream_options(path, value):
    obj = ensure_dict(path, value)
    reject_unknown_keys(path, obj, {"include_obfuscation"})
    sanitized = {}
    if "include_obfuscation" in obj:
        sanitized["include_obfuscation"] = ensure_bool(f"{path}.include_obfuscation", obj["include_obfuscation"])
    return sanitized


def sanitize_tool_choice(path, value):
    if isinstance(value, str):
        choice = ensure_string(path, value, allow_empty=False)
        if choice not in SUPPORTED_TOOL_CHOICE_STRINGS:
            fail_invalid_request(path, "unsupported tool_choice value")
        return choice
    fail_invalid_request(
        path,
        "tool_choice object form is not yet supported by the safe allowlist",
    )


async def sanitize_tools(path, value, session):
    tools = ensure_list(path, value, max_length=MAX_TOOL_COUNT)
    sanitized = []
    for index, item in enumerate(tools):
        item_path = f"{path}[{index}]"
        tool = ensure_dict(item_path, item)
        if "type" not in tool:
            fail_invalid_request(item_path, "tool must include type")
        tool_type = ensure_string(f"{item_path}.type", tool["type"], allow_empty=False)
        if tool_type not in SUPPORTED_SIMPLE_TOOL_TYPES:
            fail_invalid_request(
                item_path,
                "tool type is not yet supported by the safe allowlist",
            )
        reject_unknown_keys(item_path, tool, {"type"})
        sanitized.append({"type": tool_type})
    return sanitized


async def build_responses_request(payload, session):
    body = ensure_dict("body", payload)
    reject_unknown_keys("body", body, ALLOWED_RESPONSE_TOP_LEVEL_KEYS)

    if "model" not in body:
        fail_invalid_request("body.model", "missing required field")
    if "input" not in body:
        fail_invalid_request("body.input", "missing required field")

    sanitized = {
        "model": ensure_string("body.model", body["model"], allow_empty=False),
        "input": await sanitize_content_field("body.input", body["input"], session),
    }

    if "background" in body:
        sanitized["background"] = ensure_bool("body.background", body["background"])
    if "conversation" in body:
        sanitized["conversation"] = sanitize_conversation("body.conversation", body["conversation"])
    if "include" in body:
        sanitized["include"] = sanitize_include("body.include", body["include"])
    if "instructions" in body:
        sanitized["instructions"] = await sanitize_content_field("body.instructions", body["instructions"], session)
    if "max_output_tokens" in body:
        sanitized["max_output_tokens"] = ensure_int("body.max_output_tokens", body["max_output_tokens"])
    if "metadata" in body:
        sanitized["metadata"] = sanitize_metadata("body.metadata", body["metadata"])
    if "parallel_tool_calls" in body:
        sanitized["parallel_tool_calls"] = ensure_bool("body.parallel_tool_calls", body["parallel_tool_calls"])
    if "previous_response_id" in body:
        sanitized["previous_response_id"] = ensure_string("body.previous_response_id", body["previous_response_id"], allow_empty=False)
    if "prompt_cache_key" in body:
        sanitized["prompt_cache_key"] = ensure_string("body.prompt_cache_key", body["prompt_cache_key"], allow_empty=False)
    if "reasoning" in body:
        sanitized["reasoning"] = sanitize_reasoning("body.reasoning", body["reasoning"])
    if "service_tier" in body:
        sanitized["service_tier"] = ensure_string("body.service_tier", body["service_tier"], allow_empty=False)
    if "store" in body:
        sanitized["store"] = ensure_bool("body.store", body["store"])
    if "stream" in body:
        sanitized["stream"] = ensure_bool("body.stream", body["stream"])
    if "stream_options" in body:
        sanitized["stream_options"] = sanitize_stream_options("body.stream_options", body["stream_options"])
    if "temperature" in body:
        sanitized["temperature"] = ensure_number("body.temperature", body["temperature"])
    if "text" in body:
        sanitized["text"] = sanitize_text_config("body.text", body["text"])
    if "tool_choice" in body:
        sanitized["tool_choice"] = sanitize_tool_choice("body.tool_choice", body["tool_choice"])
    if "tools" in body:
        sanitized["tools"] = await sanitize_tools("body.tools", body["tools"], session)
    if "top_logprobs" in body:
        sanitized["top_logprobs"] = ensure_int("body.top_logprobs", body["top_logprobs"])
    if "top_p" in body:
        sanitized["top_p"] = ensure_number("body.top_p", body["top_p"])
    if "truncation" in body:
        truncation = ensure_string("body.truncation", body["truncation"], allow_empty=False)
        if truncation not in SUPPORTED_TRUNCATION:
            fail_invalid_request("body.truncation", "unsupported truncation value")
        sanitized["truncation"] = truncation
    if "user" in body:
        sanitized["user"] = ensure_string("body.user", body["user"], allow_empty=False)

    return sanitized


def make_stream_restorer(session):
    replacements = {
        token: json.dumps(
            original,
            ensure_ascii=False,
        )[1:-1]
        for token, original
        in session["token_to_value"].items()
    }

    pending = ""
    decoder = codecs.getincrementaldecoder("utf-8")()

    def restore_text_value(text):
        for token, escaped_original in replacements.items():
            text = text.replace(
                token,
                escaped_original,
            )

        return text

    def restore_content_part(part):
        if not isinstance(part, dict):
            return part

        part_type = part.get("type")

        if part_type == "output_text" and isinstance(part.get("text"), str):
            updated = dict(part)
            updated["text"] = restore_text_value(
                updated["text"]
            )
            return updated

        if part_type == "refusal" and isinstance(part.get("refusal"), str):
            updated = dict(part)
            updated["refusal"] = restore_text_value(
                updated["refusal"]
            )
            return updated

        return part

    def restore_output_item(item):
        if not isinstance(item, dict):
            return item

        if (
            item.get("type") != "message"
            or item.get("role") != "assistant"
        ):
            return item

        content = item.get("content")

        if not isinstance(content, list):
            return item

        updated = dict(item)
        updated["content"] = [
            restore_content_part(part)
            for part in content
        ]
        return updated

    def restore_response_object(response):
        if not isinstance(response, dict):
            return response

        updated = dict(response)
        output = updated.get("output")

        if isinstance(output, list):
            updated["output"] = [
                restore_output_item(item)
                for item in output
            ]

        return updated

    def restore_event_payload(payload):
        if not isinstance(payload, dict):
            return payload

        event_type = payload.get("type")
        updated = dict(payload)

        if (
            event_type == "response.output_text.delta"
            and isinstance(updated.get("delta"), str)
        ):
            updated["delta"] = restore_text_value(
                updated["delta"]
            )
            return updated

        if (
            event_type == "response.output_text.done"
            and isinstance(updated.get("text"), str)
        ):
            updated["text"] = restore_text_value(
                updated["text"]
            )
            return updated

        if (
            event_type == "response.refusal.delta"
            and isinstance(updated.get("delta"), str)
        ):
            updated["delta"] = restore_text_value(
                updated["delta"]
            )
            return updated

        if (
            event_type == "response.refusal.done"
            and isinstance(updated.get("refusal"), str)
        ):
            updated["refusal"] = restore_text_value(
                updated["refusal"]
            )
            return updated

        if event_type in {
            "response.content_part.added",
            "response.content_part.done",
        }:
            updated["part"] = restore_content_part(
                updated.get("part")
            )
            return updated

        if event_type == "response.output_item.done":
            updated["item"] = restore_output_item(
                updated.get("item")
            )
            return updated

        if event_type in {
            "response.created",
            "response.completed",
            "response.incomplete",
            "response.failed",
        }:
            updated["response"] = restore_response_object(
                updated.get("response")
            )
            return updated

        return updated

    def process_sse_block(block):
        lines = block.splitlines(keepends=True)
        output_lines = []

        for line in lines:
            if not line.startswith("data:"):
                output_lines.append(line)
                continue

            prefix, value = line.split(":", 1)
            if value.startswith(" "):
                value = value[1:]

            line_ending = ""
            if value.endswith("\r\n"):
                value = value[:-2]
                line_ending = "\r\n"
            elif value.endswith("\n"):
                value = value[:-1]
                line_ending = "\n"

            if value == "[DONE]":
                output_lines.append(line)
                continue

            try:
                payload = json.loads(value)
            except Exception:
                output_lines.append(line)
                continue

            restored_payload = restore_event_payload(
                payload
            )
            serialized = json.dumps(
                restored_payload,
                ensure_ascii=False,
                separators=(",", ":"),
            )
            output_lines.append(
                f"{prefix}: {serialized}{line_ending}"
            )

        return "".join(output_lines)

    def process_complete_text(text):
        if not text:
            return b""

        if "data:" in text or "event:" in text:
            normalized = text.replace("\r\n", "\n")
            blocks = normalized.split("\n\n")

            if len(blocks) > 1:
                completed_blocks = blocks[:-1]
                remainder = blocks[-1]
                rendered = "".join(
                    process_sse_block(block + "\n\n")
                    for block in completed_blocks
                )
                return rendered.encode("utf-8"), remainder

        return b"", text

    def feed(chunk):
        nonlocal pending

        text = pending + decoder.decode(chunk)
        output, pending = process_complete_text(text)
        return output

    def finish():
        nonlocal pending

        text = (
            pending
            + decoder.decode(
                b"",
                final=True,
            )
        )

        pending = ""

        if not text:
            return b""

        if "data:" in text or "event:" in text:
            return process_sse_block(text).encode("utf-8")

        try:
            payload = json.loads(text)
        except Exception:
            return text.encode("utf-8")

        restored_payload = restore_response_object(
            payload
        )
        return json.dumps(
            restored_payload,
            ensure_ascii=False,
            separators=(",", ":"),
        ).encode("utf-8")

    return feed, finish


@app.get(local_route("/models"))
async def proxy_models(request: Request):
    headers = forward_request_headers(request)

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            upstream = await client.get(
                f"{UPSTREAM_BASE}/models",
                params=request.query_params.multi_items(),
                headers=headers,
            )
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=(
                "Upstream models request failed: "
                f"{type(exc).__name__}"
            ),
        )

    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        headers=forward_response_headers(
            upstream.headers
        ),
    )


@app.post(local_route("/responses"))
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(
            status_code=401,
            detail=(
                "Missing Codex OAuth "
                "authorization header"
            ),
        )

    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > MAX_REQUEST_BODY_BYTES:
                raise HTTPException(
                    status_code=413,
                    detail="Responses request body too large",
                )
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail="Invalid Content-Length header",
            )

    try:
        raw_body = await request.body()
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Unable to read request body",
        )

    if len(raw_body) > MAX_REQUEST_BODY_BYTES:
        raise HTTPException(
            status_code=413,
            detail="Responses request body too large",
        )

    try:
        payload = json.loads(raw_body)
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid JSON request",
        )

    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=400,
            detail=(
                "Responses request body must be an object"
            ),
        )

    enforce_request_limits(payload)

    await acquire_capacity(
        RESPONSE_SEMAPHORE,
        RESPONSE_QUEUE_WAIT_SECONDS,
        "Privacy proxy is busy",
    )
    capacity_acquired = True
    session_id, session = create_session()

    try:
        outbound_payload = await build_responses_request(
            payload,
            session,
        )
    except Exception as exc:
        delete_session(session_id)
        if capacity_acquired:
            RESPONSE_SEMAPHORE.release()

        if isinstance(exc, HTTPException):
            raise

        raise HTTPException(
            status_code=503,
            detail=(
                "Privacy detection failed closed: "
                f"{type(exc).__name__}"
            ),
        )

    headers = build_upstream_request_headers(request)
    params = build_upstream_query_params(request)

    timeout = httpx.Timeout(
        connect=UPSTREAM_CONNECT_TIMEOUT_SECONDS,
        read=UPSTREAM_READ_TIMEOUT_SECONDS,
        write=UPSTREAM_WRITE_TIMEOUT_SECONDS,
        pool=UPSTREAM_CONNECT_TIMEOUT_SECONDS,
    )

    client = httpx.AsyncClient(
        timeout=timeout
    )

    try:
        upstream_request = client.build_request(
            "POST",
            f"{UPSTREAM_BASE}/responses",
            params=params,
            headers=headers,
            json=outbound_payload,
        )

        upstream = await client.send(
            upstream_request,
            stream=True,
        )
    except Exception as exc:
        delete_session(session_id)
        await client.aclose()
        if capacity_acquired:
            RESPONSE_SEMAPHORE.release()

        raise HTTPException(
            status_code=503,
            detail=(
                "Upstream request failed: "
                f"{type(exc).__name__}"
            ),
        )

    if upstream.status_code >= 400:
        body = await upstream.aread()
        status = upstream.status_code

        response_headers = forward_response_headers(
            upstream.headers
        )

        await upstream.aclose()
        await client.aclose()
        delete_session(session_id)
        if capacity_acquired:
            RESPONSE_SEMAPHORE.release()

        return Response(
            content=body,
            status_code=status,
            headers=response_headers,
        )

    feed_restore, finish_restore = (
        make_stream_restorer(session)
    )

    async def restored_stream():
        try:
            async for chunk in upstream.aiter_bytes():
                restored = feed_restore(chunk)

                if restored:
                    yield restored

            tail = finish_restore()

            if tail:
                yield tail
        finally:
            await upstream.aclose()
            await client.aclose()
            delete_session(session_id)
            if capacity_acquired:
                RESPONSE_SEMAPHORE.release()

    return StreamingResponse(
        restored_stream(),
        status_code=upstream.status_code,
        headers=forward_response_headers(
            upstream.headers
        ),
    )
