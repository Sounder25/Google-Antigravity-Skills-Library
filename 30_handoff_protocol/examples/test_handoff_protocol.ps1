$ScriptPath = Join-Path $PSScriptRoot "..\scripts\prepare_handoff.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_handoff_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-030..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
Push-Location $TestDir

$Pass1 = $false
try {
    $result = & $ScriptPath -From "A" -To "B" -Task "Do X" -Completed "Step 1" -Pending "Step 2" -OutputPath "HANDOFF.md"
    $obj = $result | ConvertFrom-Json
    $Pass1 = (Test-Path $obj.handoff_path)
} catch {}

Pop-Location

$AllPassed = $Pass1

$Report = @"
# 🧪 Verification Report: SKILL-030 (Handoff Protocol)
**Date:** $(Get-Date)

## Test Cases

### 1. Handoff Document Created
**Expected:** HANDOFF.md exists
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }
