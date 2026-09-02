. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Ensure-ProjectDirectories

if (-not (Test-PrivacyStackHealthy)) {
    throw "Privacy stack is not healthy. Run ./scripts/start.ps1 first."
}

$sampleText = "My name is Jonas, email jonas@example.com, phone +37061234567, and demo credential DEMO_SECRET_VALUE"
$protectBody = @{
    text = $sampleText
    language = "en"
} | ConvertTo-Json

$protectResponse = Invoke-RestMethod `
    -Uri "$Script:ProxyBaseUrl/protect" `
    -Method Post `
    -ContentType "application/json" `
    -Body $protectBody

if (-not $protectResponse.session_id) {
    throw "Protect response did not include session_id."
}

if (-not $protectResponse.session_secret) {
    throw "Protect response did not include session_secret."
}

if (-not $protectResponse.text) {
    throw "Protect response did not include transformed text."
}

if ($protectResponse.text -eq $sampleText) {
    throw "Protect response did not transform the sample text."
}

if ($protectResponse.text -notmatch 'GP_[A-Z_]+_\d{4}') {
    throw "Protect response did not include expected GP_* placeholder tokens."
}

$restoreBody = @{
    session_id = $protectResponse.session_id
    text = $protectResponse.text
} | ConvertTo-Json

$restoreResponse = Invoke-RestMethod `
    -Uri "$Script:ProxyBaseUrl/restore" `
    -Method Post `
    -Headers @{ "x-session-secret" = $protectResponse.session_secret } `
    -ContentType "application/json" `
    -Body $restoreBody

if (-not $restoreResponse.text) {
    throw "Restore response did not include restored text."
}

if ($restoreResponse.text -ne $sampleText) {
    throw "Restore response did not reconstruct the original sample text."
}

Write-Output "Demo proof passed."
Write-Output "Session ID: $($protectResponse.session_id)"
Write-Output "Protected text: $($protectResponse.text)"
Write-Output "Restored text: $($restoreResponse.text)"
