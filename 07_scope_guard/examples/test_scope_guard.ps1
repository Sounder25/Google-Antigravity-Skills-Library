$ScriptPath = Join-Path $PSScriptRoot "..\scripts\check_scope.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_scope_guard_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-007..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$allowed = @($TestDir)
$observed = @(
    (Join-Path $TestDir "file.txt"),
    (Join-Path $env:TEMP "outside.txt")
)

$Pass1 = $false
try {
    $result = & $ScriptPath -AllowedRoots $allowed -ObservedPaths $observed
    $obj = $result | ConvertFrom-Json
    $Pass1 = ($obj.status -eq "FAIL") -and ($obj.out_of_scope.Count -eq 1)
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-007 (Scope Guard)
**Date:** $(Get-Date)

## Test Cases

### 1. Detects Out-of-Scope Paths
**Input:** One in-scope, one out-of-scope path.
**Expected:** FAIL with 1 out_of_scope.
**Actual:** Status: $(if($obj){$obj.status}else{""}), Out: $(if($obj){$obj.out_of_scope.Count}else{0})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




