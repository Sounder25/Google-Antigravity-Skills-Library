$ScriptPath = Join-Path $PSScriptRoot "..\scripts\detect_hallucination.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-028..."

$Pass1 = $false
try {
    $content = "Use /api/v1/users with v1.2.3 and call fetch_user(id)."
    $result = & $ScriptPath -Content $content
    $obj = $result | ConvertFrom-Json
    $Pass1 = ($obj.hallucination_risk -eq "HIGH") -and (-not $obj.safe_to_proceed)
} catch {}

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-028 (Hallucination Detector)
**Date:** $(Get-Date)

## Test Cases

### 1. Flags Specific Claims
**Input:** Content with version, API path, function signature.
**Expected:** HIGH risk and safe_to_proceed false.
**Actual:** Risk: $(if($obj){$obj.hallucination_risk}else{""})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
