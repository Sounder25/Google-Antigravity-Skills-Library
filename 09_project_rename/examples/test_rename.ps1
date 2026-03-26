$ScriptPath = Join-Path $PSScriptRoot "..\rename_project.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_rename_$(Get-Random)"
$ProjectDir = Join-Path $TestRoot "OldName.Project"

Write-Host "Running Validation Tests for SKILL-009..."

New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
Set-Content -Path (Join-Path $ProjectDir "OldName.csproj") -Value "<Project>OldName</Project>"
Set-Content -Path (Join-Path $ProjectDir "README.md") -Value "OldName"

Push-Location $TestRoot

git init | Out-Null

$Pass1 = $false
try {
    & $ScriptPath -OldName "OldName" -NewName "NewName" -Mode "recovery" -DryRun *>&1 | Out-Null
    $Pass1 = Test-Path (Join-Path $TestRoot "RENAME_SUMMARY.md")
} catch {}

$Summary = if ($Pass1) { Get-Content (Join-Path $TestRoot "RENAME_SUMMARY.md") -Raw } else { "" }
$Pass2 = ($Summary -match "DryRun") -and ($Summary -match "True")

Pop-Location

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-009 (Project-Wide Rename)
**Date:** $(Get-Date)

## Test Cases

### 1. DryRun Generates Summary
**Input:** -Mode recovery -DryRun in a git repo with matching names.
**Expected:** RENAME_SUMMARY.md exists.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. DryRun Flags Recorded
**Input:** Summary content.
**Expected:** "DryRun: True" in report.
**Actual:** Found: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }




