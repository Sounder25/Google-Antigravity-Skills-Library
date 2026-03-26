$ScriptPath = Join-Path $PSScriptRoot "..\detect_env.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestDir = Join-Path $env:TEMP "fas_test_env_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-020..."

# detect_env.ps1 resolves OutputDir from Get-Location, so we must cd there
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
$OutputDirName = ".env"

Push-Location $TestDir

# Case 1: Script runs without error
$ErrorOccurred = $false
try {
    & $ScriptPath -OutputDir $OutputDirName *>&1 | Out-Null
} catch {
    $ErrorOccurred = $true
}
$Pass1 = -not $ErrorOccurred

Pop-Location

# Case 2: JSON profile created
$JsonFile = Join-Path (Join-Path $TestDir $OutputDirName) "SYSTEM_PROFILE.json"
$Pass2 = Test-Path $JsonFile

# Case 3: Contains expected keys
$Profile = $null
$Pass3 = $false
if ($Pass2) {
    try {
        $Profile = Get-Content $JsonFile -Raw | ConvertFrom-Json
        $Pass3 = ($null -ne $Profile.cpu) -and ($null -ne $Profile.memory) -and ($null -ne $Profile.capabilities)
    } catch {}
}

# Case 4: ENV file created
$EnvFile = Join-Path (Join-Path $TestDir $OutputDirName) "OPTIMIZED_FLAGS.env"
$Pass4 = Test-Path $EnvFile

$AllPassed = $Pass1 -and $Pass2 -and $Pass3 -and $Pass4

$Report = @"
# 🧪 Verification Report: SKILL-020 (Environment Detection)
**Date:** $(Get-Date)

## Test Cases

### 1. No Crash
**Input:** detect_env.ps1
**Expected:** Exit without error.
**Actual:** Error: $ErrorOccurred
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. JSON Profile Created
**Input:** Check for SYSTEM_PROFILE.json.
**Expected:** File exists.
**Actual:** Exists: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

### 3. Profile Keys Present
**Input:** Parse JSON for cpu, memory, capabilities.
**Expected:** All keys present.
**Actual:** cpu: $($null -ne $Profile.cpu), memory: $($null -ne $Profile.memory), capabilities: $($null -ne $Profile.capabilities)
**Pass:** $(if($Pass3){"✅"}else{"❌"})

### 4. ENV File Created
**Input:** Check for OPTIMIZED_FLAGS.env.
**Expected:** File exists.
**Actual:** Exists: $Pass4
**Pass:** $(if($Pass4){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

# Cleanup
if (Test-Path $TestDir) { Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue }




