$ScriptPath = Join-Path $PSScriptRoot "..\init_plan.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_planner_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-014..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$OutputPlan = Join-Path $TestDir "PLAN.json"

# Case 1: Plan creation
Push-Location $TestDir
try {
    & $ScriptPath -Objective "Automated Test Objective" -OutputPath $OutputPlan -Force 2>&1 | Out-Null
} catch {}
Pop-Location

$Pass1 = Test-Path $OutputPlan

# Case 2: Valid JSON
$PlanContent = $null
$Pass2 = $false
if ($Pass1) {
    try {
        $PlanContent = Get-Content $OutputPlan -Raw | ConvertFrom-Json
        $Pass2 = $true
    } catch {}
}

# Case 3: Contains objective
$Pass3 = $false
if ($PlanContent) {
    $rawJson = Get-Content $OutputPlan -Raw
    $Pass3 = $rawJson -match "Automated Test Objective"
}

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-014 (Deterministic Planner)
**Date:** $(Get-Date)

## Test Cases

### 1. Plan File Created
**Input:** init_plan.ps1 -Objective "Automated Test Objective"
**Expected:** PLAN.json exists.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Valid JSON
**Input:** Parse PLAN.json.
**Expected:** No parse errors.
**Actual:** Valid: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Contains Objective
**Input:** Search for objective string.
**Expected:** "Automated Test Objective" present.
**Actual:** Found: $Pass3
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




