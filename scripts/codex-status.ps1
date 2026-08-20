. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "codex" -DisplayName "Codex CLI"
Assert-Command -Name "docker" -DisplayName "Docker CLI"

$providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]

Write-Output "Codex login status: $(Get-CodexLoginStatus)"
Write-Output "Provider configured: $(Test-CodexProviderConfigured)"
Write-Output "Proxy base URL: $Script:ProxyBaseUrl"
Write-Output "Analyzer health: $(Get-HealthSummary -Uri "$Script:AnalyzerBaseUrl/health")"
Write-Output "Proxy health: $(Get-HealthSummary -Uri "$Script:ProxyBaseUrl/health")"
Write-Output "Recommended launch:"
Write-Output "  ./scripts/codex-with-privacy.ps1 -Workspace <your repo>"
