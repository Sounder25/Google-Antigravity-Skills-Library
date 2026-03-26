param(
    [switch]$IncludeE2E,
    [string]$Model = "qwen2.5:7b",
    [string]$OutputDir = $PSScriptRoot,
    [string]$OutputFile = "VERIFICATION_SUMMARY.md"
)

$ErrorActionPreference = "Stop"
$ReportPath = Join-Path $OutputDir $OutputFile

# Discover ALL test scripts across the entire repo
$TestScripts = Get-ChildItem -Path $PSScriptRoot -Recurse -Filter "test_*.ps1" | Where-Object { $_.FullName -notmatch "node_modules|\.venv|\.git|E2E_Evaluations" }

$Intro = @"
# Foundational Agent Skills — Verification & Empirical Results
**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Framework:** Foundational Agent Skills v1.0
**Repository:** https://github.com/Sounder25/Foundational-Agent-Skills
**License:** Apache 2.0

> This document provides deterministic and empirical proof that the QMS-inspired
> execution gates described in the Foundational Agent Skills white paper
> function as specified. Each skill is tested with automated assertions.
> E2E tests use a live local LLM (Ollama + Qwen 2.5 7B) to validate that
> the gates constrain non-deterministic model behavior in real time.

---

# Part 1: Deterministic Script Verification

Each test below runs the skill's PowerShell script with controlled inputs
and asserts that the outputs match the specification. No LLM is involved.

"@

Set-Content -Path $ReportPath -Value $Intro -Encoding utf8

$TotalTests = 0
$Passed = 0
$FailedSkills = @()

foreach ($Test in $TestScripts) {
    $SkillDir = (Get-Item $Test.Directory.FullName).Parent
    $SkillName = $SkillDir.Name
    Write-Host "[$SkillName] Running $($Test.Name)..." -ForegroundColor Cyan

    $ExpectedReport = Join-Path $SkillDir.FullName "VERIFICATION_REPORT.md"
    if (Test-Path $ExpectedReport) { Remove-Item $ExpectedReport -Force }

    try {
        & $Test.FullName 2>&1 | Out-Null

        if (Test-Path $ExpectedReport) {
            $TotalTests++
            $ReportContent = Get-Content $ExpectedReport -Raw

            if ($ReportContent -match "PASSED") {
                $Passed++
                Write-Host "  -> PASSED" -ForegroundColor Green
            } else {
                $FailedSkills += $SkillName
                Write-Host "  -> FAILED" -ForegroundColor Red
            }

            Add-Content -Path $ReportPath -Value $ReportContent -Encoding utf8
            Add-Content -Path $ReportPath -Value "`n---`n" -Encoding utf8
        } else {
            Write-Host "  -> ERROR: No VERIFICATION_REPORT.md generated." -ForegroundColor Red
            $FailedSkills += "$SkillName (no report)"
        }
    } catch {
        Write-Host "  -> FATAL: $_" -ForegroundColor Red
        $FailedSkills += "$SkillName (exception)"
    }
}

# E2E Section
if ($IncludeE2E) {
    Add-Content -Path $ReportPath -Value @"

# Part 2: Empirical LLM E2E Validation

Each test below prompts a **live local LLM** (Ollama + $Model) with an
adversarial scenario, intercepts the model's proposed action, and pipes it
through the corresponding QMS gate. The raw LLM output is recorded verbatim.

"@ -Encoding utf8

    $Scenarios = Get-ChildItem -Path (Join-Path $PSScriptRoot "E2E_Evaluations\Scenarios") -Filter "*.json" -ErrorAction SilentlyContinue
    $HarnessScript = Join-Path $PSScriptRoot "E2E_Evaluations\LLM_Harness.ps1"
    $HarnessLog = Join-Path $PSScriptRoot "E2E_Evaluations\harness.log"

    foreach ($Scenario in $Scenarios) {
        $ScenarioData = Get-Content $Scenario.FullName -Raw | ConvertFrom-Json
        Write-Host "[E2E] Running scenario: $($ScenarioData.name)..." -ForegroundColor Magenta

        try {
            & $HarnessScript -ScenarioPath $Scenario.FullName -Model $Model 2>&1 | Out-Null
            $ExitCode = $LASTEXITCODE

            $TotalTests++
            $LogContent = ""
            if (Test-Path $HarnessLog) {
                $LogContent = Get-Content $HarnessLog -Raw
            }

            $ScenarioResult = if ($ExitCode -eq 0) { "✅ PASSED" } else { "❌ FAILED" }
            if ($ExitCode -eq 0) { $Passed++ } else { $FailedSkills += "E2E: $($ScenarioData.name)" }

            $E2EReport = @"
## E2E Scenario: $($ScenarioData.name)
**Target Skill:** $($ScenarioData.target_skill)
**Prompt Sent to LLM:**
> $($ScenarioData.prompt)

**Harness Transcript:**
``````
$LogContent
``````

**Result:** $ScenarioResult

---

"@
            Add-Content -Path $ReportPath -Value $E2EReport -Encoding utf8
        } catch {
            Write-Host "  -> FATAL: $_" -ForegroundColor Red
            $FailedSkills += "E2E: $($ScenarioData.name) (exception)"
        }
    }
}

# Global Summary
$SuccessRate = if ($TotalTests -gt 0) { [math]::Round(($Passed / $TotalTests) * 100, 1) } else { 0 }

$Summary = @"

# Global Summary

| Metric | Value |
|--------|-------|
| **Skills Verified** | $TotalTests |
| **Tests Passed** | $Passed |
| **Tests Failed** | $($TotalTests - $Passed) |
| **Success Rate** | $SuccessRate% |
| **Failed Skills** | $(if ($FailedSkills.Count -eq 0) { "None" } else { $FailedSkills -join ", " }) |

---

*Generated by [Publish-Results.ps1](https://github.com/Sounder25/Foundational-Agent-Skills) on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

Add-Content -Path $ReportPath -Value $Summary -Encoding utf8

Write-Host "`n========================================" -ForegroundColor White
Write-Host "  VERIFICATION COMPLETE" -ForegroundColor Green
Write-Host "  Passed: $Passed / $TotalTests ($SuccessRate%)" -ForegroundColor $(if ($SuccessRate -eq 100) { "Green" } else { "Yellow" })
Write-Host "  Report: $ReportPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor White
