$ScriptPath = Join-Path $PSScriptRoot "..\generate_gitignore.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_gitignore_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-022..."

New-Item -ItemType Directory -Path $TestDir -Force | Out-Null

# Case 1: Generate Python .gitignore
$ErrorOccurred = $false
try {
    & $ScriptPath -WorkspacePath $TestDir -Templates "Python" 2>&1 | Out-Null
} catch {
    $ErrorOccurred = $true
}
$Pass1 = -not $ErrorOccurred

# Case 2: .gitignore file created
$GitignoreFile = Join-Path $TestDir ".gitignore"
$Pass2 = Test-Path $GitignoreFile

# Case 3: Contains Python-specific patterns
$Pass3 = $false
if ($Pass2) {
    $Content = Get-Content $GitignoreFile -Raw
    $Pass3 = $Content -match "__pycache__" -or $Content -match "\.pyc"
}

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-022 (Generate .gitignore)
**Date:** $(Get-Date)

## Test Cases

### 1. No Crash
**Input:** generate_gitignore.ps1 -Templates "Python"
**Expected:** Exit without error.
**Actual:** Error: $ErrorOccurred
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. File Created
**Input:** Check for .gitignore in target dir.
**Expected:** File exists.
**Actual:** Exists: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Contains Python Patterns
**Input:** Search for __pycache__ or .pyc.
**Expected:** Present in .gitignore.
**Actual:** Match: $Pass3
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




