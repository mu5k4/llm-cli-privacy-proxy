param(
    [string]$OutputDir
)

. (Join-Path $PSScriptRoot "common.ps1")

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $Script:ProjectRoot "dist"
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
        Copy-Item `
            -LiteralPath (Join-Path $Script:ProjectRoot $item) `
            -Destination (Join-Path $stagingDir $item) `
            -Recurse `
            -Force
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
