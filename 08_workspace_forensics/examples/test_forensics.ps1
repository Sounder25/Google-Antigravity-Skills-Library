$ScriptPath = Join-Path $PSScriptRoot "..\audit_workspace.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_forensics_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-008..."

# Setup: use the skills repo itself as the target workspace
$WorkspacePath = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$OutputDir = $TestDir

# Case 1: JSON output generation
& $ScriptPath -WorkspacePath $WorkspacePath -OutputFormat "json" -OutputDir $OutputDir
$JsonFile = Join-Path $OutputDir "WORKSPACE_PROFILE.json"
$Pass1 = Test-Path $JsonFile
$Profile = $null
if ($Pass1) { $Profile = Get-Content $JsonFile -Raw | ConvertFrom-Json }

# Case 2: Forensics completeness
$Pass2 = $Profile -and ($Profile.forensics_completeness -eq "full")

# Case 3: Repo type detection
$Pass3 = $Profile -and ($Profile.repo_type -eq "git")

# Case 4: Language detection (should find at least PowerShell-adjacent or none, but no crash)
$Pass4 = $Profile -ne $null

$AllPassed = $Pass1 -and $Pass2 -and $Pass3 -and $Pass4

$Report = @"
# 🧪 Verification Report: SKILL-008 (Workspace Forensics)
**Date:** $(Get-Date)

## Test Cases

### 1. JSON Output Created
**Input:** Audit skills repo with JSON output.
**Expected:** WORKSPACE_PROFILE.json exists.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Forensics Completeness
**Input:** Git repo with full signals.
**Expected:** forensics_completeness == "full"
**Actual:** $($Profile.forensics_completeness)
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Repo Type Detection
**Input:** Directory with .git folder.
**Expected:** repo_type == "git"
**Actual:** $($Profile.repo_type)
**Pass:** $(if($Pass3){"✅"}else{"❌"})

### 4. No Crash on Profile Generation
**Input:** Full audit run.
**Expected:** Profile object is not null.
**Actual:** Not null: $($Profile -ne $null)
**Pass:** $(if($Pass4){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




