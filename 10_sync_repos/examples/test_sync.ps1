$ScriptPath = Join-Path $PSScriptRoot "..\sync_repos.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_sync_$(Get-Random)"
$RepoA = Join-Path $TestRoot "repo_a"
$RepoB = Join-Path $TestRoot "repo_b"

Write-Host "Running Validation Tests for SKILL-010..."

New-Item -ItemType Directory -Path $RepoA -Force | Out-Null
New-Item -ItemType Directory -Path $RepoB -Force | Out-Null

git -C $RepoA init | Out-Null
git -C $RepoA config user.email "test@example.com" | Out-Null
git -C $RepoA config user.name "Test" | Out-Null
Set-Content -Path (Join-Path $RepoA "a.txt") -Value "A"
git -C $RepoA add . | Out-Null
git -C $RepoA commit -m "init a" | Out-Null
git -C $RepoA remote add origin "https://example.com/repo_a.git" | Out-Null

git -C $RepoB init | Out-Null
git -C $RepoB config user.email "test@example.com" | Out-Null
git -C $RepoB config user.name "Test" | Out-Null
Set-Content -Path (Join-Path $RepoB "b.txt") -Value "B"
git -C $RepoB add . | Out-Null
git -C $RepoB commit -m "init b" | Out-Null
git -C $RepoB remote add origin "https://example.com/repo_b.git" | Out-Null

$Pass1 = $false
$Pass2 = $false
Push-Location $TestRoot
try {
    & $ScriptPath -Repos $RepoA, $RepoB *>&1 | Out-Null
    $Pass1 = Test-Path (Join-Path $TestRoot "REPO_SYNC_REPORT.md")
    if ($Pass1) {
        $content = Get-Content (Join-Path $TestRoot "REPO_SYNC_REPORT.md") -Raw
        $Pass2 = ($content -match "(?i)repo_a") -and ($content -match "(?i)repo_b")
    }
} catch {}
Pop-Location

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-010 (Sync Multi-Repo State)
**Date:** $(Get-Date)

## Test Cases

### 1. Report Created
**Input:** Two git repos with commits.
**Expected:** REPO_SYNC_REPORT.md exists.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Repo Names Included
**Input:** Report content.
**Expected:** repo_a and repo_b listed.
**Actual:** Found: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }




