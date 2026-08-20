param(
    [switch]$IncludeDisruptive
)

. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"

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

function Invoke-JsonPost {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [object]$Body
    )

    return Invoke-RestMethod `
        -Method Post `
        -Uri $Uri `
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
    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($protected.text)) -Message "Protect response did not include text."
    Assert-True -Condition ($protected.text -match 'GP_') -Message "Protect response did not include placeholder tokens."

    foreach ($secret in $Secrets) {
        Assert-True -Condition ($protected.text -notmatch [regex]::Escape($secret)) -Message "Protect response leaked fake sensitive value: $secret"
    }

    $restored = Invoke-JsonPost `
        -Uri "$Script:ProxyBaseUrl/restore" `
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
                -ContentType "application/json" `
                -Body (@{
                    text = "GP_EMAIL_ADDRESS_0001"
                    session_id = "missing-session"
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

function Test-StreamRestoreChunkBoundaries {
    $code = @'
from proxy import make_stream_restorer

session = {
    "token_to_value": {
        "GP_EMAIL_ADDRESS_0001": "alice@example.com",
        "GP_SECRET_0001": "ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    }
}

feed, finish = make_stream_restorer(session)
chunks = [
    b'{"delta":"GP_EMAIL_',
    b'ADDRESS_0001 and GP_SEC',
    b'RET_0001"}',
]

output = b"".join(feed(chunk) for chunk in chunks) + finish()
text = output.decode("utf-8")

assert "GP_EMAIL_ADDRESS_0001" not in text
assert "GP_SECRET_0001" not in text
assert "alice@example.com" in text
assert "ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in text

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
    -Text "My name is Alice Example, email alice@example.com, IP 203.0.113.5, token ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa." `
    -Language "en" `
    -Secrets @("Alice Example", "alice@example.com", "203.0.113.5", "ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa") | Out-Null

Test-ProtectRestoreRoundTrip `
    -Text "Mano vardas Jonas Pavyzdys, el. paštas jonas@example.lt, IP 203.0.113.77." `
    -Language "lt" `
    -Secrets @("Jonas Pavyzdys", "jonas@example.lt", "203.0.113.77") | Out-Null

Test-SessionReuse
Test-UnknownSessionRestore
Test-ResponsesGuardRails
Test-StreamRestoreChunkBoundaries

if ($IncludeDisruptive) {
    Test-FailClosedDetection
}

Write-Output "Regression suite passed."
