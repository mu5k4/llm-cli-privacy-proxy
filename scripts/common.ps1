Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$Script:ComposeFile = Join-Path $Script:ProjectRoot "docker-compose.yml"
$Script:EnvExamplePath = Join-Path $Script:ProjectRoot ".env.example"
$Script:EnvPath = Join-Path $Script:ProjectRoot ".env"
$Script:CodexConfigDir = Join-Path $HOME ".codex"
$Script:CodexConfigPath = Join-Path $Script:CodexConfigDir "config.toml"

function New-LocalAuthToken {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return (($bytes | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Get-ProjectConfig {
    if (-not (Test-Path $Script:EnvExamplePath)) {
        throw "Expected example environment file at $Script:EnvExamplePath"
    }

    $values = @{}

    foreach ($path in @($Script:EnvExamplePath, $Script:EnvPath)) {
        if (-not (Test-Path $path)) {
            continue
        }

        foreach ($line in Get-Content -LiteralPath $path) {
            $trimmed = $line.Trim()
            if (-not $trimmed -or $trimmed.StartsWith("#")) {
                continue
            }

            $parts = $trimmed -split "=", 2
            if ($parts.Count -ne 2) {
                continue
            }

            $values[$parts[0].Trim()] = $parts[1].Trim()
        }
    }

    foreach ($default in @(
        @{ Key = "PROXY_BIND_HOST"; Value = "127.0.0.1" },
        @{ Key = "PROXY_PORT"; Value = "8000" },
        @{ Key = "ANALYZER_PORT"; Value = "5001" },
        @{ Key = "PRIVACY_PROVIDER_NAME"; Value = "Local Privacy Proxy" },
        @{ Key = "CODEX_PROVIDER_ID"; Value = "privacy" }
    )) {
        if (-not $values.ContainsKey($default.Key) -or [string]::IsNullOrWhiteSpace($values[$default.Key])) {
            $values[$default.Key] = $default.Value
        }
    }

    return $values
}

function Initialize-ProjectConfig {
    $Script:ProjectConfig = Get-ProjectConfig
    $Script:ProxyTransportBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["PROXY_PORT"]
    $Script:PublicProxyBaseUrl = $Script:ProxyTransportBaseUrl
    $Script:AnalyzerBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["ANALYZER_PORT"]
    $localAuthToken = $Script:ProjectConfig["LOCAL_AUTH_TOKEN"]

    if ([string]::IsNullOrWhiteSpace($localAuthToken)) {
        $Script:ProxyPathPrefix = "/local/__missing_local_auth_token__"
    } else {
        $Script:ProxyPathPrefix = "/local/$localAuthToken"
    }

    $Script:ProxyBaseUrl = $Script:ProxyTransportBaseUrl + $Script:ProxyPathPrefix
    $Script:ProxyDisplayBaseUrl = $Script:ProxyTransportBaseUrl + "/local/<redacted>"
    $Script:ProxyHealthUrl = $Script:ProxyBaseUrl + "/health"
}

Initialize-ProjectConfig

function New-CodexConfigBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Suffix
    )

    if (-not (Test-Path $Script:CodexConfigPath)) {
        return $null
    }

    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = "$Script:CodexConfigPath.$timestamp.$Suffix.bak"
    Copy-Item -LiteralPath $Script:CodexConfigPath -Destination $backupPath
    return $backupPath
}

function Get-CodexConfigContent {
    if (-not (Test-Path $Script:CodexConfigPath)) {
        return ""
    }

    return (Get-Content -Raw $Script:CodexConfigPath)
}

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Test-TomlContentValid {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw "Python was not found on PATH. A real TOML parser is required for safe Codex config edits."
    }

    $code = @"
import pathlib
import tomllib
import sys

path = pathlib.Path(sys.argv[1])
with path.open("rb") as handle:
    tomllib.load(handle)
"@

    $scriptPath = Join-Path $env:TEMP "codex-toml-validate.py"
    Write-Utf8NoBomFile -Path $scriptPath -Content $code

    try {
        & python $scriptPath $Path
        if ($LASTEXITCODE -ne 0) {
            throw "TOML validation failed for $Path"
        }
    } finally {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

function Set-CodexConfigContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$BackupSuffix
    )

    if (-not (Test-Path $Script:CodexConfigDir)) {
        New-Item -ItemType Directory -Force -Path $Script:CodexConfigDir | Out-Null
    }

    $backupPath = New-CodexConfigBackup -Suffix $BackupSuffix
    $trimmed = $Content.TrimEnd()
    $finalContent = if ($trimmed) {
        $trimmed + [Environment]::NewLine
    } else {
        ""
    }

    $tempPath = "$Script:CodexConfigPath.tmp"
    Write-Utf8NoBomFile -Path $tempPath -Content $finalContent

    try {
        Test-TomlContentValid -Path $tempPath
        Move-Item -LiteralPath $tempPath -Destination $Script:CodexConfigPath -Force
    } catch {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        throw
    }

    return $backupPath
}

function Get-CodexConfigDocument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $lines = [regex]::Split($Content, "\r?\n")
    $blocks = New-Object System.Collections.Generic.List[object]
    $currentHeader = $null
    $currentLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        if ($line -match '^\[[^\[].*\]\s*$') {
            $blocks.Add([pscustomobject]@{
                Header = $currentHeader
                Lines = $currentLines.ToArray()
            })
            $currentHeader = $line.Trim()
            $currentLines = New-Object System.Collections.Generic.List[string]
            $currentLines.Add($line)
            continue
        }

        $currentLines.Add($line)
    }

    $blocks.Add([pscustomobject]@{
        Header = $currentHeader
        Lines = $currentLines.ToArray()
    })

    return ,($blocks.ToArray())
}

function Get-CodexConfigText {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document
    )

    $segments = New-Object System.Collections.Generic.List[string]

    foreach ($block in $Document) {
        $segment = (($block.Lines | ForEach-Object { $_ }) -join [Environment]::NewLine).TrimEnd()
        if ($segment) {
            $segments.Add($segment)
        }
    }

    return ($segments -join ([Environment]::NewLine + [Environment]::NewLine))
}

function Find-CodexConfigBlockIndex {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document,
        [Parameter(Mandatory = $true)]
        [string]$Header
    )

    for ($index = 0; $index -lt $Document.Count; $index++) {
        if ($Document[$index].Header -eq $Header) {
            return $index
        }
    }

    return -1
}

function New-CodexConfigBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Header,
        [Parameter(Mandatory = $true)]
        [string[]]$BodyLines
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add($Header)
    foreach ($line in $BodyLines) {
        $lines.Add($line)
    }

    return [pscustomobject]@{
        Header = $Header
        Lines = $lines.ToArray()
    }
}

function Set-CodexConfigBlock {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document,
        [Parameter(Mandatory = $true)]
        [string]$Header,
        [Parameter(Mandatory = $true)]
        [string[]]$BodyLines
    )

    $index = Find-CodexConfigBlockIndex -Document $Document -Header $Header
    $block = New-CodexConfigBlock -Header $Header -BodyLines $BodyLines
    $result = New-Object System.Collections.Generic.List[object]

    if ($index -ge 0) {
        for ($i = 0; $i -lt $Document.Count; $i++) {
            if ($i -eq $index) {
                $result.Add($block)
            } else {
                $result.Add($Document[$i])
            }
        }
        return ,($result.ToArray())
    }

    foreach ($item in $Document) {
        $result.Add($item)
    }
    $result.Add($block)
    return ,($result.ToArray())
}

function Remove-CodexConfigBlocks {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document,
        [Parameter(Mandatory = $true)]
        [string[]]$Headers
    )

    $result = New-Object System.Collections.Generic.List[object]

    foreach ($block in $Document) {
        if ($null -ne $block.Header -and $Headers -contains $block.Header) {
            continue
        }

        $result.Add($block)
    }

    return ,($result.ToArray())
}

function Get-CodexConfigRootLines {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document
    )

    foreach ($block in $Document) {
        if ($null -eq $block.Header) {
            return ,([string[]]$block.Lines)
        }
    }

    return ,([string[]]@())
}

function Set-CodexConfigRootLines {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $result = New-Object System.Collections.Generic.List[object]
    $replaced = $false

    foreach ($block in $Document) {
        if ($null -eq $block.Header) {
            $result.Add([pscustomobject]@{
                Header = $null
                Lines = [string[]]$Lines
            })
            $replaced = $true
            continue
        }

        $result.Add($block)
    }

    if (-not $replaced) {
        $result.Insert(0, [pscustomobject]@{
            Header = $null
            Lines = [string[]]$Lines
        })
    }

    return ,($result.ToArray())
}

function Set-CodexRootStringKey {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Document,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $rootLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in (Get-CodexConfigRootLines -Document $Document)) {
        $rootLines.Add($line)
    }

    $pattern = '^\s*' + [regex]::Escape($Key) + '\s*='
    $updated = $false

    for ($index = 0; $index -lt $rootLines.Count; $index++) {
        if ($rootLines[$index] -match $pattern) {
            $rootLines[$index] = "$Key = `"$Value`""
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        while ($rootLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($rootLines[$rootLines.Count - 1])) {
            $rootLines.RemoveAt($rootLines.Count - 1)
        }
        $rootLines.Add("$Key = `"$Value`"")
    }

    return (Set-CodexConfigRootLines -Document $Document -Lines $rootLines.ToArray())
}

function Get-CodexProviderBlock {
    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
    $providerName = $Script:ProjectConfig["PRIVACY_PROVIDER_NAME"]

    return @{
        Header = "[model_providers.$providerId]"
        BodyLines = @(
            "name = `"$providerName`"",
            "base_url = `"$Script:ProxyBaseUrl`"",
            "wire_api = `"responses`"",
            "requires_openai_auth = true",
            "supports_websockets = false"
        )
    }
}

function Get-CodexProjectTrustBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $normalizedPath = $ProjectPath.ToLowerInvariant().Replace("\", "\\")

    return @{
        Header = "[projects.'$normalizedPath']"
        BodyLines = @(
            "trust_level = `"trusted`""
        )
    }
}

function Assert-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$DisplayName was not found on PATH."
    }
}

function Invoke-Compose {
    param(
        [string[]]$ComposeArgs
    )

    $dockerArgs = @("compose", "-f", $Script:ComposeFile) + $ComposeArgs
    & docker @dockerArgs

    if ($LASTEXITCODE -ne 0) {
        throw "docker compose $($ComposeArgs -join ' ') failed."
    }
}

function Ensure-ProjectDirectories {
    $cacheDir = Join-Path $Script:ProjectRoot "privacy-cache"
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

    if (-not (Test-Path $Script:EnvPath)) {
        Copy-Item -LiteralPath $Script:EnvExamplePath -Destination $Script:EnvPath
    }

    $envLines = @()
    if (Test-Path $Script:EnvPath) {
        $envLines = @(Get-Content -LiteralPath $Script:EnvPath)
    }

    $hasLocalAuthToken = $false
    foreach ($line in $envLines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^LOCAL_AUTH_TOKEN\s*=\s*\S+') {
            $hasLocalAuthToken = $true
            break
        }
    }

    if (-not $hasLocalAuthToken) {
        $generatedToken = New-LocalAuthToken
        Add-Content -LiteralPath $Script:EnvPath -Value ""
        Add-Content -LiteralPath $Script:EnvPath -Value "LOCAL_AUTH_TOKEN=$generatedToken"
    }

    Initialize-ProjectConfig
}

function Wait-HttpOk {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                return
            }
        } catch {
        }

        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for $Uri"
}

function Get-HealthSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    try {
        $response = Invoke-RestMethod -Uri $Uri -TimeoutSec 5
        return "ok: $($response | ConvertTo-Json -Compress)"
    } catch {
        return "unreachable"
    }
}

function Test-HttpOk {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 5
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Test-PrivacyStackHealthy {
    return ((Test-HttpOk -Uri "$Script:AnalyzerBaseUrl/health") -and (Test-HttpOk -Uri $Script:ProxyHealthUrl))
}

function Ensure-CodexProviderConfig {
    $plan = Get-CodexInstallConfigPlan
    $backupPath = Save-CodexInstallConfigPlan -Plan $plan
    return @{
        Changed = $plan.ProviderChanged
        BackupPath = $backupPath
    }
}

function Ensure-CodexDefaultProvider {
    $plan = Get-CodexInstallConfigPlan
    $backupPath = Save-CodexInstallConfigPlan -Plan $plan
    return @{
        Changed = $plan.DefaultProviderChanged
        BackupPath = $backupPath
    }
}

function Ensure-CodexProjectTrust {
    param(
        [string]$ProjectPath = $Script:ProjectRoot
    )

    $plan = Get-CodexInstallConfigPlan
    $backupPath = Save-CodexInstallConfigPlan -Plan $plan
    return @{
        Changed = $plan.TrustChanged
        BackupPath = $backupPath
    }
}

function Remove-CodexProviderConfig {
    $plan = Get-CodexUninstallConfigPlan
    $backupPath = Save-CodexUninstallConfigPlan -Plan $plan
    return @{
        Changed = $plan.ProviderChanged
        BackupPath = $backupPath
    }
}

function Restore-CodexDefaultProvider {
    param(
        [string]$ProviderId = $Script:ProjectConfig["CODEX_PROVIDER_ID"],
        [string]$FallbackProvider = "openai"
    )

    if (-not (Test-Path $Script:CodexConfigPath)) {
        return @{
            Changed = $false
            BackupPath = $null
            PreviousValue = ""
        }
    }

    $current = Get-CodexDefaultProvider

    if ($current -ne $ProviderId) {
        return @{
            Changed = $false
            BackupPath = $null
            PreviousValue = $current
        }
    }

    $plan = Get-CodexUninstallConfigPlan -FallbackProvider $FallbackProvider
    $backupPath = Save-CodexUninstallConfigPlan -Plan $plan
    return @{
        Changed = $plan.DefaultProviderChanged
        BackupPath = $backupPath
        PreviousValue = $current
    }
}

function Remove-CodexProjectTrust {
    param(
        [string]$ProjectPath = $Script:ProjectRoot
    )

    if (-not (Test-Path $Script:CodexConfigPath)) {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $plan = Get-CodexUninstallConfigPlan
    $backupPath = Save-CodexUninstallConfigPlan -Plan $plan
    return @{
        Changed = $plan.TrustChanged
        BackupPath = $backupPath
    }
}

function Get-CodexInstallConfigPlan {
    if (-not (Test-Path $Script:CodexConfigDir)) {
        New-Item -ItemType Directory -Force -Path $Script:CodexConfigDir | Out-Null
    }

    $originalContent = Get-CodexConfigContent
    $document = Get-CodexConfigDocument -Content $originalContent
    $providerBlock = Get-CodexProviderBlock
    $trustBlock = Get-CodexProjectTrustBlock -ProjectPath $Script:ProjectRoot
    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]

    $currentProvider = ""
    if ($originalContent) {
        $currentProvider = Get-CodexDefaultProvider
    }
    $providerIndex = Find-CodexConfigBlockIndex -Document $document -Header $providerBlock.Header
    $trustIndex = Find-CodexConfigBlockIndex -Document $document -Header $trustBlock.Header

    $updatedDocument = Set-CodexConfigBlock -Document $document -Header $providerBlock.Header -BodyLines $providerBlock.BodyLines
    $updatedDocument = Set-CodexRootStringKey -Document $updatedDocument -Key "model_provider" -Value $providerId
    $updatedDocument = Set-CodexConfigBlock -Document $updatedDocument -Header $trustBlock.Header -BodyLines $trustBlock.BodyLines

    $updatedContent = Get-CodexConfigText -Document $updatedDocument
    $providerChanged = ($providerIndex -lt 0)
    $defaultProviderChanged = ($currentProvider -ne $providerId)
    $trustChanged = ($trustIndex -lt 0)

    return @{
        OriginalContent = $originalContent
        UpdatedContent = $updatedContent
        ProviderChanged = $providerChanged
        DefaultProviderChanged = $defaultProviderChanged
        TrustChanged = $trustChanged
        CurrentDefaultProvider = $currentProvider
        Changed = ($updatedContent -ne $originalContent)
    }
}

function Save-CodexInstallConfigPlan {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Plan
    )

    if (-not $Plan.Changed) {
        return $null
    }

    return (Set-CodexConfigContent -Content $Plan.UpdatedContent -BackupSuffix "install")
}

function Get-CodexUninstallConfigPlan {
    param(
        [string]$FallbackProvider = "openai"
    )

    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
    $normalizedPath = $Script:ProjectRoot.ToLowerInvariant().Replace("\", "\\")
    $legacyPath = $Script:ProjectRoot.ToLowerInvariant()
    $providerHeader = "[model_providers.$providerId]"
    $trustHeaders = @(
        "[projects.'$normalizedPath']",
        "[projects.'$legacyPath']"
    )

    $originalContent = Get-CodexConfigContent
    $document = Get-CodexConfigDocument -Content $originalContent
    $providerChanged = ((Find-CodexConfigBlockIndex -Document $document -Header $providerHeader) -ge 0)

    $currentProvider = ""
    if ($originalContent) {
        $currentProvider = Get-CodexDefaultProvider
    }

    $updatedDocument = Remove-CodexConfigBlocks -Document $document -Headers @($providerHeader)

    $defaultProviderChanged = $false
    if ($currentProvider -eq $providerId) {
        $updatedDocument = Set-CodexRootStringKey -Document $updatedDocument -Key "model_provider" -Value $FallbackProvider
        $defaultProviderChanged = $true
    }

    $trustChanged = $false
    foreach ($header in $trustHeaders) {
        if ((Find-CodexConfigBlockIndex -Document $updatedDocument -Header $header) -ge 0) {
            $trustChanged = $true
            break
        }
    }
    $updatedDocument = Remove-CodexConfigBlocks -Document $updatedDocument -Headers $trustHeaders
    $updatedContent = Get-CodexConfigText -Document $updatedDocument

    return @{
        OriginalContent = $originalContent
        UpdatedContent = $updatedContent
        ProviderChanged = $providerChanged
        DefaultProviderChanged = $defaultProviderChanged
        TrustChanged = $trustChanged
        CurrentDefaultProvider = $currentProvider
        FallbackProvider = $FallbackProvider
        Changed = ($updatedContent -ne $originalContent)
    }
}

function Save-CodexUninstallConfigPlan {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Plan
    )

    if (-not $Plan.Changed) {
        return $null
    }

    return (Set-CodexConfigContent -Content $Plan.UpdatedContent -BackupSuffix "uninstall")
}

function Get-CodexLoginStatus {
    Assert-Command -Name "codex" -DisplayName "Codex CLI"
    $authPath = Join-Path $Script:CodexConfigDir "auth.json"
    $exitCode = $null

    try {
        cmd /c "codex login status >nul 2>nul" | Out-Null
    } catch {
    }

    $exitCodeVar = Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue
    if ($exitCodeVar) {
        $exitCode = [int]$exitCodeVar.Value
    }

    if ($exitCode -eq 0) {
        if (Test-Path $authPath) {
            return "Logged in"
        }

        return "Login status command succeeded"
    }

    if (Test-Path $authPath) {
        return "Auth file present; login status command output unavailable"
    }

    return "Not logged in"
}

function Test-CodexLoggedIn {
    return (Get-CodexLoginStatus) -match "^Logged in$"
}

function Test-CodexProviderConfigured {
    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]

    if (-not (Test-Path $Script:CodexConfigPath)) {
        return $false
    }

    $document = Get-CodexConfigDocument -Content (Get-CodexConfigContent)
    return ((Find-CodexConfigBlockIndex -Document $document -Header "[model_providers.$providerId]") -ge 0)
}

function Get-CodexDefaultProvider {
    if (-not (Test-Path $Script:CodexConfigPath)) {
        return ""
    }

    foreach ($line in (Get-CodexConfigRootLines -Document (Get-CodexConfigDocument -Content (Get-CodexConfigContent)))) {
        $match = [regex]::Match($line, '^\s*model_provider\s*=\s*"([^"]+)"')
        if ($match.Success) {
            return $match.Groups[1].Value
        }
    }

    return ""
}
