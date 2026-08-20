param(
    [string]$Workspace = (Get-Location).Path,
    [switch]$Exec,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CodexArgs
)

. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "codex" -DisplayName "Codex CLI"

if (-not (Test-Path $Workspace)) {
    throw "Workspace does not exist: $Workspace"
}

if (-not (Test-CodexProviderConfigured)) {
    throw "Codex provider '$($Script:ProjectConfig["CODEX_PROVIDER_ID"])' is not configured. Run ./scripts/install.ps1 first."
}

$loginStatus = Get-CodexLoginStatus
if (-not (Test-CodexLoggedIn)) {
    throw "Codex is not logged in. Run 'codex login' first."
}

Wait-HttpOk -Uri "$Script:ProxyBaseUrl/health" -TimeoutSeconds 10

$providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
$configOverride = "model_provider=`"$providerId`""

$isInteractive = $Host.Name -ne "ServerRemoteHost"

if ($Exec) {
    & codex exec -C $Workspace -c $configOverride @CodexArgs
    return
}

if (-not $isInteractive) {
    throw "This shell is non-interactive. Use ./scripts/codex-with-privacy.ps1 -Exec -Workspace <repo> -- <prompt or exec args> for non-interactive Codex runs."
}

& codex -C $Workspace -c $configOverride @CodexArgs
