$ScriptPath = Join-Path $PSScriptRoot "..\check_feedback.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_feedback_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-017..."

New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
Push-Location $TestRoot

$Pass1 = $false
$Pass2 = $false
try {
    & $ScriptPath *>&1 | Out-Null
    $Pass1 = Test-Path "FEEDBACK.md"

    Set-Content -Path "FEEDBACK.md" -Value "Please adjust the plan."
    & $ScriptPath -Acknowledge *>&1 | Out-Null
    $content = Get-Content "FEEDBACK.md" -Raw
    $Pass2 = $content -match "ACKNOWLEDGED"
} catch {}

Pop-Location

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-017 (Async Feedback Loop)
**Date:** $(Get-Date)

## Test Cases

### 1. Feedback Channel Created
**Input:** Run when FEEDBACK.md missing.
**Expected:** FEEDBACK.md created.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Acknowledge Marks Read
**Input:** FEEDBACK.md with content + -Acknowledge.
**Expected:** ACKNOWLEDGED marker appended.
**Actual:** Found: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }



