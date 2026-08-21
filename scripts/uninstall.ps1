[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$KeepImages,
    [switch]$KeepEnv,
    [switch]$KeepCodexConfig,
    [string]$FallbackProvider = "openai"
)

. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"

$providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
$results = @()

function Add-UninstallResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    $script:results += [pscustomobject]@{
        Name = $Name
        Detail = $Detail
    }
}

$composeArgs = @("down")
if (-not $KeepImages) {
    $composeArgs += @("--rmi", "local")
}

if ($PSCmdlet.ShouldProcess($Script:ComposeFile, "docker compose $($composeArgs -join ' ')")) {
    Invoke-Compose -ComposeArgs $composeArgs
    Add-UninstallResult -Name "Stack teardown" -Detail "Stopped containers and removed the compose network."
}

if (-not $KeepEnv -and (Test-Path $Script:EnvPath)) {
    if ($PSCmdlet.ShouldProcess($Script:EnvPath, "Remove .env")) {
        Remove-Item -LiteralPath $Script:EnvPath -Force
        Add-UninstallResult -Name ".env removal" -Detail "Removed machine-local runtime overrides."
    }
}

if (-not $KeepCodexConfig) {
    $configPlan = Get-CodexUninstallConfigPlan -FallbackProvider $FallbackProvider
    $configBackupPath = $null

    if ($PSCmdlet.ShouldProcess($Script:CodexConfigPath, "Remove provider '$providerId', restore default model_provider, and remove the trusted-project entry")) {
        $configBackupPath = Save-CodexUninstallConfigPlan -Plan $configPlan
    }

    if ($configPlan.ProviderChanged) {
        Add-UninstallResult -Name "Provider removal" -Detail "Removed provider '$providerId' from $Script:CodexConfigPath"
        if ($configBackupPath) {
            Add-UninstallResult -Name "Config backup" -Detail $configBackupPath
        }
    }

    if ($configPlan.DefaultProviderChanged) {
        Add-UninstallResult -Name "Default provider restore" -Detail "Changed model_provider from '$($configPlan.CurrentDefaultProvider)' to '$FallbackProvider'"
    }

    if ($configPlan.TrustChanged) {
        Add-UninstallResult -Name "Project trust removal" -Detail "Removed trusted-project entry for $Script:ProjectRoot"
    }

    if ($WhatIfPreference) {
        Add-UninstallResult -Name "Codex config" -Detail "Preview only. Run without -WhatIf to remove the provider, reset the default provider, and remove project trust."
    } elseif (-not $configPlan.ProviderChanged -and -not $configPlan.DefaultProviderChanged -and -not $configPlan.TrustChanged) {
        Add-UninstallResult -Name "Codex config" -Detail "No privacy-specific Codex config changes were present."
    }
}

if ($KeepImages) {
    Add-UninstallResult -Name "Images" -Detail "Kept local Docker images."
}

if ($KeepEnv) {
    Add-UninstallResult -Name ".env" -Detail "Kept the local .env file."
}

if ($KeepCodexConfig) {
    Add-UninstallResult -Name "Codex config" -Detail "Kept Codex provider, default provider, and trust settings unchanged."
}

Write-Output "LLM CLI Privacy Proxy uninstall"
Write-Output ""

foreach ($result in $results) {
    Write-Output ("- {0}: {1}" -f $result.Name, $result.Detail)
}

if (-not $KeepCodexConfig) {
    Write-Output ""
    Write-Output "Codex should now use '$FallbackProvider' unless you have changed it again elsewhere."
}
