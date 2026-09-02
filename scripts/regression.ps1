param(
    [switch]$IncludeDisruptive
)

. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Ensure-ProjectDirectories

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-ProjectFileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Join-Path $Script:ProjectRoot $RelativePath
    return Get-Content -LiteralPath $path -Raw
}

function Invoke-JsonPost {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [object]$Body,
        [hashtable]$Headers = @{}
    )

    return Invoke-RestMethod `
        -Method Post `
        -Uri $Uri `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Compress -Depth 10)
}

function Invoke-ExpectedWebError {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,
        [Parameter(Mandatory = $true)]
        [int]$ExpectedStatusCode
    )

    try {
        & $Action | Out-Null
        throw "Expected HTTP $ExpectedStatusCode but the request succeeded."
    } catch {
        $response = $_.Exception.Response
        Assert-True -Condition ($null -ne $response) -Message "Expected an HTTP response object."
        Assert-True -Condition ([int]$response.StatusCode -eq $ExpectedStatusCode) -Message "Expected HTTP $ExpectedStatusCode but got $([int]$response.StatusCode)."
    }
}

function Test-ProtectRestoreRoundTrip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Language,
        [Parameter(Mandatory = $true)]
        [string[]]$Secrets
    )

    $protected = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/protect" `
        -Body @{
            text = $Text
            language = $Language
        }

    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($protected.session_id)) -Message "Protect response did not include session_id."
    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($protected.session_secret)) -Message "Protect response did not include session_secret."
    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($protected.text)) -Message "Protect response did not include text."
    Assert-True -Condition ($protected.text -match 'GP_') -Message "Protect response did not include placeholder tokens."

    foreach ($secret in $Secrets) {
        Assert-True -Condition ($protected.text -notmatch [regex]::Escape($secret)) -Message "Protect response leaked fake sensitive value: $secret"
    }

    $restored = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/restore" `
        -Headers @{ "x-session-secret" = $protected.session_secret } `
        -Body @{
            text = $protected.text
            session_id = $protected.session_id
        }

    Assert-True -Condition ($restored.text -eq $Text) -Message "Restore response did not reconstruct the original text."

    return $protected
}

function Test-SessionReuse {
    $text = "Alice Example alice@example.com alice@example.com"
    $first = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/protect" `
        -Body @{
            text = $text
            language = "en"
        }

    $second = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/protect" `
        -Headers @{ "x-session-secret" = $first.session_secret } `
        -Body @{
            text = "alice@example.com"
            language = "en"
            session_id = $first.session_id
        }

    Assert-True -Condition ($second.text -eq "GP_EMAIL_ADDRESS_0001") -Message "Session reuse did not preserve placeholder numbering."
}

function Test-UnknownSessionRestore {
    Invoke-ExpectedWebError `
        -ExpectedStatusCode 404 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/restore" `
                -Headers @{ "x-session-secret" = "missing-secret" } `
                -ContentType "application/json" `
                -Body (@{
                    text = "GP_EMAIL_ADDRESS_0001"
                    session_id = "missing-session"
                } | ConvertTo-Json -Compress)
        }
}

function Test-SessionOwnershipGuards {
    $protected = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/protect" `
        -Body @{
            text = "alice@example.com"
            language = "en"
        }

    Invoke-ExpectedWebError `
        -ExpectedStatusCode 401 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/restore" `
                -ContentType "application/json" `
                -Body (@{
                    text = $protected.text
                    session_id = $protected.session_id
                } | ConvertTo-Json -Compress)
        }

    Invoke-ExpectedWebError `
        -ExpectedStatusCode 403 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/restore" `
                -Headers @{ "x-session-secret" = "wrong-secret" } `
                -ContentType "application/json" `
                -Body (@{
                    text = $protected.text
                    session_id = $protected.session_id
                } | ConvertTo-Json -Compress)
        }

    Invoke-ExpectedWebError `
        -ExpectedStatusCode 404 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/protect" `
                -Headers @{ "x-session-secret" = $protected.session_secret } `
                -ContentType "application/json" `
                -Body (@{
                    text = "alice@example.com"
                    language = "en"
                    session_id = "missing-session"
                } | ConvertTo-Json -Compress)
        }
}

function Test-OneShotRestoreInvalidation {
    $protected = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/protect" `
        -Body @{
            text = "alice@example.com"
            language = "en"
        }

    $restored = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/restore" `
        -Headers @{ "x-session-secret" = $protected.session_secret } `
        -Body @{
            text = $protected.text
            session_id = $protected.session_id
        }

    Assert-True -Condition ($restored.text -eq "alice@example.com") -Message "One-shot restore did not restore the original text."

    Invoke-ExpectedWebError `
        -ExpectedStatusCode 404 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/restore" `
                -Headers @{ "x-session-secret" = $protected.session_secret } `
                -ContentType "application/json" `
                -Body (@{
                    text = $protected.text
                    session_id = $protected.session_id
                } | ConvertTo-Json -Compress)
        }
}

function Test-ResponsesGuardRails {
    Invoke-ExpectedWebError `
        -ExpectedStatusCode 401 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/responses" `
                -ContentType "application/json" `
                -Body (@{
                    input = "hello"
                } | ConvertTo-Json -Compress)
        }

    Invoke-ExpectedWebError `
        -ExpectedStatusCode 400 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/responses" `
                -Headers @{ Authorization = "Bearer fake-token" } `
                -ContentType "application/json" `
                -Body "{not-json"
        }

    Invoke-ExpectedWebError `
        -ExpectedStatusCode 400 `
        -Action {
            Invoke-RestMethod `
                -Method Post `
                -Uri "$Script:ProxyBaseUrl/responses" `
                -Headers @{ Authorization = "Bearer fake-token" } `
                -ContentType "application/json" `
                -Body (@{
                    model = "gpt-5"
                } | ConvertTo-Json -Compress)
        }
}

function Test-AuthenticatedRouteGuard {
    Invoke-ExpectedWebError `
        -ExpectedStatusCode 404 `
        -Action {
            Invoke-WebRequest `
                -Method Get `
                -Uri "$Script:PublicProxyBaseUrl/health" `
                -UseBasicParsing
        }
}

function Test-StreamRestoreChunkBoundaries {
    $code = @'
from proxy import make_stream_restorer

session = {
    "token_to_value": {
        "GP_EMAIL_ADDRESS_0001": "alice@example.com",
        "GP_SECRET_0001": "DEMO_SECRET_VALUE",
    }
}

feed, finish = make_stream_restorer(session)
chunks = [
    b'event: response.output_text.delta\n',
    b'data: {"type":"response.output_text.delta","delta":"GP_EMAIL_',
    b'ADDRESS_0001 and GP_SECRET_0001"}\n\n',
]

output = b"".join(feed(chunk) for chunk in chunks) + finish()
text = output.decode("utf-8")

assert "GP_EMAIL_ADDRESS_0001" not in text
assert "GP_SECRET_0001" not in text
assert "alice@example.com" in text
assert "DEMO_SECRET_VALUE" in text
assert '"type":"response.output_text.delta"' in text

print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Streaming restore regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Streaming restore regression did not report success."
}

function Test-ProtocolAwareRestoreBoundaries {
    $code = @'
from proxy import make_stream_restorer

session = {
    "token_to_value": {
        "GP_SECRET_0001": "DEMO_SECRET_VALUE",
    }
}

feed, finish = make_stream_restorer(session)
payload = (
    b'event: response.output_text.delta\n'
    b'data: {"type":"response.output_text.delta","delta":"GP_SECRET_0001"}\n\n'
    b'event: response.function_call_arguments.delta\n'
    b'data: {"type":"response.function_call_arguments.delta","delta":"{\\"token\\":\\"GP_SECRET_0001\\"}"}\n\n'
    b'event: response.reasoning_text.delta\n'
    b'data: {"type":"response.reasoning_text.delta","delta":"GP_SECRET_0001"}\n\n'
)

text = (feed(payload) + finish()).decode("utf-8")

assert "DEMO_SECRET_VALUE" in text
assert '"type":"response.output_text.delta","delta":"DEMO_SECRET_VALUE"' in text
assert '"type":"response.function_call_arguments.delta","delta":"{\\"token\\":\\"GP_SECRET_0001\\"}"' in text
assert '"type":"response.reasoning_text.delta","delta":"GP_SECRET_0001"' in text

print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Protocol-aware restore regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Protocol-aware restore regression did not report success."
}

function Test-CrossSlotCanonicalScanning {
    $code = @'
import asyncio

from proxy import protect_payload_input


async def fake_scan(slots, language):
    assert len(slots) == 1
    assert language == "lt"
    corpus = slots[0]["text"]
    return {
        corpus: [
            {
                "start": 0,
                "end": len("alice@example.com"),
                "entity_type": "EMAIL_ADDRESS",
                "score": 0.99,
                "source": "presidio",
            }
        ]
    }


def fake_nosey(_text):
    return []


async def main():
    import proxy

    proxy.scan_presidio_unique = fake_scan
    proxy.nosey_parker_spans = fake_nosey

    session = {
        "token_to_value": {},
        "value_to_token": {},
        "counters": {},
    }

    payload = [
        {
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": "alice@",
                },
                {
                    "type": "input_text",
                    "text": "example.com",
                },
            ],
        }
    ]

    sanitized = await protect_payload_input(payload, session)
    parts = sanitized[0]["content"]
    assert parts[0]["text"] == "GP_EMAIL_ADDRESS_0001"
    assert parts[1]["text"] == ""
    assert session["token_to_value"]["GP_EMAIL_ADDRESS_0001"] == "alice@example.com"

asyncio.run(main())
print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Cross-slot canonical scanning regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Cross-slot canonical scanning regression did not report success."
}

function Test-ResponsesFastPath {
    $code = @'
import asyncio

from proxy import build_responses_request


async def main():
    import proxy

    original_scan = proxy.scan_presidio_unique
    original_nosey = proxy.nosey_parker_spans

    def fake_nosey(text):
        marker = "ghp_abcdefghijklmnopqrstuvwxyz123456"
        start = text.find(marker)
        if start < 0:
            return []
        return [
            {
                "start": start,
                "end": start + len(marker),
                "entity_type": "SECRET",
                "score": 1.0,
                "source": "noseyparker",
            }
        ]

    try:
        async def fail_scan(*args, **kwargs):
            raise AssertionError("responses fast path should not call presidio")

        proxy.scan_presidio_unique = fail_scan
        proxy.nosey_parker_spans = fake_nosey

        session = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": {},
        }

        payload = {
            "model": "gpt-5",
            "input": "Reach me at alice@example.com, +370 612 34567, 203.0.113.7, IBAN LT121000011101001000, https://example.com, 4242 4242 4242 4242, token=ABCDEF1234567890ABCDEF1234567890 and ghp_abcdefghijklmnopqrstuvwxyz123456",
            "instructions": "Use alice@example.com and 203.0.113.7 only for the demo",
        }

        sanitized = await build_responses_request(payload, session)

        assert "alice@example.com" not in sanitized["input"]
        assert "203.0.113.7" not in sanitized["input"]
        assert "LT121000011101001000" not in sanitized["input"]
        assert "https://example.com" not in sanitized["input"]
        assert "4242 4242 4242 4242" not in sanitized["input"]
        assert "ABCDEF1234567890ABCDEF1234567890" not in sanitized["input"]
        assert "ghp_abcdefghijklmnopqrstuvwxyz123456" not in sanitized["input"]
        assert "alice@example.com" not in sanitized["instructions"]
        assert "203.0.113.7" not in sanitized["instructions"]
        assert any(token.startswith("GP_EMAIL_ADDRESS_") for token in session["token_to_value"])
        assert any(token.startswith("GP_IP_ADDRESS_") for token in session["token_to_value"])
        assert any(token.startswith("GP_IBAN_CODE_") for token in session["token_to_value"])
        assert any(token.startswith("GP_URL_") for token in session["token_to_value"])
        assert any(token.startswith("GP_CREDIT_CARD_") for token in session["token_to_value"])
        assert any(token.startswith("GP_SECRET_") for token in session["token_to_value"])
    finally:
        proxy.scan_presidio_unique = original_scan
        proxy.nosey_parker_spans = original_nosey

asyncio.run(main())
print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Responses fast-path regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Responses fast-path regression did not report success."
}

function Test-ResponsesLargePayloadSkipsNoseyParker {
    $code = @'
import asyncio

from proxy import build_responses_request


async def main():
    import proxy

    original_nosey = proxy.nosey_parker_spans

    try:
        def fail_nosey(_text):
            raise AssertionError("large benign responses payload should skip noseyparker")

        proxy.nosey_parker_spans = fail_nosey

        session = {
            "token_to_value": {},
            "value_to_token": {},
            "counters": {},
        }

        big_text = ("safe text block " * 1400) + "alice@example.com"
        payload = {
            "model": "gpt-5",
            "input": big_text,
        }

        sanitized = await build_responses_request(payload, session)

        assert "alice@example.com" not in sanitized["input"]
        assert any(token.startswith("GP_EMAIL_ADDRESS_") for token in session["token_to_value"])
    finally:
        proxy.nosey_parker_spans = original_nosey

asyncio.run(main())
print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Responses large-payload skip regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Responses large-payload skip regression did not report success."
}

function Test-OverlapUnionPreservation {
    $code = @'
from app import resolve_overlaps

spans = [
    {
        "start": 5,
        "end": 10,
        "entity_type": "EMAIL_ADDRESS",
        "score": 0.8,
        "source": "presidio",
    },
    {
        "start": 3,
        "end": 12,
        "entity_type": "SECRET",
        "score": 1.0,
        "source": "noseyparker",
    },
    {
        "start": 20,
        "end": 30,
        "entity_type": "URL",
        "score": 0.7,
        "source": "presidio",
    },
    {
        "start": 25,
        "end": 35,
        "entity_type": "API_KEY",
        "score": 1.0,
        "source": "noseyparker",
    },
]

resolved = resolve_overlaps(spans)

assert resolved == [
    {
        "start": 3,
        "end": 12,
        "entity_type": "SECRET",
        "score": 1.0,
        "source": "noseyparker",
    },
    {
        "start": 20,
        "end": 35,
        "entity_type": "API_KEY",
        "score": 1.0,
        "source": "noseyparker",
    },
]

print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Overlap union regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Overlap union regression did not report success."
}

function Test-LongEntityBoundaryHandling {
    $code = @'
import asyncio

import proxy


async def main():
    original_overlap = proxy.PRESIDIO_CHUNK_OVERLAP
    original_chunk_size = proxy.PRESIDIO_CHUNK_SIZE
    original_scan = proxy.presidio_spans
    original_cache = dict(proxy.PRESIDIO_CACHE)

    try:
        proxy.PRESIDIO_CHUNK_SIZE = 4000
        proxy.PRESIDIO_CHUNK_OVERLAP = 1024
        proxy.PRESIDIO_CACHE.clear()

        async def fake_presidio_spans(chunk_text, language):
            assert language == "lt"
            spans = []
            for target in targets:
                start = chunk_text.find(target)
                if start >= 0:
                    spans.append({
                        "start": start,
                        "end": start + len(target),
                        "entity_type": "SECRET",
                        "score": 0.99,
                        "source": "presidio",
                    })
            return spans

        proxy.presidio_spans = fake_presidio_spans

        below = ("A" * 3979) + " " + ("B" * 20)
        equal = ("A" * 3979) + " " + ("C" * 1024)
        above = ("A" * 3979) + " " + ("D" * 1025)
        targets = ["B" * 20, "C" * 1024]

        below_result = await proxy.scan_presidio_unique([{"text": below}], "lt")
        equal_result = await proxy.scan_presidio_unique([{"text": equal}], "lt")

        assert below_result[below][0]["start"] == 3980
        assert below_result[below][0]["end"] == 4000
        assert equal_result[equal][0]["start"] == 3980
        assert equal_result[equal][0]["end"] == 5004

        try:
            await proxy.scan_presidio_unique([{"text": above}], "lt")
            raise AssertionError("above-limit boundary entity was accepted")
        except RuntimeError as exc:
            assert "visibility window" in str(exc)
    finally:
        proxy.PRESIDIO_CHUNK_OVERLAP = original_overlap
        proxy.PRESIDIO_CHUNK_SIZE = original_chunk_size
        proxy.presidio_spans = original_scan
        proxy.PRESIDIO_CACHE.clear()
        proxy.PRESIDIO_CACHE.update(original_cache)

asyncio.run(main())
print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Long-entity boundary regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Long-entity boundary regression did not report success."
}

function Test-SupplyChainPins {
    $privacyDockerfile = Get-ProjectFileContent -RelativePath "privacy-service\Dockerfile"
    $analyzerDockerfile = Get-ProjectFileContent -RelativePath "Dockerfile.analyzer"
    $pyproject = Get-ProjectFileContent -RelativePath "pyproject.toml"
    $lockFile = Get-ProjectFileContent -RelativePath "privacy-service.lock"
    $analyzerLock = Get-ProjectFileContent -RelativePath "analyzer.lock"
    $analyzerConfig = Get-ProjectFileContent -RelativePath "analyzer-config.yaml"

    Assert-True -Condition ($privacyDockerfile -match '@sha256:') -Message "Privacy-service Dockerfile is missing immutable image digests."
    Assert-True -Condition ($analyzerDockerfile -match '@sha256:') -Message "Analyzer Dockerfile is missing immutable image digests."
    Assert-True -Condition ($analyzerDockerfile -notmatch ':latest') -Message "Analyzer Dockerfile still uses a mutable latest tag."
    Assert-True -Condition ($privacyDockerfile -match '--require-hashes') -Message "Privacy-service Dockerfile is not using hash-locked installs."
    Assert-True -Condition ($analyzerDockerfile -match '--require-hashes') -Message "Analyzer Dockerfile is not using hash-locked installs."
    Assert-True -Condition ($privacyDockerfile -match 'pyproject.toml privacy-service.lock') -Message "Privacy-service Dockerfile is not wired to the repo pyproject plus privacy-service lockfile."
    Assert-True -Condition ($analyzerDockerfile -match 'pyproject.toml analyzer.lock') -Message "Analyzer Dockerfile is not wired to the repo pyproject plus analyzer lockfile."
    Assert-True -Condition ($pyproject -match '\[project\.optional-dependencies\]') -Message "pyproject.toml is missing dependency groups."
    Assert-True -Condition ($pyproject -match 'privacy-service') -Message "pyproject.toml is missing the privacy-service dependency group."
    Assert-True -Condition ($pyproject -match 'analyzer') -Message "pyproject.toml is missing the analyzer dependency group."
    Assert-True -Condition ($lockFile -match '--hash=sha256:') -Message "Privacy-service lock file is missing hashes."
    Assert-True -Condition ($analyzerLock -match '--hash=sha256:') -Message "Analyzer lock file is missing hashes."
    Assert-True -Condition ($analyzerDockerfile -match 'snapshot_download') -Message "Analyzer Dockerfile is missing pinned model prefetch."
    Assert-True -Condition ($analyzerDockerfile -match 'microsoft/mdeberta-v3-base') -Message "Analyzer Dockerfile is missing the pinned base tokenizer/config model source."
    Assert-True -Condition ($analyzerDockerfile -match 'a0484667b22365f84929a935b5e50a51f71f159d') -Message "Analyzer Dockerfile is missing the pinned base tokenizer/config revision."
    Assert-True -Condition ($analyzerDockerfile -match '3003753fba99e40645cf088c7367a2c6211fc174897dc64f1f9c147c29d18d2d') -Message "Analyzer Dockerfile is missing the pinned model checksum."
    Assert-True -Condition ($analyzerDockerfile -match 'bcffcd343dc5efa5ef2d5a58d2b405eed108f01cc45b48d0a907b333ec41801f') -Message "Analyzer Dockerfile is missing the pinned base config checksum."
    Assert-True -Condition ($analyzerDockerfile -match '13c8d666d62a7bc4ac8f040aab68e942c861f93303156cc28f5c7e885d86d6e3') -Message "Analyzer Dockerfile is missing the pinned tokenizer sentencepiece checksum."
    Assert-True -Condition ($analyzerDockerfile -match '3f3978e0c036f2c2588cac34a6047cbb0af0b0dc1814254e291028529805496d') -Message "Analyzer Dockerfile is missing the pinned tokenizer config checksum."
    Assert-True -Condition ($analyzerDockerfile -match 'tokenizer_config.json') -Message "Analyzer Dockerfile is not staging local tokenizer files into the pinned GLiNER directory."
    Assert-True -Condition ($analyzerDockerfile.Contains("data['model_name'] = '/opt/models/gliner_multi_pii-v1'")) -Message "Analyzer Dockerfile is not rewriting the bundled GLiNER config to the local pinned model path."
    Assert-True -Condition ($analyzerConfig -match 'model_name: /opt/models/gliner_multi_pii-v1') -Message "Analyzer config is not pinned to the local model snapshot."
}

function Test-ResponsesRequestGuards {
    $code = @'
import asyncio

from fastapi import HTTPException
from proxy import (
    build_responses_request,
    build_upstream_query_params,
    build_upstream_request_headers,
)


class FakeHeaders:
    def __init__(self, items):
        self._items = items

    def items(self):
        return list(self._items)


class FakeQueryParams:
    def __init__(self, items):
        self._items = items

    def multi_items(self):
        return list(self._items)


class FakeRequest:
    def __init__(self, headers, query):
        self.headers = FakeHeaders(headers)
        self.query_params = FakeQueryParams(query)


async def main():
    session = {
        "token_to_value": {},
        "value_to_token": {},
        "counters": {},
    }

    payload = {
        "model": "gpt-5",
        "input": "Contact me at test@example.com",
        "instructions": "Use test@example.com if needed",
        "client_metadata": {
            "client": "codex",
            "surface": "cli",
        },
        "stream": True,
        "text": {
            "format": {
                "type": "text",
            },
            "verbosity": "low",
        },
        "tool_choice": "auto",
        "tools": [
            {
                "type": "web_search_preview",
            },
            {
                "type": "shell",
            },
            {
                "type": "function",
                "name": "get_status",
                "description": "Return current status",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "verbose": {
                            "type": "boolean",
                        }
                    }
                },
                "strict": True,
            },
            {
                "type": "mcp",
                "server_label": "local",
                "tool_names": [
                    "fetch_docs",
                ],
            },
        ],
    }
    sanitized = await build_responses_request(payload, session)
    assert sanitized["model"] == "gpt-5"
    assert sanitized["stream"] is True
    assert "test@example.com" not in sanitized["input"]
    assert "test@example.com" not in sanitized["instructions"]
    assert sanitized["client_metadata"] == {
        "client": "codex",
        "surface": "cli",
    }

    long_turn_metadata = "x" * 2048
    long_metadata_sanitized = await build_responses_request(
        {
            "model": "gpt-5",
            "input": "hello",
            "client_metadata": {
                "x-codex-turn-metadata": long_turn_metadata,
            },
        },
        {
            "token_to_value": {},
            "value_to_token": {},
            "counters": {},
        },
    )
    assert long_metadata_sanitized["client_metadata"]["x-codex-turn-metadata"] == long_turn_metadata
    assert sanitized["text"] == {
        "format": {
            "type": "text",
        },
        "verbosity": "low",
    }
    assert sanitized["tool_choice"] == "auto"
    assert sanitized["tools"] == [
        {
            "type": "web_search_preview",
        },
        {
            "type": "shell",
        },
        {
            "type": "function",
            "name": "get_status",
            "description": "Return current status",
            "parameters": {
                "type": "object",
                "properties": {
                    "verbose": {
                        "type": "boolean",
                    }
                }
            },
            "strict": True,
        },
        {
            "type": "mcp",
            "server_label": "local",
            "tool_names": [
                "fetch_docs",
            ],
        },
    ]

    sanitized = await build_responses_request(
        {
            "model": "gpt-5",
            "input": "hello",
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "response_payload",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "status": {
                                "type": "string",
                            }
                        },
                        "required": ["status"],
                    },
                }
            },
        },
        {
            "token_to_value": {},
            "value_to_token": {},
            "counters": {},
        },
    )
    assert sanitized["text"] == {
        "format": {
            "type": "json_schema",
            "name": "response_payload",
            "strict": True,
            "schema": {
                "type": "object",
                "properties": {
                    "status": {
                        "type": "string",
                    }
                },
                "required": ["status"],
            },
        }
    }

    try:
        await build_responses_request(
            {
                "model": "gpt-5",
                "input": "hello",
                "unexpected": "value",
            },
            {
                "token_to_value": {},
                "value_to_token": {},
                "counters": {},
            },
        )
        raise AssertionError("unknown top-level field was accepted")
    except HTTPException as exc:
        assert exc.status_code == 400

    try:
        await build_responses_request(
            {
                "model": "gpt-5",
                "input": "hello",
                "client_metadata": {
                    "x-codex-turn-metadata": "x" * 20000,
                },
            },
            {
                "token_to_value": {},
                "value_to_token": {},
                "counters": {},
            },
        )
        raise AssertionError("oversized client_metadata value was accepted")
    except HTTPException as exc:
        assert exc.status_code == 400

    try:
        await build_responses_request(
            {
                "model": "gpt-5",
                "input": "hello",
                "client_metadata": {
                    "ok": "yes",
                    "nested": {
                        "no": "no",
                    },
                },
            },
            {
                "token_to_value": {},
                "value_to_token": {},
                "counters": {},
            },
        )
        raise AssertionError("nested client_metadata value was accepted")
    except HTTPException as exc:
        assert exc.status_code == 400

    sanitized = await build_responses_request(
        {
            "model": "gpt-5",
            "input": "hello",
            "tools": [
                {
                    "type": "totally_unknown_tool",
                    "supports": {
                        "streaming": True,
                        "modes": ["fast", "safe"],
                    },
                }
            ],
        },
        {
            "token_to_value": {},
            "value_to_token": {},
            "counters": {},
        },
    )
    assert sanitized["tools"] == [
        {
            "type": "totally_unknown_tool",
            "supports": {
                "streaming": True,
                "modes": ["fast", "safe"],
            },
        }
    ]

    try:
        await build_responses_request(
            {
                "model": "gpt-5",
                "input": "hello",
                "text": {
                    "format": {
                        "type": "totally_unknown_format",
                    }
                },
            },
            {
                "token_to_value": {},
                "value_to_token": {},
                "counters": {},
            },
        )
        raise AssertionError("unsupported text format was accepted")
    except HTTPException as exc:
        assert exc.status_code == 400

    try:
        await build_responses_request(
            {
                "model": "gpt-5",
                "input": "hello",
                "tool_choice": {
                    "type": "shell",
                },
            },
            {
                "token_to_value": {},
                "value_to_token": {},
                "counters": {},
            },
        )
        raise AssertionError("object tool_choice was accepted")
    except HTTPException as exc:
        assert exc.status_code == 400

    sanitized = await build_responses_request(
        {
            "model": "gpt-5",
            "input": "hello",
            "tools": [
                {
                    "type": "web_search_preview",
                    "user_location": {
                        "type": "approximate",
                        "city": "Vilnius",
                    },
                }
            ],
        },
        {
            "token_to_value": {},
            "value_to_token": {},
            "counters": {},
        },
    )
    assert sanitized["tools"] == [
        {
            "type": "web_search_preview",
            "user_location": {
                "type": "approximate",
                "city": "Vilnius",
            },
        }
    ]

    request = FakeRequest(
        headers=[
            ("authorization", "Bearer test"),
            ("content-type", "application/json"),
            ("x-secret", "raw"),
        ],
        query=[
            ("include", "reasoning.encrypted_content"),
            ("raw", "value"),
        ],
    )

    headers = build_upstream_request_headers(request)
    params = build_upstream_query_params(request)

    assert headers["authorization"] == "Bearer test"
    assert headers["content-type"] == "application/json"
    assert "x-secret" not in headers
    assert params == [("include", "reasoning.encrypted_content")]

asyncio.run(main())
print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Responses request-guard regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Responses request-guard regression did not report success."
}

function Test-ResourceBoundsGuards {
    $code = @'
import asyncio
import subprocess

from fastapi import HTTPException

import app
import proxy


async def main():
    original_text_limit = proxy.MAX_REQUEST_TEXT_BYTES
    original_depth_limit = proxy.MAX_REQUEST_JSON_DEPTH
    original_cache_entries = proxy.PRESIDIO_CACHE_MAX_ENTRIES
    original_cache_bytes = proxy.PRESIDIO_CACHE_MAX_BYTES
    original_cache_fingerprint = proxy.PRESIDIO_CACHE_FINGERPRINT
    original_chunk_size = proxy.PRESIDIO_CHUNK_SIZE
    original_chunk_overlap = proxy.PRESIDIO_CHUNK_OVERLAP
    original_queue_wait = proxy.RESPONSE_QUEUE_WAIT_SECONDS
    original_presidio_spans = proxy.presidio_spans
    original_scan_semaphore = proxy.PRESIDIO_SCAN_SEMAPHORE
    original_session_bytes = app.MAX_SESSION_BYTES

    try:
        proxy.MAX_REQUEST_TEXT_BYTES = 8
        try:
            proxy.enforce_request_limits({
                "model": "gpt-5",
                "input": "123456789",
            })
            raise AssertionError("oversize aggregate text was accepted")
        except HTTPException as exc:
            assert exc.status_code == 400
            assert "aggregate text too large" in exc.detail

        proxy.MAX_REQUEST_JSON_DEPTH = 3
        try:
            proxy.enforce_request_limits({
                "model": "gpt-5",
                "input": {"a": {"b": {"c": "x"}}},
            })
            raise AssertionError("over-depth payload was accepted")
        except HTTPException as exc:
            assert exc.status_code == 400
            assert "JSON nesting too deep" in exc.detail

        def fake_timeout(*args, **kwargs):
            raise subprocess.TimeoutExpired(cmd=args[0], timeout=kwargs.get("timeout", 0))

        original_run = app.subprocess.run
        app.subprocess.run = fake_timeout
        try:
            app.nosey_parker_spans("DEMO_SECRET_VALUE")
            raise AssertionError("noseyparker timeout was not raised")
        except subprocess.TimeoutExpired:
            pass
        finally:
            app.subprocess.run = original_run

        app.sessions.clear()
        app.MAX_SESSION_BYTES = 20
        session_id, session = app.create_session()
        assert session_id == session["id"]
        try:
            app.assign_session_token(session, "EMAIL_ADDRESS", "alice@example.com")
            raise AssertionError("oversize session mapping was accepted")
        except RuntimeError as exc:
            assert "limit" in str(exc).lower()

        proxy.PRESIDIO_CACHE.clear()
        proxy.MAX_REQUEST_JSON_DEPTH = original_depth_limit
        proxy.PRESIDIO_CACHE_MAX_ENTRIES = 1
        proxy.PRESIDIO_CACHE_MAX_BYTES = 1024
        proxy.PRESIDIO_CACHE_FINGERPRINT = "fingerprint-a"
        proxy.store_cached_presidio_spans([
            ("chunk-v2:fingerprint-a:lt:first", [{"start": 0, "end": 1, "entity_type": "EMAIL_ADDRESS", "score": 0.9, "source": "presidio"}]),
            ("chunk-v2:fingerprint-a:lt:second", [{"start": 1, "end": 2, "entity_type": "SECRET", "score": 1.0, "source": "noseyparker"}]),
        ])
        assert list(proxy.PRESIDIO_CACHE.keys()) == ["chunk-v2:fingerprint-a:lt:second"]

        cache_key = proxy.build_presidio_cache_key("alice@example.com", "lt")
        proxy.PRESIDIO_CACHE[cache_key] = []
        assert proxy.get_cached_presidio_spans(cache_key) == []

        proxy.PRESIDIO_CACHE_FINGERPRINT = "fingerprint-b"
        assert proxy.build_presidio_cache_key("alice@example.com", "lt") != cache_key
        assert proxy.get_cached_presidio_spans(
            proxy.build_presidio_cache_key("alice@example.com", "lt")
        ) is None

        proxy.PRESIDIO_CACHE.clear()
        proxy.PRESIDIO_CHUNK_SIZE = 4
        proxy.PRESIDIO_CHUNK_OVERLAP = 8
        proxy.RESPONSE_QUEUE_WAIT_SECONDS = 0.01
        proxy.PRESIDIO_SCAN_SEMAPHORE = asyncio.Semaphore(1)

        async def fake_presidio_spans(text, language):
            await asyncio.sleep(0.05)
            return [{
                "start": 0,
                "end": len(text),
                "entity_type": "URL",
                "score": 0.9,
                "source": "presidio",
            }]

        proxy.presidio_spans = fake_presidio_spans
        scanned = await proxy.scan_presidio_unique(
            [{"text": "abcd efgh"}],
            "en",
        )
        assert "abcd efgh" in scanned
        assert len(scanned["abcd efgh"]) >= 1
    finally:
        proxy.MAX_REQUEST_TEXT_BYTES = original_text_limit
        proxy.MAX_REQUEST_JSON_DEPTH = original_depth_limit
        proxy.PRESIDIO_CACHE_MAX_ENTRIES = original_cache_entries
        proxy.PRESIDIO_CACHE_MAX_BYTES = original_cache_bytes
        proxy.PRESIDIO_CACHE_FINGERPRINT = original_cache_fingerprint
        proxy.PRESIDIO_CHUNK_SIZE = original_chunk_size
        proxy.PRESIDIO_CHUNK_OVERLAP = original_chunk_overlap
        proxy.RESPONSE_QUEUE_WAIT_SECONDS = original_queue_wait
        proxy.presidio_spans = original_presidio_spans
        proxy.PRESIDIO_SCAN_SEMAPHORE = original_scan_semaphore
        app.MAX_SESSION_BYTES = original_session_bytes
        app.sessions.clear()
        proxy.PRESIDIO_CACHE.clear()

asyncio.run(main())
print("ok")
'@

    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($code))
    $runner = "import base64; exec(base64.b64decode('$encoded').decode('utf-8'))"
    $result = & docker exec llm-cli-privacy-proxy python -c $runner

    if ($LASTEXITCODE -ne 0) {
        throw "Resource bounds regression failed."
    }

    Assert-True -Condition ($result -match "ok") -Message "Resource bounds regression did not report success."
}

function Test-FailClosedDetection {
    Invoke-Compose stop presidio-analyzer

    try {
        Invoke-ExpectedWebError `
            -ExpectedStatusCode 503 `
            -Action {
                Invoke-RestMethod `
                    -Method Post `
                    -Uri "$Script:ProxyBaseUrl/protect" `
                    -ContentType "application/json" `
                    -Body (@{
                        text = "alice@example.com"
                        language = "en"
                    } | ConvertTo-Json -Compress)
            }
    } finally {
        Invoke-Compose start presidio-analyzer
        Wait-HttpOk -Uri "$Script:AnalyzerBaseUrl/health"
    }
}

Test-ProtectRestoreRoundTrip `
    -Text "My name is Alice Example, email alice@example.com, IP 203.0.113.5." `
    -Language "en" `
    -Secrets @("Alice Example", "alice@example.com", "203.0.113.5") | Out-Null

Test-ProtectRestoreRoundTrip `
    -Text "Mano vardas Jonas Pavyzdys, el. paštas jonas@example.lt, IP 203.0.113.77." `
    -Language "lt" `
    -Secrets @("Jonas Pavyzdys", "jonas@example.lt", "203.0.113.77") | Out-Null

Test-SessionReuse
Test-UnknownSessionRestore
Test-SessionOwnershipGuards
Test-OneShotRestoreInvalidation
Test-AuthenticatedRouteGuard
Test-ResponsesGuardRails
Test-ResponsesRequestGuards
Test-ResourceBoundsGuards
Test-CrossSlotCanonicalScanning
Test-ResponsesFastPath
Test-ResponsesLargePayloadSkipsNoseyParker
Test-OverlapUnionPreservation
Test-LongEntityBoundaryHandling
Test-SupplyChainPins
Test-StreamRestoreChunkBoundaries
Test-ProtocolAwareRestoreBoundaries

if ($IncludeDisruptive) {
    Test-FailClosedDetection
}

Write-Output "Regression suite passed."
