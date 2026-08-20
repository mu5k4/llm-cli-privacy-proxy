import json
import os
import subprocess
import tempfile
import uuid
from collections import defaultdict

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="LLM CLI Privacy Proxy")

PRESIDIO_URL = os.environ.get("PRESIDIO_URL", "http://presidio-analyzer:3000")

sessions = {}


class ProtectRequest(BaseModel):
    text: str
    language: str = "lt"
    session_id: str | None = None


class RestoreRequest(BaseModel):
    text: str
    session_id: str


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
    async with httpx.AsyncClient(timeout=120) as client:
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
    spans = sorted(
        spans,
        key=lambda x: (
            0 if x["source"] == "noseyparker" else 1,
            -x["score"],
            -(x["end"] - x["start"]),
        ),
    )

    selected = []

    for candidate in spans:
        overlaps = any(
            candidate["start"] < existing["end"]
            and candidate["end"] > existing["start"]
            for existing in selected
        )

        if not overlaps:
            selected.append(candidate)

    return sorted(selected, key=lambda x: x["start"])


def get_session(session_id: str | None):
    if not session_id:
        session_id = str(uuid.uuid4())

    if session_id not in sessions:
        sessions[session_id] = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": defaultdict(int),
        }

    return session_id, sessions[session_id]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/protect")
async def protect(req: ProtectRequest):
    try:
        pii = await presidio_spans(req.text, req.language)
        secrets = nosey_parker_spans(req.text)
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"Detection failed: {exc}")

    spans = resolve_overlaps(secrets + pii)
    session_id, session = get_session(req.session_id)

    output = req.text

    for span in reversed(spans):
        original = req.text[span["start"]:span["end"]]

        if original in session["value_to_token"]:
            token = session["value_to_token"][original]
        else:
            entity = span["entity_type"].upper().replace(" ", "_")
            session["counters"][entity] += 1
            token = f"GP_{entity}_{session['counters'][entity]:04d}"
            session["value_to_token"][original] = token
            session["token_to_value"][token] = original

        output = output[:span["start"]] + token + output[span["end"]:]

    return {
        "session_id": session_id,
        "text": output,
        "detections": len(spans),
    }


@app.post("/restore")
def restore(req: RestoreRequest):
    session = sessions.get(req.session_id)

    if not session:
        raise HTTPException(status_code=404, detail="Unknown session")

    output = req.text

    for token, original in session["token_to_value"].items():
        output = output.replace(token, original)

    return {"text": output}
