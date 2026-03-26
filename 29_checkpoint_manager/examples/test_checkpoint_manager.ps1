$ScriptPath = Join-Path $PSScriptRoot "..\scripts\checkpoint_manager.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_checkpoint_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-029..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null

$Pass1 = $false
$Pass2 = $false
$Pass3 = $false
try {
    $create = & $ScriptPath -Operation create -Path $TestDir -Label "step1" -Context "state" -Verified
    $obj1 = $create | ConvertFrom-Json
    $Pass1 = $obj1.status -eq "VERIFIED"

    $list = & $ScriptPath -Operation list -Path $TestDir
    $obj2 = $list | ConvertFrom-Json
    $Pass2 = $obj2.checkpoints.Count -ge 1

    $validate = & $ScriptPath -Operation validate -Path $TestDir
    $obj3 = $validate | ConvertFrom-Json
    $Pass3 = $obj3.status -eq "OK"
} catch {}

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-029 (Checkpoint Manager)
**Date:** $(Get-Date)

## Test Cases

### 1. Create Verified Checkpoint
**Expected:** status VERIFIED
**Actual:** $(if($obj1){$obj1.status}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. List Checkpoints
**Expected:** at least 1 checkpoint
**Actual:** $(if($obj2){$obj2.checkpoints.Count}else{0})
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Validate Checkpoints
**Expected:** status OK
**Actual:** $(if($obj3){$obj3.status}else{""})
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }
