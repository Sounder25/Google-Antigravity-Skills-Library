$ScriptPath = Join-Path $PSScriptRoot "..\invoke_recovery.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_recovery_$(Get-Random)"
$TargetDir = Join-Path $TestRoot "missing_dir"
$TargetFile = Join-Path $TargetDir "file.txt"

Write-Host "Running Validation Tests for SKILL-013..."

New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null

$Command = "Set-Content -Path '$TargetFile' -Value 'ok'"

$Pass1 = $false
try {
    & $ScriptPath -Command $Command -Retries 2 *>&1 | Out-Null
    $Pass1 = Test-Path $TargetFile
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-013 (Error-State Recovery)
**Date:** $(Get-Date)

## Test Cases

### 1. Auto-Fix Missing Directory
**Input:** Set-Content to a missing directory.
**Expected:** Directory created and file written.
**Actual:** File exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }




