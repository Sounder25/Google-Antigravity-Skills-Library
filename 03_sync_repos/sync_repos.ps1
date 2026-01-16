# SKILL-003: Sync Multi-Repo State
# Detects drift between git repositories

param(
    [string[]]$Repos,
    [string]$Reference,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

if ($Apply) {
    Write-Warning "Apply mode is NOT yet implemented for safety reasons. Running report only."
}

# Auto-detect duplicates if no repos provided
if (-not $Repos) {
    # This would need access to the index or heuristics
    # For now, require manual input or default to current dir + submodules
    Write-Warning "No repos specified. Scanning for submodules..."
    $submodules = git submodule status | ForEach-Object { $_.Split(' ')[2] }
    if ($submodules) {
        $Repos = @(".") + $submodules
    }
    else {
        Write-Error "No repos specified and no submodules found."
        exit 1
    }
}

$results = @()

foreach ($path in $Repos) {
    if (-not (Test-Path $path)) {
        Write-Warning "Repo not found: $path"
        continue
    }
    
    Push-Location $path
    try {
        $name = Split-Path (Resolve-Path .) -Leaf
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        $hash = git rev-parse --short HEAD 2>$null
        $status = git status --porcelain 2>$null
        $clean = $status.Length -eq 0
        $remote = git remote get-url origin 2>$null
        
        $results += [PSCustomObject]@{
            Name   = $name
            Path   = (Resolve-Path .)
            Branch = $branch
            Hash   = $hash
            Clean  = $clean
            Remote = $remote
        }
    }
    catch {
        Write-Warning "Failed to read git info for $path"
    }
    finally {
        Pop-Location
    }
}

# Display Report
Write-Host "`n=== Multi-Repo Sync Report ===" -ForegroundColor Cyan
$results | Format-Table Name, Branch, Hash, Clean, Path -AutoSize

# Drift Detection
if ($results.Count -gt 1) {
    $ref = $results[0]
    foreach ($r in $results) {
        if ($r.Hash -ne $ref.Hash) {
            Write-Host "DRIFT DETECTED: $($r.Name) ($($r.Hash)) != $($ref.Name) ($($ref.Hash))" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "Only one repo scanned. Nothing to compare." -ForegroundColor Gray
}

# Generate Markdown
$mdLines = @(
    "# Sync Report",
    "",
    "| Name | Branch | Hash | Clean | Path |",
    "|------|--------|------|-------|------|"
)
foreach ($r in $results) {
    $mdLines += "| $($r.Name) | $($r.Branch) | $($r.Hash) | $(if($r.Clean){'✅'}else{'❌'}) | $($r.Path) |"
}

$mdLines | Out-File "REPO_SYNC_REPORT.md" -Encoding utf8
Write-Host "`nReport saved to REPO_SYNC_REPORT.md" -ForegroundColor Green
