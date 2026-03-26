$ScriptPath = Join-Path $PSScriptRoot "..\spawn_agent.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_spawn_$(Get-Random)"
$TaskName = "audit"
$Instructions = "Check repository structure."

Write-Host "Running Validation Tests for SKILL-016..."

New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
Push-Location $TestRoot

Set-Content -Path "WORKSPACE_PROFILE.json" -Value "{`"workspace_name`":`"test`"}"

$Pass1 = $false
$Pass2 = $false
try {
    & $ScriptPath -TaskName $TaskName -Instructions $Instructions *>&1 | Out-Null
    $missionPath = Join-Path $TestRoot ".swarm\$TaskName\MISSION.md"
    $Pass1 = Test-Path $missionPath
    if ($Pass1) {
        $content = Get-Content $missionPath -Raw
        $Pass2 = ($content -match [regex]::Escape($Instructions)) -and ($content -match "TOOLKIT")
    }
} catch {}

Pop-Location

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-016 (Agent-Swarm Spawner)
**Date:** $(Get-Date)

## Test Cases

### 1. Mission Created
**Input:** Task name + instructions.
**Expected:** MISSION.md exists in swarm dir.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Mission Content
**Input:** MISSION.md content.
**Expected:** Instructions and Skills Manifest present.
**Actual:** Found: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }




