. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Invoke-Compose ps

Write-Output "Analyzer health: $(Get-HealthSummary -Uri "$Script:AnalyzerBaseUrl/health")"
Write-Output "Proxy health: $(Get-HealthSummary -Uri "$Script:ProxyBaseUrl/health")"
