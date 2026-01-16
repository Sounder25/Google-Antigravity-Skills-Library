# SKILL-001: Run EELS Test Suite
# Automates EELS compliance testing for EVM implementations

param(
    [Parameter(Mandatory = $true)]
    [string]$EvmBinary,
    
    [string]$TestFilter = "",
    [string]$SpecsPath = "",
    [string]$OutputDir = ".forensics",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# 1. Load Workspace Profile (SKILL-000 dependency)
$profilePath = ".\.forensics\WORKSPACE_PROFILE.json"
if (-not (Test-Path $profilePath)) {
    $profilePath = ".\WORKSPACE_PROFILE.json" # try root
}

if (Test-Path $profilePath) {
    $profile = Get-Content $profilePath | ConvertFrom-Json
    Write-Host "Loaded profile for: $($profile.workspace_name)" -ForegroundColor Cyan
}
else {
    Write-Warning "WORKSPACE_PROFILE.json not found. Running blind (SKILL-000 recommended)."
}

# 2. Locate execution-specs
if (-not $SpecsPath) {
    # Try to find it in common locations
    $candidates = @(
        ".\execution-specs",
        "..\execution-specs",
        "C:\projects\Scrutor\execution-specs",
        "C:\projects\Scrutor Test\execution-specs"
    )
    
    foreach ($c in $candidates) {
        if (Test-Path "$c\pyproject.toml") {
            $SpecsPath = Resolve-Path $c
            break
        }
    }
}

if (-not $SpecsPath -or -not (Test-Path $SpecsPath)) {
    Write-Error "Could not locate 'execution-specs' repository. Please specify --specs-path."
    exit 1
}
Write-Host "Using specs at: $SpecsPath" -ForegroundColor Gray

# 3. Verify EVM Binary
if (-not (Test-Path $EvmBinary)) {
    Write-Error "EVM binary not found at: $EvmBinary"
    exit 1
}
$EvmBinary = Resolve-Path $EvmBinary
Write-Host "Target EVM: $EvmBinary" -ForegroundColor Gray

# 4. Setup Python Environment
Push-Location $SpecsPath
try {
    if (-not (Test-Path ".venv")) {
        Write-Host "Creating Python venv..." -ForegroundColor Yellow
        python -m venv .venv
        if ($LASTEXITCODE -ne 0) { throw "Failed to create venv." }
    }
    
    # Activate venv
    $venvScript = ".\.venv\Scripts\Activate.ps1"
    if (Test-Path $venvScript) {
        . $venvScript
    }
    else {
        # Fallback for non-standard layouts
        $venvScript = ".\.venv\bin\Activate.ps1"
        if (Test-Path $venvScript) { . $venvScript } else { throw "Cannot find activate script." }
    }
    
    # Check dependencies
    if (-not (pip show execution-spec-tests 2>$null)) {
        Write-Host "Installing dependencies (this may take a minute)..." -ForegroundColor Yellow
        pip install -q -e .
        if ($LASTEXITCODE -ne 0) { throw "Failed to install dependencies." }
    }
    
    # 5. Run Tests
    Write-Host "Running tests..." -ForegroundColor Green
    if ($TestFilter) { Write-Host "Filter: $TestFilter" -ForegroundColor Cyan }
    
    # Construct command
    # Assuming pytest-xdist might be useful but let's stick to simple first
    # Pass EVM binary via typical t8n arg or env var depending on the runner.
    # Standard EELS tests often wrap the binary call.
    # Usually: pytest --evm-bin=...
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $jsonReport = "eels_report_$timestamp.json"
    
    $pytestArgs = @(
        "--evm-bin=$EvmBinary",
        "--tb=short"
    )
    if ($TestFilter) { $pytestArgs += "-k", "`"$TestFilter`"" }
    
    # Attempt to capture output
    # We use Invoke-Expression or direct call carefully
    $cmd = "pytest $pytestArgs"
    Write-Verbose "Executing: $cmd"
    
    # We capture stdout/stderr to parse summary
    $output = Invoke-Expression $cmd 2>&1 | Out-String
    $exitCode = $LASTEXITCODE # pytest exit codes: 0=all pass, 1=some fail, 2=interrupt, etc.
    
    # 6. Parse Results
    $summaryRegex = "(=+ (.*) =+)"
    $finalLine = ($output -split "`n" | Select-Object -Last 2 | Where-Object { $_ -match "=" }) -join ""
    
    $passed = 0
    $failed = 0
    $skipped = 0
    
    if ($finalLine -match "(\d+) passed") { $passed = $matches[1] }
    if ($finalLine -match "(\d+) failed") { $failed = $matches[1] }
    if ($finalLine -match "(\d+) skipped") { $skipped = $matches[1] }
    
    $total = [int]$passed + [int]$failed + [int]$skipped
    
    # 7. Generate Report
    Pop-Location # Go back to origin
    
    if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
    
    $reportPath = Join-Path $OutputDir "EELS_TEST_RESULTS_$timestamp.md"
    
    $mdReport = @"
# EELS Test Report

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**EVM Binary:** $EvmBinary
**Specs Path:** $SpecsPath
**Filter:** $(if($TestFilter){$TestFilter}else{"None"})

## Summary

- **Total:** $total
- **Passed:** $passed
- **Failed:** $failed
- **Skipped:** $skipped
- **Exit Code:** $exitCode

## Execution Log (Tail)

```text
$finalLine
```

## Recommendations

$(if ([int]$failed -gt 0) { "⚠️ **FAILURES DETECTED**: Check the full log or run with -v for details." } else { "✅ **SUCCESS**: All tests passed." })

"@
    
    $mdReport | Out-File -FilePath $reportPath -Encoding utf8
    Write-Host "Report saved: $reportPath" -ForegroundColor Green
    
    # Output to console nicely
    Write-Host "Passed: $passed" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Red
    Write-Host "Skipped: $skipped" -ForegroundColor Gray
    
}
catch {
    Write-Error "Error running EELS tests: $_"
    exit 1
}
finally {
    # Try to deactivate? Usually purely local to the script scope in PS, but good practice.
    if (Get-Command deactivate -ErrorAction SilentlyContinue) { deactivate }
}
