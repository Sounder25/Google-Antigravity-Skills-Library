# SKILL-004: Clean Build Artifacts
# Removes bin/obj and other artifacts

param(
    [string[]]$Targets = @("bin", "obj", "node_modules", "__pycache__", ".venv"),
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-FolderSize {
    param([string]$Path)
    $measure = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    return $measure.Sum
}

$totalSize = 0
$pathsToRemove = @()

Write-Host "Scanning for artifacts..." -ForegroundColor Cyan

# Find directories matching targets
# We use Get-ChildItem -Recurse but exclude hidden folders like .git
$found = Get-ChildItem -Recurse -Directory -ErrorAction SilentlyContinue | 
Where-Object { 
    $n = $_.Name; 
    $Targets -contains $n -and $_.FullName -notmatch "\\\.git\\" 
}

foreach ($item in $found) {
    $pathsToRemove += $item
    if ($DryRun) {
        Write-Host "[DRY] Found: $($item.FullName)"
    }
}

if ($pathsToRemove.Count -eq 0) {
    Write-Host "No artifacts found." -ForegroundColor Green
    exit 0
}

if ($DryRun) {
    Write-Host "Found $($pathsToRemove.Count) folders to clean." -ForegroundColor Yellow
    exit 0
}

if (-not $Force) {
    $confirm = Read-Host "Found $($pathsToRemove.Count) folders. Delete? (y/n)"
    if ($confirm -ne "y") { exit 0 }
}

foreach ($item in $pathsToRemove) {
    try {
        if (Test-Path $item.FullName) {
            Write-Host "Deleting: $($item.FullName)" -ForegroundColor Gray
            Remove-Item $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Warning "Failed to delete $($item.FullName): $_"
    }
}

Write-Host "Cleanup complete." -ForegroundColor Green
