# SKILL-007: Deterministic Planner
# Generates a structured PLAN.json artifact from template

param(
    [Parameter(Mandatory = $true)]
    [string]$Objective,
    
    [string]$OutputPath = "PLAN.json",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$templatePath = Join-Path $PSScriptRoot "templates\PLAN_TEMPLATE.json"

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found at $templatePath"
    exit 1
}

if ((Test-Path $OutputPath) -and -not $Force) {
    Write-Warning "Plan file '$OutputPath' already exists."
    $ans = Read-Host "Overwrite? (y/n)"
    if ($ans -ne "y") { exit 0 }
}

# Read and Hydrate Template
$jsonContent = Get-Content $templatePath -Raw
$jsonContent = $jsonContent -replace "{{OBJECTIVE}}", $Objective
$jsonContent = $jsonContent -replace "{{CREATED_AT}}", (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
$jsonContent = $jsonContent -replace "{{WORKSPACE_PATH}}", ((Get-Location).Path -replace "\\", "\\")

# Parse to verify JSON integrity
try {
    $planObj = $jsonContent | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse template JSON: $_"
    exit 1
}

# Write Output
$jsonContent | Out-File $OutputPath -Encoding utf8

Write-Host "✅ Created deterministic plan at: $OutputPath" -ForegroundColor Green
Write-Host "Action Required: Edit the 'execution_model' and 'safety' sections." -ForegroundColor Yellow
