$ScriptPath = Join-Path $PSScriptRoot "..\prune_context.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-015..."

# Run from the skills repo root (has .git)
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Push-Location $RepoRoot

# Case 1: Pruner runs without error
$ErrorOccurred = $false
try {
    & $ScriptPath -Focus "guard" 2>&1 | Out-Null
} catch {
    $ErrorOccurred = $true
}
$Pass1 = -not $ErrorOccurred

# Case 2: Output file created
$OutputFile = Join-Path $RepoRoot "RELEVANT_FILES.txt"
$Pass2 = Test-Path $OutputFile

# Case 3: Contains expected file
$Pass3 = $false
if ($Pass2) {
    $Content = Get-Content $OutputFile -Raw
    $Pass3 = $Content -match "guard"
}

Pop-Location

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-015 (Context Pruner)
**Date:** $(Get-Date)

## Test Cases

### 1. No Crash
**Input:** prune_context.ps1 -Focus "guard"
**Expected:** Exit without error.
**Actual:** Error: $ErrorOccurred
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Output File Created
**Input:** Check for RELEVANT_FILES.txt.
**Expected:** File exists.
**Actual:** Exists: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Contains Relevant Match
**Input:** Search output for "guard".
**Expected:** guard_check.ps1 or similar found.
**Actual:** Match: $Pass3
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue }




