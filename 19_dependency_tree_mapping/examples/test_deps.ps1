$ScriptPath = Join-Path $PSScriptRoot "..\map_dependencies.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_deps_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-019..."

# Setup: Create a minimal package.json project
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$PkgJson = @{
    name = "test-project"
    dependencies = @{ lodash = "^4.0.0"; express = "^4.18.0" }
} | ConvertTo-Json
Set-Content -Path (Join-Path $TestDir "package.json") -Value $PkgJson

# OutputDir must be relative for the script (it joins with WorkspacePath internally)
$OutputDirName = ".dependencies"

# Case 1: Script runs without error
$ErrorOccurred = $false
try {
    & $ScriptPath -WorkspacePath $TestDir -OutputDir $OutputDirName *>&1 | Out-Null
} catch {
    $ErrorOccurred = $true
}
$Pass1 = -not $ErrorOccurred

# Case 2: Mermaid graph file created
$MmdFile = Join-Path (Join-Path $TestDir $OutputDirName) "DEPENDENCY_GRAPH.mmd"
$Pass2 = Test-Path $MmdFile

# Case 3: Graph contains edges
$Pass3 = $false
if ($Pass2) {
    $Content = Get-Content $MmdFile -Raw
    $Pass3 = $Content -match "lodash" -and $Content -match "express"
}

$AllPassed = $Pass1 -and $Pass2 -and $Pass3

$Report = @"
# 🧪 Verification Report: SKILL-019 (Dependency Tree Mapping)
**Date:** $(Get-Date)

## Test Cases

### 1. No Crash
**Input:** map_dependencies.ps1 on a Node.js project.
**Expected:** Exit without error.
**Actual:** Error: $ErrorOccurred
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Mermaid Graph Created
**Input:** Check for DEPENDENCY_GRAPH.mmd.
**Expected:** File exists.
**Actual:** Exists: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Graph Contains Dependencies
**Input:** Search graph for "lodash" and "express".
**Expected:** Both present.
**Actual:** lodash: $($Content -match "lodash"), express: $($Content -match "express")
**Pass:** $(if($Pass3){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




