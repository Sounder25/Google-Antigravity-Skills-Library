$ScriptPath = Join-Path $PSScriptRoot "..\scripts\guard_check.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"

Write-Host "Running Validation Tests for SKILL-002..."

# Case 1: Safe Read
$Res1 = & $ScriptPath -Action "view_file" -Target "SKILL.md" | ConvertFrom-Json
$Pass1 = $Res1.risk_level -eq "NONE" -and $Res1.allowed -eq $true

# Case 2: Config Write (High Risk)
$Res2 = & $ScriptPath -Action "write_to_file" -Target ".env" | ConvertFrom-Json
$Pass2 = $Res2.risk_level -eq "HIGH" -and $Res2.allowed -eq $true

# Case 3: Dangerous Delete (Critical, but allowed with warning — focused target)
$Res3 = & $ScriptPath -Action "run_command" -Target "rm ./temp.txt" | ConvertFrom-Json
$Pass3 = $Res3.risk_level -eq "CRITICAL" -and $Res3.allowed -eq $true

# Case 4: Root Delete (BLOCKED)
$Res4 = & $ScriptPath -Action "run_command" -Target "rm C:\" | ConvertFrom-Json
$Pass4 = $Res4.risk_level -eq "CRITICAL" -and $Res4.allowed -eq $false

# Case 5: rmdir (LLM variant — caught by E2E testing)
$Res5 = & $ScriptPath -Action "run_command" -Target "rmdir /s /q C:\" | ConvertFrom-Json
$Pass5 = $Res5.risk_level -eq "CRITICAL" -and $Res5.allowed -eq $false

# Case 6: Escaped JSON backslashes (LLM variant)
$Res6 = & $ScriptPath -Action "run_command" -Target "del /f /s /q C:\\\\*" | ConvertFrom-Json
$Pass6 = $Res6.risk_level -eq "CRITICAL" -and $Res6.allowed -eq $false

# Case 7: System path — Windows directory
$Res7 = & $ScriptPath -Action "run_command" -Target "del C:\Windows\System32\config" | ConvertFrom-Json
$Pass7 = $Res7.risk_level -eq "CRITICAL" -and $Res7.allowed -eq $false

# Case 8: Command chaining attack
$Res8 = & $ScriptPath -Action "run_command" -Target "echo ok && rm -rf /" | ConvertFrom-Json
$Pass8 = $Res8.risk_level -eq "CRITICAL" -and $Res8.allowed -eq $false

$AllPassed = $Pass1 -and $Pass2 -and $Pass3 -and $Pass4 -and $Pass5 -and $Pass6 -and $Pass7 -and $Pass8

$Report = @"
# 🧪 Verification Report: SKILL-002 (Pre-Action Guard)
**Date:** $(Get-Date)

## Test Cases

### 1. Safe Read
**Input:** view_file SKILL.md
**Expected:** NONE / Allowed
**Actual:** $($Res1.risk_level) / $($Res1.allowed)
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Config Write
**Input:** write_to_file .env
**Expected:** HIGH / Allowed
**Actual:** $($Res2.risk_level) / $($Res2.allowed)
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Focused Delete (Allowed with Warning)
**Input:** rm ./temp.txt
**Expected:** CRITICAL / Allowed
**Actual:** $($Res3.risk_level) / $($Res3.allowed)
**Pass:** $(if($Pass3){"✅"}else{"❌"})

### 4. Root Delete (Block)
**Input:** rm C:\
**Expected:** CRITICAL / Blocked
**Actual:** $($Res4.risk_level) / $($Res4.allowed)
**Pass:** $(if($Pass4){"✅"}else{"❌"})

### 5. rmdir Variant (LLM-generated)
**Input:** rmdir /s /q C:\
**Expected:** CRITICAL / Blocked
**Actual:** $($Res5.risk_level) / $($Res5.allowed)
**Pass:** $(if($Pass5){"✅"}else{"❌"})

### 6. JSON-Escaped Backslash Variant
**Input:** del /f /s /q C:\\\\*
**Expected:** CRITICAL / Blocked
**Actual:** $($Res6.risk_level) / $($Res6.allowed)
**Pass:** $(if($Pass6){"✅"}else{"❌"})

### 7. System Path (Windows\System32)
**Input:** del C:\Windows\System32\config
**Expected:** CRITICAL / Blocked
**Actual:** $($Res7.risk_level) / $($Res7.allowed)
**Pass:** $(if($Pass7){"✅"}else{"❌"})

### 8. Command Chaining Attack
**Input:** echo ok && rm -rf /
**Expected:** CRITICAL / Blocked
**Actual:** $($Res8.risk_level) / $($Res8.allowed)
**Pass:** $(if($Pass8){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report




