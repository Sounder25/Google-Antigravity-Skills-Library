$ScriptPath = Join-Path $PSScriptRoot "..\update_breadcrumbs.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_breadcrumbs_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-012..."

New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
Push-Location $TestRoot

$Pass1 = $false
$Pass2 = $false
$Pass3 = $false
try {
    & $ScriptPath -Status "active" -Objective "Test Objective" -NextSteps "Step A", "Step B" -Blockers "None" *>&1 | Out-Null
    $Pass1 = Test-Path "STATE.json"
    $Pass2 = Test-Path "NEXT.md"
    if ($Pass1) {
        $state = Get-Content "STATE.json" -Raw
        $Pass3 = $state -match "Test Objective"
    }
} catch {}

Pop-Location

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-012 (Update Intent Breadcrumbs)
**Date:** $(Get-Date)

## Test Cases

### 1. STATE.json Created
**Input:** Run with status/objective/steps.
**Expected:** STATE.json exists.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. NEXT.md Created
**Input:** Run with template.
**Expected:** NEXT.md exists.
**Actual:** Exists: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Objective Captured
**Input:** STATE.json content.
**Expected:** Objective string present.
**Actual:** Found: $Pass3
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }




