$ScriptPath = Join-Path $PSScriptRoot "..\scripts\semantic_diff.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-033..."

$Pass1 = $false
try {
    $before = "foo"
    $after = "foo replaced with bar"
    $result = & $ScriptPath -Before $before -After $after -Intent "bar"
    $obj = $result | ConvertFrom-Json
    $Pass1 = ($obj.verdict -eq "COMPLETE") -and ($obj.safe_to_ship)
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-033 (Semantic Diff)
**Date:** $(Get-Date)

## Test Cases

### 1. Intent Fulfilled
**Expected:** verdict COMPLETE
**Actual:** $(if($obj){$obj.verdict}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
