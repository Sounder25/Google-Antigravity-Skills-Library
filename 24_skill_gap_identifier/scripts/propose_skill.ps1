<#
.SYNOPSIS
    Scaffolds a new skill based on a gap analysis.
.DESCRIPTION
    finds the next available ID, creates the folder, and writes a template.
.PARAMETER Name
    The short name of the skill.
.PARAMETER Trigger
    Trigger phrase or condition.
.PARAMETER Description
    Full description.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Trigger,

    [Parameter(Mandatory = $true)]
    [string]$Description
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SkillsRoot = Join-Path $PSScriptRoot "..\.."

# 1. Find Next ID
$Existing = Get-ChildItem -Path $SkillsRoot -Directory
$MaxId = 0
foreach ($Item in $Existing) {
    if ($Item.Name -match "^(\d+)_") {
        $Id = [int]$Matches[1]
        if ($Id -gt $MaxId) { $MaxId = $Id }
    }
}
$NextId = $MaxId + 1
$IdStr = "{0:D2}" -f $NextId

# 2. Create Directory
$SafeName = $Name.ToLower() -replace ("[^a-z0-9]", "_") -replace ("_{2,}", "_")
$NewDirName = "${IdStr}_${SafeName}"
$NewDirPath = Join-Path $SkillsRoot $NewDirName

if (Test-Path $NewDirPath) {
    Write-Error "Skill directory already exists: $NewDirPath"
    exit 1
}

New-Item -ItemType Directory -Path $NewDirPath -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $NewDirPath "scripts") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $NewDirPath "templates") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $NewDirPath "examples") -Force | Out-Null

# 3. Create Template
$TemplateContent = @"
---
name: $SafeName
description: $Description
version: 1.0.0
author: Antigravity Skills Library
created: $(Get-Date -Format "yyyy-MM-dd")
leverage_score: 1/5 (Draft)
---

# SKILL-${IdStr}: $Name

## Overview
$Description

## Trigger Phrases
- \`$Trigger\`

## Preconditions
1. TBD

## Implementation
See \`scripts/main.ps1\`.
"@

Set-Content -Path (Join-Path $NewDirPath "SKILL.md") -Value $TemplateContent

# 4. Report
Write-Output @{
    status  = "CREATED"
    path    = $NewDirPath
    id      = "SKILL-$IdStr"
    message = "Skill scaffolded successfully."
} | ConvertTo-Json
