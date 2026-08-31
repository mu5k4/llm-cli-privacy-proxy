. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "codex" -DisplayName "Codex CLI"
Assert-Command -Name "docker" -DisplayName "Docker CLI"
Ensure-ProjectDirectories

$providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]

Write-Output "Codex login status: $(Get-CodexLoginStatus)"
Write-Output "Provider configured: $(Test-CodexProviderConfigured)"
Write-Output "Default model_provider: $(Get-CodexDefaultProvider)"
Write-Output "Proxy base URL: $Script:ProxyDisplayBaseUrl"
Write-Output "Analyzer health: $(Get-HealthSummary -Uri "$Script:AnalyzerBaseUrl/health")"
Write-Output "Proxy health: $(Get-HealthSummary -Uri $Script:ProxyHealthUrl)"
Write-Output "Recommended launch:"
Write-Output "  start the privacy stack, then run codex normally from your repo"
