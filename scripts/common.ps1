Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$Script:ComposeFile = Join-Path $Script:ProjectRoot "docker-compose.yml"
$Script:EnvExamplePath = Join-Path $Script:ProjectRoot ".env.example"
$Script:EnvPath = Join-Path $Script:ProjectRoot ".env"
$Script:CodexConfigDir = Join-Path $HOME ".codex"
$Script:CodexConfigPath = Join-Path $Script:CodexConfigDir "config.toml"

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

$Script:ProjectConfig = Get-ProjectConfig
$Script:ProxyBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["PROXY_PORT"]
$Script:AnalyzerBaseUrl = "http://{0}:{1}" -f $Script:ProjectConfig["PROXY_BIND_HOST"], $Script:ProjectConfig["ANALYZER_PORT"]

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

function Set-CodexConfigContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$BackupSuffix
    )

    $backupPath = New-CodexConfigBackup -Suffix $BackupSuffix
    $trimmed = $Content.TrimEnd()
    $finalContent = if ($trimmed) {
        $trimmed + [Environment]::NewLine
    } else {
        ""
    }

    Set-Content -Path $Script:CodexConfigPath -Value $finalContent -Encoding UTF8
    return $backupPath
}

function Get-CodexConfigContent {
    if (-not (Test-Path $Script:CodexConfigPath)) {
        return ""
    }

    return (Get-Content -Raw $Script:CodexConfigPath)
}

function Remove-TomlSectionsByHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string[]]$Headers
    )

    $lines = [regex]::Split($Content, "\r?\n")
    $result = New-Object System.Collections.Generic.List[string]
    $skipSection = $false

    foreach ($line in $lines) {
        if ($skipSection) {
            if ($line -match '^\[') {
                $skipSection = $false
            } else {
                continue
            }
        }

        if ($Headers -contains $line.Trim()) {
            $skipSection = $true
            continue
        }

        $result.Add($line)
    }

    return ($result -join [Environment]::NewLine)
}

function Add-TomlSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Section
    )

    $trimmed = $Content.TrimEnd()
    if (-not $trimmed) {
        return ($Section.TrimEnd() + [Environment]::NewLine)
    }

    return ($trimmed + [Environment]::NewLine + [Environment]::NewLine + $Section.TrimEnd() + [Environment]::NewLine)
}

function Set-CodexDefaultProviderInContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$ProviderId
    )

    if ($Content -match '(?m)^model_provider\s*=') {
        return [regex]::Replace(
            $Content,
            '(?m)^model_provider\s*=.*$',
            "model_provider = `"$ProviderId`""
        )
    }

    $trimmed = $Content.TrimEnd()
    if (-not $trimmed) {
        return ("model_provider = `"$ProviderId`"" + [Environment]::NewLine)
    }

    return ($trimmed + [Environment]::NewLine + "model_provider = `"$ProviderId`"" + [Environment]::NewLine)
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
    return ((Test-HttpOk -Uri "$Script:AnalyzerBaseUrl/health") -and (Test-HttpOk -Uri "$Script:ProxyBaseUrl/health"))
}

function Ensure-CodexProviderConfig {
    if (-not (Test-Path $Script:CodexConfigDir)) {
        New-Item -ItemType Directory -Force -Path $Script:CodexConfigDir | Out-Null
    }

    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
    $providerName = $Script:ProjectConfig["PRIVACY_PROVIDER_NAME"]

    $providerBlock = @"
[model_providers.$providerId]
name = "$providerName"
base_url = "$Script:ProxyBaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
"@

    if (-not (Test-Path $Script:CodexConfigPath)) {
        Set-Content -Path $Script:CodexConfigPath -Value ($providerBlock + [Environment]::NewLine) -Encoding UTF8
        return @{
            Changed = $true
            BackupPath = $null
        }
    }

    $content = Get-Content -Raw $Script:CodexConfigPath
    $providerPattern = '^\[model_providers\.' + [regex]::Escape($providerId) + '\]\r?$'
    if ($content -match "(?m)$providerPattern") {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $trimmed = $content.TrimEnd()
    $updated = $trimmed + [Environment]::NewLine + [Environment]::NewLine + $providerBlock + [Environment]::NewLine
    $backupPath = Set-CodexConfigContent -Content $updated -BackupSuffix "provider"

    return @{
        Changed = $true
        BackupPath = $backupPath
    }
}

function Ensure-CodexDefaultProvider {
    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]

    if (-not (Test-Path $Script:CodexConfigDir)) {
        New-Item -ItemType Directory -Force -Path $Script:CodexConfigDir | Out-Null
    }

    if (-not (Test-Path $Script:CodexConfigPath)) {
        Set-Content -Path $Script:CodexConfigPath -Value ("model_provider = `"$providerId`"" + [Environment]::NewLine) -Encoding UTF8
        return @{
            Changed = $true
            BackupPath = $null
        }
    }

    $content = Get-Content -Raw $Script:CodexConfigPath
    $updated = $content

    if ($content -match '(?m)^model_provider\s*=') {
        $updated = [regex]::Replace(
            $content,
            '(?m)^model_provider\s*=.*$',
            "model_provider = `"$providerId`""
        )
    } else {
        $trimmed = $content.TrimEnd()
        $updated = $trimmed + [Environment]::NewLine + "model_provider = `"$providerId`"" + [Environment]::NewLine
    }

    if ($updated -eq $content) {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $backupPath = Set-CodexConfigContent -Content $updated -BackupSuffix "default-provider"

    return @{
        Changed = $true
        BackupPath = $backupPath
    }
}

function Ensure-CodexProjectTrust {
    param(
        [string]$ProjectPath = $Script:ProjectRoot
    )

    if (-not (Test-Path $Script:CodexConfigDir)) {
        New-Item -ItemType Directory -Force -Path $Script:CodexConfigDir | Out-Null
    }

    $normalizedPath = $ProjectPath.ToLowerInvariant().Replace("\", "\\")
    $projectBlock = @"
[projects.'$normalizedPath']
trust_level = "trusted"
"@

    if (-not (Test-Path $Script:CodexConfigPath)) {
        Set-Content -Path $Script:CodexConfigPath -Value ($projectBlock + [Environment]::NewLine) -Encoding UTF8
        return @{
            Changed = $true
            BackupPath = $null
        }
    }

    $content = Get-Content -Raw $Script:CodexConfigPath
    $projectPattern = '^\[projects\.' + [regex]::Escape("'" + $normalizedPath + "'") + '\]\r?$'
    if ($content -match "(?m)$projectPattern") {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $trimmed = $content.TrimEnd()
    $updated = $trimmed + [Environment]::NewLine + [Environment]::NewLine + $projectBlock + [Environment]::NewLine
    $backupPath = Set-CodexConfigContent -Content $updated -BackupSuffix "project-trust"

    return @{
        Changed = $true
        BackupPath = $backupPath
    }
}

function Remove-CodexProviderConfig {
    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]

    if (-not (Test-Path $Script:CodexConfigPath)) {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $content = Get-Content -Raw $Script:CodexConfigPath
    $header = "[model_providers.$providerId]"
    $updated = Remove-TomlSectionsByHeader -Content $content -Headers @($header)

    if ($updated -eq $content) {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $backupPath = Set-CodexConfigContent -Content $updated -BackupSuffix "remove-provider"
    return @{
        Changed = $true
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

    $content = Get-Content -Raw $Script:CodexConfigPath
    $current = Get-CodexDefaultProvider

    if ($current -ne $ProviderId) {
        return @{
            Changed = $false
            BackupPath = $null
            PreviousValue = $current
        }
    }

    $updated = [regex]::Replace(
        $content,
        '(?m)^model_provider\s*=.*$',
        "model_provider = `"$FallbackProvider`""
    )

    if ($updated -eq $content) {
        return @{
            Changed = $false
            BackupPath = $null
            PreviousValue = $current
        }
    }

    $backupPath = Set-CodexConfigContent -Content $updated -BackupSuffix "restore-default-provider"
    return @{
        Changed = $true
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

    $normalizedPath = $ProjectPath.ToLowerInvariant().Replace("\", "\\")
    $legacyPath = $ProjectPath.ToLowerInvariant()
    $content = Get-Content -Raw $Script:CodexConfigPath
    $headers = @(
        "[projects.'$normalizedPath']",
        "[projects.'$legacyPath']"
    )
    $updated = Remove-TomlSectionsByHeader -Content $content -Headers $headers

    if ($updated -eq $content) {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $backupPath = Set-CodexConfigContent -Content $updated -BackupSuffix "remove-project-trust"
    return @{
        Changed = $true
        BackupPath = $backupPath
    }
}

function Get-CodexInstallConfigPlan {
    if (-not (Test-Path $Script:CodexConfigDir)) {
        New-Item -ItemType Directory -Force -Path $Script:CodexConfigDir | Out-Null
    }

    $providerId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
    $providerName = $Script:ProjectConfig["PRIVACY_PROVIDER_NAME"]
    $normalizedPath = $Script:ProjectRoot.ToLowerInvariant().Replace("\", "\\")
    $providerHeader = "[model_providers.$providerId]"
    $trustHeader = "[projects.'$normalizedPath']"
    $providerBlock = @"
[model_providers.$providerId]
name = "$providerName"
base_url = "$Script:ProxyBaseUrl"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
"@
    $trustBlock = @"
[projects.'$normalizedPath']
trust_level = "trusted"
"@

    $originalContent = Get-CodexConfigContent
    $updatedContent = $originalContent

    $providerChanged = $false
    if ($updatedContent -notmatch "(?m)^\[model_providers\.$([regex]::Escape($providerId))\]\r?$") {
        $updatedContent = Add-TomlSection -Content $updatedContent -Section $providerBlock
        $providerChanged = $true
    }

    $defaultProviderChanged = $false
    $currentProvider = ""
    if ($originalContent) {
        $currentProvider = Get-CodexDefaultProvider
    }
    $providerUpdatedContent = Set-CodexDefaultProviderInContent -Content $updatedContent -ProviderId $providerId
    if ($providerUpdatedContent -ne $updatedContent) {
        $updatedContent = $providerUpdatedContent
        $defaultProviderChanged = $true
    }

    $trustChanged = $false
    if ($updatedContent -notmatch "(?m)^\[projects\.$([regex]::Escape("'" + $normalizedPath + "'"))\]\r?$") {
        $updatedContent = Add-TomlSection -Content $updatedContent -Section $trustBlock
        $trustChanged = $true
    }

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
    $updatedContent = $originalContent

    $providerRemovedContent = Remove-TomlSectionsByHeader -Content $updatedContent -Headers @($providerHeader)
    $providerChanged = ($providerRemovedContent -ne $updatedContent)
    $updatedContent = $providerRemovedContent

    $currentProvider = ""
    if ($originalContent) {
        $currentProvider = Get-CodexDefaultProvider
    }

    $defaultProviderChanged = $false
    if ($currentProvider -eq $providerId) {
        $restoredContent = Set-CodexDefaultProviderInContent -Content $updatedContent -ProviderId $FallbackProvider
        $defaultProviderChanged = ($restoredContent -ne $updatedContent)
        $updatedContent = $restoredContent
    }

    $trustRemovedContent = Remove-TomlSectionsByHeader -Content $updatedContent -Headers $trustHeaders
    $trustChanged = ($trustRemovedContent -ne $updatedContent)
    $updatedContent = $trustRemovedContent

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

    $content = Get-Content -Raw $Script:CodexConfigPath
    $providerPattern = '^\[model_providers\.' + [regex]::Escape($providerId) + '\]\r?$'
    return $content -match "(?m)$providerPattern"
}

function Get-CodexDefaultProvider {
    if (-not (Test-Path $Script:CodexConfigPath)) {
        return ""
    }

    $content = Get-Content -Raw $Script:CodexConfigPath
    $match = [regex]::Match($content, '(?m)^model_provider\s*=\s*"([^"]+)"')

    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return ""
}
