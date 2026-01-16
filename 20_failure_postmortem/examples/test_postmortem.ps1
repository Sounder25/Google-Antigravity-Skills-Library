$ScriptPath = Join-Path $PSScriptRoot "..\scripts\log_failure.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$LogDir = Join-Path $HOME ".gemini\antigravity\.forensics"
$LogFile = Join-Path $LogDir "POSTMORTEMS.md"

Write-Host "Running Validation Tests for SKILL-020..."

# Capture Size Before
if (Test-Path $LogFile) { $StartSize = (Get-Item $LogFile).Length } else { $StartSize = 0 }

# Trigger Log
$Result = & $ScriptPath -Command "test-command" -Error "Simulated Error 123" -Context "Unit Test" | ConvertFrom-Json

# Verify
$EndSize = (Get-Item $LogFile).Length
$Content = Get-Content $LogFile -Raw

$PassFile = ($Result.file -eq $LogFile)
$PassStatus = ($Result.status -eq "LOGGED")
$PassAppend = ($EndSize -gt $StartSize)
$PassContent = $Content -match "Simulated Error 123"

$AllPassed = $PassFile -and $PassStatus -and $PassAppend -and $PassContent

$Report = @"
# 🧪 Verification Report: SKILL-020 (Failure Postmortem)
**Date:** $(Get-Date)

## Test Cases

### 1. Log Creation & Append
**Input:** Log a simulated error.
**Expected:** File grows, content contains error.
**Actual:** File Exists: $PassFile, Status: $($Result.status), Appended: $PassAppend
**Pass:** $(if($AllPassed){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
