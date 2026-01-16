# SKILL-005: Update Intent Breadcrumbs
# Maintains NEXT.md and STATE.json context files using templates

param(
    [string]$Status = "active",
    [string]$Objective,
    [string[]]$NextSteps,
    [string[]]$Blockers
)

$ErrorActionPreference = "Stop"

# 1. STATE.json (Machine Readable)
$statePath = "STATE.json"
$state = @{
    last_updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
}

if (Test-Path $statePath) {
    try {
        $existing = Get-Content $statePath | ConvertFrom-Json
        foreach ($prop in $existing.PSObject.Properties) {
            $state[$prop.Name] = $prop.Value
        }
    }
    catch {
        Write-Warning "Could not parse existing STATE.json. Starting fresh."
    }
}

if ($Status) { $state["status"] = $Status }
if ($Objective) { $state["current_objective"] = $Objective }
if ($NextSteps) { $state["next_steps"] = $NextSteps }
if ($Blockers) { $state["blockers"] = $Blockers }

if (Test-Path ".git") {
    $state["git"] = @{
        branch = (git rev-parse --abbrev-ref HEAD 2>$null)
        commit = (git log -1 --pretty=format:"%h" 2>$null)
    }
}

$state | ConvertTo-Json -Depth 5 | Out-File $statePath -Encoding utf8
Write-Host "Updated $statePath" -ForegroundColor Green

# 2. NEXT.md (Human Readable) - From Template
$nextPath = "NEXT.md"
$templatePath = Join-Path $PSScriptRoot "templates\NEXT_TEMPLATE.md"

if (-not (Test-Path $nextPath)) {
    if (Test-Path $templatePath) {
        $content = Get-Content $templatePath -Raw
        $content = $content -replace "{{WORKSPACE_NAME}}", (Split-Path (Get-Location) -Leaf)
        $content = $content -replace "{{TIMESTAMP}}", (Get-Date -Format "yyyy-MM-dd HH:mm")
        $content = $content -replace "{{STATUS}}", $Status
        $content = $content -replace "{{OBJECTIVE}}", $(if ($Objective) { $Objective } else { "[Enter Objective]" })
        
        $stepsList = if ($NextSteps) { $NextSteps | ForEach-Object { "1. [ ] $_" } | Out-String } else { "1. [ ] " }
        $content = $content -replace "{{NEXT_STEPS_LIST}}", $stepsList
        
        $blockersList = if ($Blockers) { $Blockers | ForEach-Object { "- $_" } | Out-String } else { "- None" }
        $content = $content -replace "{{BLOCKERS_LIST}}", $blockersList
        
        $content | Out-File $nextPath -Encoding utf8
        Write-Host "Created $nextPath from template" -ForegroundColor Green
    }
    else {
        Write-Warning "Template not found at $templatePath. Skipping NEXT.md creation."
    }
}
else {
    Write-Host "NEXT.md exists. Please update it manually." -ForegroundColor Yellow
}
