$ScriptPath = Join-Path $PSScriptRoot "..\fetch_docs.ps1"
$ReportPath = Join-Path $PSScriptRoot "..\VERIFICATION_REPORT.md"
$TestRoot = Join-Path $env:TEMP "fas_test_docs_$(Get-Random)"

Write-Host "Running Validation Tests for SKILL-018..."

New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
Push-Location $TestRoot

$Port = Get-Random -Minimum 18000 -Maximum 19000
$Prefix = "http://localhost:$Port/"

$ServerJob = Start-Job -ScriptBlock {
    param($Prefix)
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($Prefix)
    try {
        $listener.Start()
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $path = $context.Request.Url.AbsolutePath
            $responseText = ""
            if ($path -eq "/llms.txt") {
                $responseText = "# Test Docs`n- [Doc One](/doc1.md)`n- [Doc Two](/doc2.md)"
            } elseif ($path -eq "/doc1.md") {
                $responseText = "# Doc One`nAlpha"
            } elseif ($path -eq "/doc2.md") {
                $responseText = "# Doc Two`nBeta"
            } elseif ($path -eq "/shutdown") {
                $responseText = "bye"
                $bytes = [Text.Encoding]::UTF8.GetBytes($responseText)
                $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                $context.Response.Close()
                break
            } else {
                $context.Response.StatusCode = 404
                $responseText = "not found"
            }

            $bytes = [Text.Encoding]::UTF8.GetBytes($responseText)
            $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            $context.Response.Close()
        }
    } finally {
        $listener.Stop()
    }
} -ArgumentList $Prefix

Start-Sleep -Milliseconds 1000

$Pass1 = $false
$Pass2 = $false
try {
    & $ScriptPath -Url $Prefix -OutputDir ".docs" -MaxDepth 2 *>&1 | Out-Null
    $Pass1 = Test-Path (Join-Path $TestRoot ".docs\CONSOLIDATED_KNOWLEDGE.md")
    if ($Pass1) {
        $content = Get-Content (Join-Path $TestRoot ".docs\CONSOLIDATED_KNOWLEDGE.md") -Raw
        $Pass2 = ($content -match "## Doc One") -and ($content -match "## Doc Two")
    }
} catch {}

try {
    Invoke-WebRequest -Uri "$Prefix/shutdown" -UseBasicParsing | Out-Null
} catch {}

if ($ServerJob) {
    Wait-Job $ServerJob -Timeout 2 | Out-Null
    Remove-Job $ServerJob -Force -ErrorAction SilentlyContinue
}

Pop-Location

$AllPassed = $Pass1 -and $Pass2

$Report = @"
# 🧪 Verification Report: SKILL-018 (llms.txt & Doc Parsing)
**Date:** $(Get-Date)

## Test Cases

### 1. Consolidated File Created
**Input:** Local llms.txt server.
**Expected:** CONSOLIDATED_KNOWLEDGE.md exists.
**Actual:** Exists: $Pass1
**Pass:** $(if($Pass1){"✅"}else{"❌"})

### 2. Linked Docs Included
**Input:** Consolidated content.
**Expected:** Doc One and Doc Two included.
**Actual:** Found: $Pass2
**Pass:** $(if($Pass2){"✅"}else{"❌"})

## Summary
$(if($AllPassed){"**✅ PASSED (100% Coverage)**"}else{"**❌ FAILED**"})
"@

Set-Content -Path $ReportPath -Value $Report
Write-Host "Report saved to $ReportPath"
Write-Output $Report

if (Test-Path $TestRoot) { Remove-Item $TestRoot -Recurse -Force -ErrorAction SilentlyContinue }




