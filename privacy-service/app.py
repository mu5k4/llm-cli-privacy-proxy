import json
import os
import secrets
import subprocess
import tempfile
import time
import uuid
from collections import OrderedDict, defaultdict

import httpx
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel

app = FastAPI(title="LLM CLI Privacy Proxy")

PRESIDIO_URL = os.environ.get("PRESIDIO_URL", "http://presidio-analyzer:3000")
LOCAL_AUTH_TOKEN = os.environ.get("LOCAL_AUTH_TOKEN", "").strip()
PRESIDIO_TIMEOUT_SECONDS = float(os.environ.get("PRESIDIO_TIMEOUT_SECONDS", "30"))
NOSEYPARKER_TIMEOUT_SECONDS = float(os.environ.get("NOSEYPARKER_TIMEOUT_SECONDS", "30"))
MAX_PROTECT_TEXT_BYTES = int(os.environ.get("MAX_PROTECT_TEXT_BYTES", "200000"))
SESSION_TTL_SECONDS = int(os.environ.get("SESSION_TTL_SECONDS", "900"))
MAX_ACTIVE_SESSIONS = int(os.environ.get("MAX_ACTIVE_SESSIONS", "256"))
MAX_SESSION_BYTES = int(os.environ.get("MAX_SESSION_BYTES", "262144"))
MAX_TOTAL_SESSION_BYTES = int(os.environ.get("MAX_TOTAL_SESSION_BYTES", "4194304"))

if not LOCAL_AUTH_TOKEN:
    raise RuntimeError("LOCAL_AUTH_TOKEN must be configured")

LOCAL_AUTH_PREFIX = f"/local/{LOCAL_AUTH_TOKEN}"

sessions = OrderedDict()


class ProtectRequest(BaseModel):
    text: str
    language: str = "lt"
    session_id: str | None = None


class RestoreRequest(BaseModel):
    text: str
    session_id: str
    delete_after_restore: bool = True


def byte_to_char_offset(text: str, byte_offset: int) -> int:
    return len(text.encode("utf-8")[:byte_offset].decode("utf-8", errors="ignore"))


def nosey_parker_spans(text: str):
    with tempfile.TemporaryDirectory() as tmp:
        datastore = f"{tmp}/scan.np"
        enum_line = json.dumps(
            {"content": text, "provenance": {"source": "llm-cli-request"}}
        ) + "\n"

        scan = subprocess.run(
            [
                "noseyparker",
                "scan",
                "-q",
                "-d",
                datastore,
                "--enumerator=/dev/stdin",
            ],
            input=enum_line,
            text=True,
            capture_output=True,
            timeout=NOSEYPARKER_TIMEOUT_SECONDS,
        )

        if scan.returncode not in (0, 1):
            raise RuntimeError(scan.stderr or scan.stdout)

        report = subprocess.run(
            [
                "noseyparker",
                "report",
                "-q",
                "-d",
                datastore,
                "--format",
                "json",
            ],
            text=True,
            capture_output=True,
            timeout=NOSEYPARKER_TIMEOUT_SECONDS,
        )

        if report.returncode != 0:
            raise RuntimeError(report.stderr or report.stdout)

        findings = json.loads(report.stdout or "[]")
        spans = []

        for finding in findings:
            for match in finding.get("matches", []):
                offsets = match.get("location", {}).get("offset_span", {})
                start_b = offsets.get("start")
                end_b = offsets.get("end")

                if start_b is None or end_b is None:
                    continue

                spans.append(
                    {
                        "start": byte_to_char_offset(text, start_b),
                        "end": byte_to_char_offset(text, end_b),
                        "entity_type": "SECRET",
                        "score": 1.0,
                        "source": "noseyparker",
                    }
                )

        return spans


async def presidio_spans(text: str, language: str):
    async with httpx.AsyncClient(timeout=PRESIDIO_TIMEOUT_SECONDS) as client:
        response = await client.post(
            f"{PRESIDIO_URL}/analyze",
            json={"text": text, "language": language},
        )
        response.raise_for_status()

    spans = []
    for item in response.json():
        entity = item["entity_type"]

        if entity == "EMAIL":
            entity = "EMAIL_ADDRESS"

        spans.append(
            {
                "start": item["start"],
                "end": item["end"],
                "entity_type": entity,
                "score": item["score"],
                "source": "presidio",
            }
        )

    return spans


def resolve_overlaps(spans):
    ranked_spans = sorted(
        spans,
        key=lambda x: (
            x["start"],
            x["end"],
            0 if x["source"] == "noseyparker" else 1,
            -x["score"],
            -(x["end"] - x["start"]),
        ),
    )

    merged = []
    current = None

    for candidate in ranked_spans:
        if current is None:
            current = {
                **candidate,
                "start": candidate["start"],
                "end": candidate["end"],
                "_best_rank": (
                    0 if candidate["source"] == "noseyparker" else 1,
                    -candidate["score"],
                    -(candidate["end"] - candidate["start"]),
                ),
            }
            continue

        if candidate["start"] < current["end"]:
            current["start"] = min(current["start"], candidate["start"])
            current["end"] = max(current["end"], candidate["end"])
            candidate_rank = (
                0 if candidate["source"] == "noseyparker" else 1,
                -candidate["score"],
                -(candidate["end"] - candidate["start"]),
            )
            if candidate_rank < current["_best_rank"]:
                current["entity_type"] = candidate["entity_type"]
                current["score"] = candidate["score"]
                current["source"] = candidate["source"]
                current["_best_rank"] = candidate_rank
            continue

        current.pop("_best_rank", None)
        merged.append(current)
        current = {
            **candidate,
            "start": candidate["start"],
            "end": candidate["end"],
            "_best_rank": (
                0 if candidate["source"] == "noseyparker" else 1,
                -candidate["score"],
                -(candidate["end"] - candidate["start"]),
            ),
        }

    if current is not None:
        current.pop("_best_rank", None)
        merged.append(current)

    return merged


def create_session():
    prune_sessions()
    session_id = str(uuid.uuid4())
    evict_sessions(required_bytes=0, protected_session_id=session_id)
    sessions[session_id] = {
        "id": session_id,
        "secret": secrets.token_urlsafe(32),
        "token_to_value": {},
        "value_to_token": {},
        "counters": defaultdict(int),
        "created_at": time.time(),
        "updated_at": time.time(),
        "approx_bytes": 0,
    }
    touch_session(session_id)
    return session_id, sessions[session_id]


def enforce_text_size(text: str):
    text_bytes = len(text.encode("utf-8"))
    if text_bytes > MAX_PROTECT_TEXT_BYTES:
        raise HTTPException(status_code=413, detail="Text payload too large")


def estimate_mapping_bytes(token: str, original: str):
    return len(token.encode("utf-8")) + len(original.encode("utf-8"))


def total_session_bytes():
    return sum(session["approx_bytes"] for session in sessions.values())


def touch_session(session_id: str):
    session = sessions[session_id]
    session["updated_at"] = time.time()
    sessions.move_to_end(session_id)


def prune_sessions():
    now = time.time()
    expired = [
        session_id
        for session_id, session in sessions.items()
        if now - session["updated_at"] > SESSION_TTL_SECONDS
    ]
    for session_id in expired:
        sessions.pop(session_id, None)


def evict_sessions(required_bytes: int, protected_session_id: str | None = None):
    prune_sessions()

    while (
        len(sessions) >= MAX_ACTIVE_SESSIONS
        or total_session_bytes() + required_bytes > MAX_TOTAL_SESSION_BYTES
    ):
        candidate_id = None

        for existing_id in sessions.keys():
            if existing_id != protected_session_id:
                candidate_id = existing_id
                break

        if candidate_id is None:
            raise RuntimeError("Session capacity exhausted")

        sessions.pop(candidate_id, None)


def assign_session_token(session, entity_type: str, original: str):
    if "counters" not in session or session["counters"] is None:
        session["counters"] = {}
    if "value_to_token" not in session or session["value_to_token"] is None:
        session["value_to_token"] = {}
    if "token_to_value" not in session or session["token_to_value"] is None:
        session["token_to_value"] = {}
    if "approx_bytes" not in session or session["approx_bytes"] is None:
        session["approx_bytes"] = 0

    if original in session["value_to_token"]:
        if "id" in session:
            touch_session(session["id"])
        return session["value_to_token"][original]

    entity = entity_type.upper().replace(" ", "_")
    session["counters"][entity] = session["counters"].get(entity, 0) + 1
    token = f"GP_{entity}_{session['counters'][entity]:04d}"
    required_bytes = estimate_mapping_bytes(token, original)

    if required_bytes > MAX_SESSION_BYTES:
        raise RuntimeError("Single mapping exceeds session retention limit")

    if session["approx_bytes"] + required_bytes > MAX_SESSION_BYTES:
        raise RuntimeError("Session retention limit exceeded")

    evict_sessions(
        required_bytes=required_bytes,
        protected_session_id=session.get("id"),
    )

    session["value_to_token"][original] = token
    session["token_to_value"][token] = original
    session["approx_bytes"] += required_bytes
    if "id" in session:
        touch_session(session["id"])

    return token


def get_existing_session(session_id: str):
    prune_sessions()
    session = sessions.get(session_id)
    if not session:
        return None
    touch_session(session_id)
    return session


def delete_session(session_id: str):
    sessions.pop(session_id, None)


def session_public_view(session):
    return {
        "session_id": session["id"],
        "session_secret": session["secret"],
    }


def require_session_secret(request: Request):
    session_secret = request.headers.get("x-session-secret", "").strip()
    if not session_secret:
        raise HTTPException(status_code=401, detail="Missing session secret")
    return session_secret


def require_owned_session(session_id: str, session_secret: str):
    session = get_existing_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Unknown session")
    if session.get("secret") != session_secret:
        raise HTTPException(status_code=403, detail="Session ownership check failed")
    return session


def local_route(path: str) -> str:
    return f"{LOCAL_AUTH_PREFIX}{path}"


@app.get(local_route("/health"))
def health():
    return {"status": "ok", "auth_mode": "path_secret"}


@app.post(local_route("/protect"))
async def protect(req: ProtectRequest, request: Request):
    enforce_text_size(req.text)

    try:
        pii = await presidio_spans(req.text, req.language)
        secrets = nosey_parker_spans(req.text)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Detection failed: {exc}")

    spans = resolve_overlaps(secrets + pii)

    if req.session_id:
        session = require_owned_session(
            req.session_id,
            require_session_secret(request),
        )
        session_id = req.session_id
    else:
        session_id, session = create_session()

    output = req.text

    for span in reversed(spans):
        original = req.text[span["start"]:span["end"]]

        token = assign_session_token(
            session,
            span["entity_type"],
            original,
        )

        output = output[:span["start"]] + token + output[span["end"]:]

    return {
        **session_public_view(session),
        "text": output,
        "detections": len(spans),
    }


@app.post(local_route("/restore"))
def restore(req: RestoreRequest, request: Request):
    enforce_text_size(req.text)
    session = require_owned_session(
        req.session_id,
        require_session_secret(request),
    )

    output = req.text

    for token, original in session["token_to_value"].items():
        output = output.replace(token, original)

    if req.delete_after_restore:
        delete_session(req.session_id)

    return {"text": output}


@app.delete(local_route("/sessions/{session_id}"))
def destroy_session(session_id: str, request: Request):
    require_owned_session(
        session_id,
        require_session_secret(request),
    )
    delete_session(session_id)
    return {"deleted": True}
