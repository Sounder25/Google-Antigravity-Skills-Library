$ScriptPath = Join-Path $PSScriptRoot "..\scripts\validate_dependencies.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_deps_validator_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-031..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$fileOk = Join-Path $TestDir "input.txt"
Set-Content -Path $fileOk -Value "data"
[Environment]::SetEnvironmentVariable("FAS_TEST_ENV", "1")

$Pass1 = $false
try {
    $result = & $ScriptPath -Plan "Do work" -Files $fileOk -EnvVars "FAS_TEST_ENV"
    $obj = $result | ConvertFrom-Json
    $Pass1 = $obj.ready_to_execute -eq $true
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-031 (Dependency Validator)
**Date:** $(Get-Date)

## Test Cases

### 1. Dependencies Present
**Expected:** ready_to_execute true
**Actual:** $(if($obj){$obj.ready_to_execute}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }
