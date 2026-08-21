. (Join-Path $PSScriptRoot "common.ps1")

Assert-Command -Name "docker" -DisplayName "Docker CLI"
Assert-Command -Name "codex" -DisplayName "Codex CLI"
Ensure-ProjectDirectories

$expectedProviderId = $Script:ProjectConfig["CODEX_PROVIDER_ID"]
$results = @()

function Add-DoctorResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [bool]$Passed,
        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    $script:results += [pscustomobject]@{
        Name = $Name
        Passed = $Passed
        Detail = $Detail
    }
}

function Invoke-DoctorCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Check
    )

    try {
        & $Check
    } catch {
        Add-DoctorResult -Name $Name -Passed $false -Detail $_.Exception.Message
    }
}

Invoke-DoctorCheck -Name "Codex login" -Check {
    $status = Get-CodexLoginStatus
    Add-DoctorResult -Name "Codex login" -Passed ($status -match "^Logged in$") -Detail $status
}

Invoke-DoctorCheck -Name "Provider configured" -Check {
    $configured = Test-CodexProviderConfigured
    Add-DoctorResult -Name "Provider configured" -Passed $configured -Detail ("Expected provider '{0}' present: {1}" -f $expectedProviderId, $configured)
}

Invoke-DoctorCheck -Name "Default model_provider" -Check {
    $actualProvider = Get-CodexDefaultProvider
    $passed = $actualProvider -eq $expectedProviderId
    $detail = "Expected '{0}', found '{1}'" -f $expectedProviderId, $(if ($actualProvider) { $actualProvider } else { "<unset>" })
    Add-DoctorResult -Name "Default model_provider" -Passed $passed -Detail $detail
}

Invoke-DoctorCheck -Name "Analyzer health" -Check {
    $healthy = Test-HttpOk -Uri "$Script:AnalyzerBaseUrl/health"
    Add-DoctorResult -Name "Analyzer health" -Passed $healthy -Detail (Get-HealthSummary -Uri "$Script:AnalyzerBaseUrl/health")
}

Invoke-DoctorCheck -Name "Proxy health" -Check {
    $healthy = Test-HttpOk -Uri "$Script:ProxyBaseUrl/health"
    Add-DoctorResult -Name "Proxy health" -Passed $healthy -Detail (Get-HealthSummary -Uri "$Script:ProxyBaseUrl/health")
}

Invoke-DoctorCheck -Name "Demo proof" -Check {
    if (-not (Test-PrivacyStackHealthy)) {
        Add-DoctorResult -Name "Demo proof" -Passed $false -Detail "Privacy stack is not healthy. Run ./scripts/start.ps1 first."
        return
    }

    $output = & (Join-Path $PSScriptRoot "demo-proof.ps1") 2>&1
    $detail = ($output | Out-String).Trim()
    Add-DoctorResult -Name "Demo proof" -Passed $true -Detail $detail
}

Write-Output "LLM CLI Privacy Proxy doctor"
Write-Output "Proxy base URL: $Script:ProxyBaseUrl"
Write-Output ""

foreach ($result in $results) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    Write-Output ("[{0}] {1}: {2}" -f $status, $result.Name, $result.Detail)
}

$failed = @($results | Where-Object { -not $_.Passed })

Write-Output ""
Write-Output ("Summary: {0} passed, {1} failed" -f ($results.Count - $failed.Count), $failed.Count)

if ($failed.Count -gt 0) {
    throw "Doctor found failing checks."
}
