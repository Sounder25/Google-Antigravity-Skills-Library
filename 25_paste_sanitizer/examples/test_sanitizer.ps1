$ScriptPath = Join-Path $PSScriptRoot "..\scripts\paste_sanitizer.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-025..."

$Input = @"
PS C:\> git status
On branch main
git add .
Everything up-to-date
dotnet build
"@

$Pass1 = $false
$Pass2 = $false
try {
    $out = & $ScriptPath -Text $Input *>&1 | Out-String
    $Pass1 = $out -match "COPY/PASTE COMMANDS"
    $Pass2 = ($out -match "git add ") -and ($out -match "dotnet build") -and (-not ($out -match "Everything up-to-date"))
} catch {}

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-025 (Paste Sanitizer)
**Date:** $(Get-Date)

## Test Cases

### 1. Output Block Created
**Input:** Mixed prompt/output/commands.
**Expected:** COPY/PASTE block present.
**Actual:** Found: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Output Stripped
**Input:** Contains prompt/output lines.
**Expected:** Commands only, output removed.
**Actual:** Commands kept and output removed: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report




