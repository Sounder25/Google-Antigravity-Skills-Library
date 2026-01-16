$ScriptPath = Join-Path $PSScriptRoot "..\scripts\prepare_review.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestFile = Join-Path $PSScriptRoot "code_stub.cs"

# Create a dummy file
Set-Content -Path $TestFile -Value @"
public void Process(string input) {
    if (input == null) return;
    var sql = "SELECT * FROM users WHERE name = '" + input + "'";
    Execute(sql); // SQL Injection!
}
"@

Write-Host "Running Validation Tests for SKILL-019..."

# Test 1: Generate Security Prompt
$Out1 = & $ScriptPath -FilePath $TestFile -Mode "Security" 
$OutString1 = $Out1 -join "`n"
$Pass1 = $OutString1 -match "Injection"

# Test 2: Generate Perf Prompt
$Out2 = & $ScriptPath -FilePath $TestFile -Mode "Performance"
$OutString2 = $Out2 -join "`n"
$Pass2 = $OutString2 -match "Blocking I/O"

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-019 (Adversarial Reviewer)
**Date:** $(Get-Date)

## Test Cases

### 1. Security Mode
**Input:** code_stub.cs (Security)
**Expected:** Prompt containing 'Injection/Sanitization'
**Actual:** $(if($Pass1){"Found Keywords"}else{"Missing Keywords. Output was: " + $Out1.Substring(0, [Math]::Min($Out1.Length, 100)) + "..."})
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Performance Mode
**Input:** code_stub.cs (Performance)
**Expected:** Prompt containing 'Blocking I/O'
**Actual:** $(if($Pass2){"Found Keywords"}else{"Missing Keywords"})
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report
