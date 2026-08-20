param(
    [switch]$NoBuild
)

. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Ensure-ProjectDirectories

if (-not $NoBuild) {
    Invoke-Compose @("build")
}

Invoke-Compose @("up", "-d")

Wait-HttpOk -Uri "$Script:AnalyzerBaseUrl/health"
Wait-HttpOk -Uri "$Script:ProxyBaseUrl/health"

Write-Output "Privacy stack is healthy."
