. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"

Ensure-ProjectDirectories

Write-Output "Bootstrap complete."
Write-Output "Environment file: $Script:EnvPath"
Write-Output "Proxy URL: $Script:ProxyBaseUrl"
Write-Output "Analyzer URL: $Script:AnalyzerBaseUrl"
Write-Output "Next steps:"
Write-Output "  1. Review $Script:EnvPath if you need custom ports or upstream settings."
Write-Output "  2. Run ./scripts/start.ps1"
Write-Output "  3. Run ./scripts/regression.ps1"
