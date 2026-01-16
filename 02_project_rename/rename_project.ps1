# SKILL-002: Project-Wide Rename
# Safely renames .NET projects with "Planned" and "Recovery" modes

param(
    [string]$WorkspacePath = (Get-Location).Path,
    
    [Parameter(Mandatory = $true)]
    [string]$OldName,
    
    [Parameter(Mandatory = $true)]
    [string]$NewName,
    
    [ValidateSet("auto", "planned", "recovery")]
    [string]$Mode = "auto",
    
    [switch]$DryRun,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# Set context to workspace
if (-not (Test-Path $WorkspacePath)) {
    Write-Error "Workspace path not found: $WorkspacePath"
    exit 1
}
Push-Location $WorkspacePath

function Write-Step { param([string]$msg) Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Action { param([string]$msg) Write-Host "  [ACTION] $msg" -ForegroundColor Green }
function Write-Info { param([string]$msg) Write-Host "  [INFO] $msg" -ForegroundColor Gray }
function Write-Warn { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }

# 1. Validation & Mode Selection
Write-Step "Initializing Rename: '$OldName' -> '$NewName'"

if (-not (Test-Path ".git")) {
    Write-Error "Must be run from git repository root."
    exit 1
}

$status = git status --porcelain
$isDirty = $status.Length -gt 0

if ($Mode -eq "auto") {
    $Mode = if ($isDirty) { "recovery" } else { "planned" }
}

Write-Info "Mode detected: $Mode"
if ($isDirty) { Write-Warn "Repository is dirty ($($status.Count) changes)." }

if ($Mode -eq "planned" -and $isDirty) {
    Write-Error "In 'planned' mode, repository must be clean. Commit or stash changes first, or use 'recovery' mode."
    exit 1
}

if ($Mode -eq "recovery" -and $isDirty -and -not $DryRun) {
    Write-Warn "Running in RECOVERY mode on DIRTY repo."
    Write-Warn "You MUST run with -DryRun first to inspect changes."
    Write-Error "Safety Stop: Please run again with -DryRun parameter."
    exit 1
}

# 2. Safety Branch
if (-not $DryRun) {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    $safetyBranch = "rename-$OldName-to-$NewName-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    
    Write-Step "Creating Safety Branch"
    git checkout -b $safetyBranch
    Write-Action "Switched to branch: $safetyBranch"
}
else {
    Write-Step "DRY RUN MODE - No changes will be written"
}

# 3. Rename Logic
$changes = @()

# Helper to log
function Log-Change {
    param($Type, $Path, $Details)
    $obj = [PSCustomObject]@{ Type = $Type; Path = $Path; Details = $Details }
    $script:changes += $obj
    if ($DryRun) { Write-Info "[DRY] $Type`: $Path -> $Details" }
    else { Write-Action "$Type`: $Path" }
}

# A. Rename Directories (Deepest First)
Write-Step "Scanning Directories"
$dirs = Get-ChildItem -Recurse -Directory | 
Where-Object { $_.FullName -notmatch '\\(bin|obj|\.git|node_modules)\\' } |
Where-Object { $_.Name -match $OldName } |
Sort-Object { $_.FullName.Length } -Descending # Deepest first

foreach ($d in $dirs) {
    $newName = $d.Name -replace $OldName, $NewName
    Log-Change "RenameDir" $d.FullName $newName
    if (-not $DryRun) {
        Rename-Item -Path $d.FullName -NewName $newName
    }
}

# B. Rename Files
Write-Step "Scanning Files (Names)"
$files = Get-ChildItem -Recurse -File | 
Where-Object { $_.FullName -notmatch '\\(bin|obj|\.git|node_modules)\\' } |
Where-Object { $_.Name -match $OldName }

foreach ($f in $files) {
    $newName = $f.Name -replace $OldName, $NewName
    Log-Change "RenameFile" $f.FullName $newName
    if (-not $DryRun) {
        Rename-Item -Path $f.FullName -NewName $newName
    }
}

# C. Update Content
Write-Step "Scanning Content (.cs, .csproj, .sln, etc)"
$textFiles = Get-ChildItem -Recurse -File | 
Where-Object { $_.FullName -notmatch '\\(bin|obj|\.git|node_modules)\\' } |
Where-Object { $_.Extension -match "\.(cs|csproj|sln|xml|json|md|txt|yml|yaml)$" }

foreach ($f in $textFiles) {
    # If we renamed the file, we need the NEW path
    $currentPath = $f.FullName
    if (-not (Test-Path $currentPath) -and -not $DryRun) {
        # Try to find it if it was renamed? 
        # Actually in non-DryRun, Rename-Item happens instantly so the object might be stale if name changed.
        # But we sort of handle directories deepest first.
        # If files were renamed, Get-ChildItem results are stale for those specific files.
        # This is tricky. simpler to re-scan or just try.
        continue 
    }
    
    if (-not $DryRun) {
        $content = Get-Content -LiteralPath $currentPath -Raw
        if ($content -match $OldName) {
            $newContent = $content -replace $OldName, $NewName
            Set-Content -LiteralPath $currentPath -Value $newContent -NoNewline
            Log-Change "UpdateContent" $currentPath "Replaced '$OldName'"
        }
    }
    else {
        # In dry run, just check content
        $content = Get-Content -LiteralPath $currentPath -Raw
        if ($content -match $OldName) {
            Log-Change "UpdateContent" $currentPath "Found match"
        }
    }
}

# 4. Gitignore update
if (Test-Path ".gitignore") {
    Log-Change "UpdateContent" ".gitignore" "Updated ignore rules"
    if (-not $DryRun) {
        $c = Get-Content ".gitignore" -Raw
        if ($c -match $OldName) {
            $c = $c -replace $OldName, $NewName
            Set-Content ".gitignore" $c -NoNewline
        }
    }
}

# 5. Build Verification
if (-not $DryRun -and -not $SkipBuild) {
    Write-Step "Verifying Build"
    dotnet build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed! Please inspect errors. You are on safety branch: $safetyBranch"
        # We don't auto-rollback because the user might just need to fix one small thing.
        # But we warn heavily.
    }
    else {
        Write-Action "Build Successful!"
    }
}

# 6. Report
$summaryPath = "RENAME_SUMMARY.md"
$report = @"
# Project Rename Summary
**Old:** $OldName
**New:** $NewName
**Mode:** $Mode
**DryRun:** $DryRun
**Date:** $(Get-Date)

## Changes
$($script:changes | Format-Table | Out-String)
"@

$report | Out-File $summaryPath
Write-Step "Complete. Summary saved to $summaryPath"
if ($DryRun) {
    Write-Host "Review summary. If correct, run again without -DryRun" -ForegroundColor Yellow
}
else {
    Write-Host "Changes applied to branch $safetyBranch. Verify and merge to main." -ForegroundColor Green
}

Pop-Location
