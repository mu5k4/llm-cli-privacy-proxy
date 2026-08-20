. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Invoke-Compose down
Write-Output "Privacy stack stopped."
