param(
    [string]$MockServerUrl,
    [string]$TestPath = "Tests/doc-downloader.Integration.Tests.ps1"
)

if ($MockServerUrl) {
    $ready = $false
    $maxAttempts = 30
    $attempts = 0

    while (-not $ready -and $attempts -lt $maxAttempts) {
        Write-Host "Waiting for mock server at $MockServerUrl..."
        try {
            $response = Invoke-WebRequest -Uri "$MockServerUrl/api/v1/documents/queued/next" -ErrorAction SilentlyContinue
            $ready = $true
        } catch {
            $ready = $false
            Start-Sleep -Seconds 2
            $attempts++
        }
    }

    if (-not $ready) {
        Write-Error "Mock server failed to start in time."
        exit 1
    }
    Write-Host "Mock server is ready."
}

Write-Host "Running tests: $TestPath"
$pesterResult = Invoke-Pester -Path $TestPath -Output Detailed -PassThru

Write-Host "---------------------------------------"
Write-Host "Test Summary:"
Write-Host "Passed: $($pesterResult.PassedCount)"
Write-Host "Failed: $($pesterResult.FailedCount)"
Write-Host "---------------------------------------"

if ($pesterResult.FailedCount -gt 0) {
    Write-Host "Exiting with code 1 due to test failures."
    exit 1
}

Write-Host "Exiting with code 0."
exit 0
