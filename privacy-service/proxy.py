import asyncio
import codecs
import hashlib
import json
import os
import time

import httpx
from fastapi import HTTPException, Request
from fastapi.responses import Response, StreamingResponse

from app import (
    app,
    get_session,
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

PRESIDIO_CACHE = {}
PRESIDIO_CACHE_FILE = "/app/cache/presidio-cache.json"

def load_presidio_cache():
    try:
        with open(PRESIDIO_CACHE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict):
                PRESIDIO_CACHE.update(data)
    except FileNotFoundError:
        pass
    except Exception as exc:
        print(json.dumps({"cache_load_error": type(exc).__name__}), flush=True)

def save_presidio_cache():
    try:
        with open(PRESIDIO_CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(PRESIDIO_CACHE, f, ensure_ascii=False)
    except Exception as exc:
        print(json.dumps({"cache_save_error": type(exc).__name__}), flush=True)

load_presidio_cache()


HOP_BY_HOP_HEADERS = {
    "host",
    "content-length",
    "connection",
    "transfer-encoding",
    "content-encoding",
    "accept-encoding",
}


def forward_request_headers(request: Request):
    return {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in HOP_BY_HOP_HEADERS
    }


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

        separator = "\n\n"
        parts.append(separator)
        offset += len(separator)

    return "".join(parts), ranges


def map_secret_spans(secret_spans, ranges):
    mapped = {
        item["slot"]: []
        for item in ranges
    }

    for span in secret_spans:
        for item in ranges:
            if (
                span["start"] >= item["start"]
                and span["end"] <= item["end"]
            ):
                mapped[item["slot"]].append({
                    **span,
                    "start": span["start"] - item["start"],
                    "end": span["end"] - item["start"],
                })
                break

    return mapped


async def scan_presidio_unique(slots):
    chunk_size = 4000
    overlap = 256

    unique_texts = list(dict.fromkeys(
        slot["text"]
        for slot in slots
    ))

    text_chunks = {}
    missing_chunks = {}
    for text in unique_texts:
        chunks = []

        for core_start in range(0, len(text), chunk_size):
            core_end = min(len(text), core_start + chunk_size)
            scan_start = max(0, core_start - overlap)
            scan_end = min(len(text), core_end + overlap)
            chunk_text = text[scan_start:scan_end]
            chunk_hash = hashlib.sha256(chunk_text.encode("utf-8")).hexdigest()
            cache_key = "chunk-v1:" + chunk_hash

            hit = cache_key in PRESIDIO_CACHE

            chunks.append({
                "core_start": core_start,
                "core_end": core_end,
                "scan_start": scan_start,
                "cache_key": cache_key,
            })

            if not hit:
                missing_chunks[cache_key] = chunk_text

        text_chunks[text] = chunks

    semaphore = asyncio.Semaphore(1)

    async def scan(cache_key, chunk_text):
        async with semaphore:
            spans = await presidio_spans(chunk_text, "lt")
            return cache_key, spans

    if missing_chunks:
        scanned = await asyncio.gather(
            *(scan(cache_key, chunk_text) for cache_key, chunk_text in missing_chunks.items())
        )

        for cache_key, spans in scanned:
            PRESIDIO_CACHE[cache_key] = spans

        save_presidio_cache()

    results = {}

    for text, chunks in text_chunks.items():
        mapped = []

        for chunk in chunks:
            spans = PRESIDIO_CACHE[chunk["cache_key"]]

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

        if original in session["value_to_token"]:
            token = session["value_to_token"][original]
        else:
            entity = span["entity_type"].upper().replace(" ", "_")
            session["counters"][entity] += 1
            token = (
                f"GP_{entity}_"
                f"{session['counters'][entity]:04d}"
            )

            session["value_to_token"][original] = token
            session["token_to_value"][token] = original

        output = (
            output[:span["start"]]
            + token
            + output[span["end"]:]
        )

    return output


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


async def protect_payload_input(value, session):
    slots = []
    collect_text_slots(value, slots)

    if not slots:
        return value

    corpus, ranges = build_secret_corpus(slots)

    nosey_task = asyncio.to_thread(
        nosey_parker_spans,
        corpus,
    )

    presidio_task = scan_presidio_unique(slots)

    secret_spans, pii_by_text = await asyncio.gather(
        nosey_task,
        presidio_task,
    )

    secrets_by_slot = map_secret_spans(
        secret_spans,
        ranges,
    )

    replacements = []

    for index, slot in enumerate(slots):
        text = slot["text"]

        spans = resolve_overlaps(
            secrets_by_slot.get(index, [])
            + pii_by_text.get(text, [])
        )

        replacements.append(
            apply_spans(
                text,
                spans,
                session,
            )
        )

    return replace_text_slots(
        value,
        replacements,
        [0],
    )


def make_stream_restorer(session):
    replacements = {
        token: json.dumps(
            original,
            ensure_ascii=False,
        )[1:-1]
        for token, original
        in session["token_to_value"].items()
    }

    tokens = list(replacements.keys())
    pending = ""
    decoder = codecs.getincrementaldecoder("utf-8")()

    def restore_complete(text):
        for token, escaped_original in replacements.items():
            text = text.replace(
                token,
                escaped_original,
            )

        return text

    def split_safe(text):
        hold = 0

        for token in tokens:
            max_check = min(
                len(token) - 1,
                len(text),
            )

            for length in range(
                max_check,
                0,
                -1,
            ):
                if text.endswith(token[:length]):
                    hold = max(
                        hold,
                        length,
                    )
                    break

        if hold:
            return (
                text[:-hold],
                text[-hold:],
            )

        return text, ""

    def feed(chunk):
        nonlocal pending

        text = pending + decoder.decode(chunk)
        ready, pending = split_safe(text)

        return restore_complete(
            ready
        ).encode("utf-8")

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

        return restore_complete(
            text
        ).encode("utf-8")

    return feed, finish


@app.get("/models")
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


@app.post("/responses")
async def proxy_responses(request: Request):
    if "authorization" not in request.headers:
        raise HTTPException(
            status_code=401,
            detail=(
                "Missing Codex OAuth "
                "authorization header"
            ),
        )

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid JSON request",
        )

    if (
        not isinstance(payload, dict)
        or "input" not in payload
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Responses request "
                "has no input field"
            ),
        )

    session_id, session = get_session(None)

    try:
        payload["input"] = await protect_payload_input(
            payload["input"],
            session,
        )
    except Exception as exc:
        sessions.pop(session_id, None)

        raise HTTPException(
            status_code=503,
            detail=(
                "Privacy detection failed closed: "
                f"{type(exc).__name__}"
            ),
        )

    headers = forward_request_headers(request)

    timeout = httpx.Timeout(
        connect=30,
        read=None,
        write=120,
        pool=30,
    )

    client = httpx.AsyncClient(
        timeout=timeout
    )

    try:
        upstream_request = client.build_request(
            "POST",
            f"{UPSTREAM_BASE}/responses",
            params=request.query_params.multi_items(),
            headers=headers,
            json=payload,
        )

        upstream = await client.send(
            upstream_request,
            stream=True,
        )
    except Exception as exc:
        sessions.pop(session_id, None)
        await client.aclose()

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
        sessions.pop(session_id, None)

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
            sessions.pop(session_id, None)

    return StreamingResponse(
        restored_stream(),
        status_code=upstream.status_code,
        headers=forward_response_headers(
            upstream.headers
        ),
    )





