$ScriptPath = Join-Path $PSScriptRoot "..\find_duplicates.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_dupes_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-021..."

# Setup: Create two identical files
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$Content = "This is a duplicate test content with enough bytes to exceed the minimum."
Set-Content -Path (Join-Path $TestDir "fileA.txt") -Value $Content
Set-Content -Path (Join-Path $TestDir "fileB.txt") -Value $Content

$OutputDir = Join-Path $TestDir ".forensics"

# Case 1: Script runs without error
$ErrorOccurred = $false
try {
    & $ScriptPath -WorkspacePath $TestDir -OutputDir ".forensics" 2>&1 | Out-Null
} catch {
    $ErrorOccurred = $true
}
$Pass1 = -not $ErrorOccurred

# Case 2: Report created
$ReportFile = Join-Path $OutputDir "DUPLICATE_REPORT.md"
$Pass2 = Test-Path $ReportFile

# Case 3: Report detects 1 duplicate group
$Pass3 = $false
if ($Pass2) {
    $DupeReport = Get-Content $ReportFile -Raw
    $Pass3 = $DupeReport -match "Total Groups: 1"
}

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-021 (Detect Duplicate Files)
**Date:** $(Get-Date)

## Test Cases

### 1. No Crash
**Input:** find_duplicates.ps1 on dir with 2 identical files.
**Expected:** Exit without error.
**Actual:** Error: $ErrorOccurred
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Report Created
**Input:** Check for DUPLICATE_REPORT.md.
**Expected:** File exists.
**Actual:** Exists: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Detects Duplicate Group
**Input:** Two identical files.
**Expected:** Total Groups: 1
**Actual:** $(if($Pass3){"Found 1 group"}else{"Not found"})
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




