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
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    & docker compose -f $Script:ComposeFile @Args

    if ($LASTEXITCODE -ne 0) {
        throw "docker compose $($Args -join ' ') failed."
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
    $providerPattern = '^\[model_providers\.' + [regex]::Escape($providerId) + '\]$'
    if ($content -match "(?m)$providerPattern") {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = "$Script:CodexConfigPath.$timestamp.bak"
    Copy-Item -LiteralPath $Script:CodexConfigPath -Destination $backupPath

    $trimmed = $content.TrimEnd()
    $updated = $trimmed + [Environment]::NewLine + [Environment]::NewLine + $providerBlock + [Environment]::NewLine
    Set-Content -Path $Script:CodexConfigPath -Value $updated -Encoding UTF8

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
    $projectPattern = '^\[projects\.' + [regex]::Escape("'" + $normalizedPath + "'") + '\]$'
    if ($content -match "(?m)$projectPattern") {
        return @{
            Changed = $false
            BackupPath = $null
        }
    }

    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = "$Script:CodexConfigPath.$timestamp.project-trust.bak"
    Copy-Item -LiteralPath $Script:CodexConfigPath -Destination $backupPath

    $trimmed = $content.TrimEnd()
    $updated = $trimmed + [Environment]::NewLine + [Environment]::NewLine + $projectBlock + [Environment]::NewLine
    Set-Content -Path $Script:CodexConfigPath -Value $updated -Encoding UTF8

    return @{
        Changed = $true
        BackupPath = $backupPath
    }
}

function Get-CodexLoginStatus {
    Assert-Command -Name "codex" -DisplayName "Codex CLI"
    $authPath = Join-Path $Script:CodexConfigDir "auth.json"

    try {
        & codex login status > $null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $authPath)) {
            return "Logged in"
        }
    } catch {
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
    $providerPattern = '^\[model_providers\.' + [regex]::Escape($providerId) + '\]$'
    return $content -match "(?m)$providerPattern"
}
