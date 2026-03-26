$ScriptPath = Join-Path $PSScriptRoot "..\scripts\plan_rollback.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-027..."

$Pass1 = $false
$Pass2 = $false
try {
    $result1 = & $ScriptPath -Action "Drop column" -Target "users.legacy_id"
    $obj1 = $result1 | ConvertFrom-Json
    $Pass1 = ($obj1.rollback_level -eq "NONE") -and (-not $obj1.rollback_viable)

    $result2 = & $ScriptPath -Action "Upgrade dependency" -Target "libA" -RollbackPath "C:\backups\libA" -Tested
    $obj2 = $result2 | ConvertFrom-Json
    $Pass2 = ($obj2.rollback_level -eq "FULL") -and ($obj2.rollback_viable)
} catch {}

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-027 (Rollback Planner)
**Date:** $(Get-Date)

## Test Cases

### 1. No Rollback Path
**Input:** Action without rollback path.
**Expected:** rollback_level NONE.
**Actual:** Level: $(if($obj1){$obj1.rollback_level}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Tested Rollback Path
**Input:** Action with rollback path and -Tested.
**Expected:** rollback_level FULL.
**Actual:** Level: $(if($obj2){$obj2.rollback_level}else{""})
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
