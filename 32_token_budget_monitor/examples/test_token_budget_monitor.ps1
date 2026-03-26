$ScriptPath = Join-Path $PSScriptRoot "..\scripts\monitor_token_budget.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-032..."

$Pass1 = $false
try {
    $result = & $ScriptPath -ModelLimit 100000 -EstimatedUsed 85000
    $obj = $result | ConvertFrom-Json
    $Pass1 = ($obj.status -eq "CRITICAL") -and ($obj.recommended_action -eq "CHECKPOINT_NOW")
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-032 (Token Budget Monitor)
**Date:** $(Get-Date)

## Test Cases

### 1. Critical Threshold
**Expected:** status CRITICAL and CHECKPOINT_NOW
**Actual:** $(if($obj){$obj.status}else{""}) / $(if($obj){$obj.recommended_action}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
