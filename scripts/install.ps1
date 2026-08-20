. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Assert-Command -Name "codex" -DisplayName "Codex CLI"

Ensure-ProjectDirectories

$configResult = Ensure-CodexProviderConfig
$defaultProviderResult = Ensure-CodexDefaultProvider
$trustResult = Ensure-CodexProjectTrust

if (Test-PrivacyStackHealthy) {
    Write-Output "Privacy stack already healthy; skipping rebuild and restart."
} else {
    Invoke-Compose @("build")
    Invoke-Compose @("up", "-d")

    Wait-HttpOk -Uri "$Script:AnalyzerBaseUrl/health"
    Wait-HttpOk -Uri "$Script:ProxyBaseUrl/health"
}

& (Join-Path $PSScriptRoot "test.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Smoke test failed."
}

if ($configResult.BackupPath) {
    Write-Output "Backed up Codex config to $($configResult.BackupPath)"
}

if ($defaultProviderResult.BackupPath) {
    Write-Output "Backed up Codex config for default provider update to $($defaultProviderResult.BackupPath)"
}

if ($trustResult.BackupPath) {
    Write-Output "Backed up Codex config for trust update to $($trustResult.BackupPath)"
}

if ($configResult.Changed) {
    Write-Output "Configured Codex provider '$($Script:ProjectConfig["CODEX_PROVIDER_ID"])' at $Script:CodexConfigPath"
} else {
    Write-Output "Codex provider '$($Script:ProjectConfig["CODEX_PROVIDER_ID"])' already present at $Script:CodexConfigPath"
}

if ($defaultProviderResult.Changed) {
    Write-Output "Set Codex default model_provider to '$($Script:ProjectConfig["CODEX_PROVIDER_ID"])'."
} else {
    Write-Output "Codex default model_provider already set to '$($Script:ProjectConfig["CODEX_PROVIDER_ID"])'."
}

if ($trustResult.Changed) {
    Write-Output "Marked proxy project as trusted in Codex config."
}

Write-Output "Codex login status: $(Get-CodexLoginStatus)"
Write-Output "Codex CLI integration setup complete."
Write-Output "Next: keep the privacy stack running and launch Codex normally from any repo."
