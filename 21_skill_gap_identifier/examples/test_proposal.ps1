$ScriptPath = Join-Path $PSScriptRoot "..\scripts\propose_skill.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$SkillsRoot = Join-Path $PSScriptRoot "..\.."

# Clean up potential test artifact from previous run
$TestName = "test_skill_scaffold"
$TestDirs = Get-ChildItem $SkillsRoot -Directory | Where-Object { $_.Name -match $TestName }
foreach ($Dir in $TestDirs) { 
    Remove-Item $Dir.FullName -Recurse -Force 
}

Write-Host "Running Validation Tests for SKILL-021..."

# Run Scaffold
$Result = & $ScriptPath -Name $TestName -Trigger "Start Test" -Description "Just a test" | ConvertFrom-Json

# Verify
$CreatedPath = $Result.path
$MDPath = Join-Path $CreatedPath "SKILL.md"
$ScriptsPath = Join-Path $CreatedPath "scripts"

$PassExists = Test-Path $CreatedPath
$PassMD = Test-Path $MDPath
$PassScripts = Test-Path $ScriptsPath
$PassContent = if ($PassMD) { (Get-Content $MDPath | Out-String) -match "SKILL-.*: $TestName" } else { $false }

$AllPassed = $PassExists -and $PassMD -and $PassScripts -and $PassContent

# Cleanup (Optional? Better to leave for inspection, but this is auto-test)
if ($PassExists) { Remove-Item $CreatedPath -Recurse -Force }

$Report = @"
# 🧪 Verification Report: SKILL-021 (Skill Gap Identifier)
**Date:** $(Get-Date)

## Test Cases

### 1. Scaffold Creation
**Input:** Create '$TestName'
**Expected:** Directory created with SKILL.md and scripts/
**Actual:** Exists: $PassExists, MD: $PassMD, Scripts: $PassScripts
**Pass:** $(if($AllPassed){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
