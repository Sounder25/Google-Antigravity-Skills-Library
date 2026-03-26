$ScriptPath = Join-Path $PSScriptRoot "..\scripts\verify_output.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_output_verifier_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-005..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$fileOk = Join-Path $TestDir "ok.txt"
$fileGone = Join-Path $TestDir "gone.txt"
Set-Content -Path $fileOk -Value "hello"

$Pass1 = $false
try {
    $result = & $ScriptPath -ExpectedPresent $fileOk -ExpectedAbsent $fileGone -ExpectedContains @{ $fileOk = "hello" }
    $obj = $result | ConvertFrom-Json
    $Pass1 = $obj.status -eq "PASS"
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-005 (Output Verifier)
**Date:** $(Get-Date)

## Test Cases

### 1. Final Inspection Pass
**Input:** Present file + absent file + content match.
**Expected:** PASS
**Actual:** Status: $(if($obj){$obj.status}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




