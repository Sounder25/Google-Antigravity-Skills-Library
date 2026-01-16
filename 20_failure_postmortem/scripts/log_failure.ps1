<#
.SYNOPSIS
    Logs a failure event to the central postmortem registry.
.DESCRIPTION
    Appends a structured failure report to POSTMORTEMS.md.
.PARAMETER Command
    The command that failed.
.PARAMETER Error
    The error message.
.PARAMETER Context
    Task context.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$Command,

    [Parameter(Mandatory = $true)]
    [string]$Error,

    [Parameter(Mandatory = $false)]
    [string]$Context = "General Execution"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$LogDir = Join-Path $HOME ".gemini\antigravity\.forensics"
$LogFile = Join-Path $LogDir "POSTMORTEMS.md"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

if (-not (Test-Path $LogFile)) {
    Set-Content -Path $LogFile -Value "# 💀 FAILURE POSTMORTEM LOG`n`n"
}

$Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Entry = @"

## [$Timestamp] Failure Analysis
**Context:** $Context
**Command:** ``$Command``
**Error:** 
> $Error

### 🕵️ Analysis (Required)
*Action Required: The Agent must analyze this failure.*
1. **Root Cause:** [?]
2. **Missed Signal:** [?]
3. **Preventive Rule:** [?]

---
"@

Add-Content -Path $LogFile -Value $Entry

Write-Output @{
    status    = "LOGGED"
    file      = $LogFile
    timestamp = $Timestamp
    message   = "Failure logged. You MUST now analyze the root cause."
} | ConvertTo-Json
