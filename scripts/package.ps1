param(
    [string]$OutputDir
)

. (Join-Path $PSScriptRoot "common.ps1")

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $Script:ProjectRoot "dist"
}

$excludedDirectoryNames = @("__pycache__")
$excludedFilePatterns = @("*.pyc", "*.pyo")

function Copy-PackageItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    $item = Get-Item -LiteralPath $SourcePath

    if ($item.PSIsContainer) {
        New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null

        Get-ChildItem -LiteralPath $SourcePath | ForEach-Object {
            if ($_.PSIsContainer -and $_.Name -in $excludedDirectoryNames) {
                return
            }

            if (-not $_.PSIsContainer) {
                foreach ($pattern in $excludedFilePatterns) {
                    if ($_.Name -like $pattern) {
                        return
                    }
                }
            }

            Copy-PackageItem `
                -SourcePath $_.FullName `
                -DestinationPath (Join-Path $DestinationPath $_.Name)
        }

        return
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
}

$version = (Get-Content -LiteralPath (Join-Path $Script:ProjectRoot "VERSION") -Raw).Trim()
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) ("llm-cli-privacy-proxy-" + [guid]::NewGuid().ToString("N"))
$packageName = "llm-cli-privacy-proxy-v$version-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".zip"
$packagePath = Join-Path $OutputDir $packageName

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $stagingDir | Out-Null

try {
    $itemsToCopy = @(
        "docker-compose.yml",
        "Dockerfile.analyzer",
        "README.md",
        "VERSION",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        ".env.example",
        ".gitignore",
        "analyzer-config.yaml",
        "recognizers.yaml",
        "docs",
        "privacy-service",
        "scripts"
    )

    foreach ($item in $itemsToCopy) {
        Copy-PackageItem `
            -SourcePath (Join-Path $Script:ProjectRoot $item) `
            -DestinationPath (Join-Path $stagingDir $item)
    }

    $cacheDir = Join-Path $stagingDir "privacy-cache"
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    Set-Content -LiteralPath (Join-Path $cacheDir ".gitkeep") -Value "" -Encoding UTF8

    if (Test-Path $packagePath) {
        Remove-Item -LiteralPath $packagePath -Force
    }

    Compress-Archive `
        -Path (Join-Path $stagingDir "*") `
        -DestinationPath $packagePath `
        -CompressionLevel Optimal

    Write-Output "Package created: $packagePath"
} finally {
    if (Test-Path $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force
    }
}
