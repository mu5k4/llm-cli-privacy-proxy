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
    $providerRemoval = @{
        Changed = $false
        BackupPath = $null
    }
    $defaultProviderRestore = @{
        Changed = $false
        BackupPath = $null
        PreviousValue = ""
    }
    $trustRemoval = @{
        Changed = $false
        BackupPath = $null
    }

    if ($PSCmdlet.ShouldProcess($Script:CodexConfigPath, "Remove provider '$providerId'")) {
        $providerRemoval = Remove-CodexProviderConfig
    }

    if ($providerRemoval.Changed) {
        Add-UninstallResult -Name "Provider removal" -Detail "Removed provider '$providerId' from $Script:CodexConfigPath"
        if ($providerRemoval.BackupPath) {
            Add-UninstallResult -Name "Provider backup" -Detail $providerRemoval.BackupPath
        }
    }

    if ($PSCmdlet.ShouldProcess($Script:CodexConfigPath, "Set default model_provider to '$FallbackProvider' when current provider is '$providerId'")) {
        $defaultProviderRestore = Restore-CodexDefaultProvider -FallbackProvider $FallbackProvider
    }

    if ($defaultProviderRestore.Changed) {
        Add-UninstallResult -Name "Default provider restore" -Detail "Changed model_provider from '$($defaultProviderRestore.PreviousValue)' to '$FallbackProvider'"
        if ($defaultProviderRestore.BackupPath) {
            Add-UninstallResult -Name "Default provider backup" -Detail $defaultProviderRestore.BackupPath
        }
    }

    if ($PSCmdlet.ShouldProcess($Script:CodexConfigPath, "Remove trusted-project entry for $Script:ProjectRoot")) {
        $trustRemoval = Remove-CodexProjectTrust
    }

    if ($trustRemoval.Changed) {
        Add-UninstallResult -Name "Project trust removal" -Detail "Removed trusted-project entry for $Script:ProjectRoot"
        if ($trustRemoval.BackupPath) {
            Add-UninstallResult -Name "Project trust backup" -Detail $trustRemoval.BackupPath
        }
    }

    if ($WhatIfPreference) {
        Add-UninstallResult -Name "Codex config" -Detail "Preview only. Run without -WhatIf to remove the provider, reset the default provider, and remove project trust."
    } elseif (-not $providerRemoval.Changed -and -not $defaultProviderRestore.Changed -and -not $trustRemoval.Changed) {
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
