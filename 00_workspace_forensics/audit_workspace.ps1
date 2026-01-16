# SKILL-000: Workspace Forensics Audit
# Generates comprehensive workspace profile with forensics completeness tracking

param(
    [string]$WorkspacePath = (Get-Location).Path,
    [ValidateSet("json", "md", "both")]
    [string]$OutputFormat = "json",
    [string]$OutputDir = ".forensics",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Helper function for verbose logging
function Write-VerboseLog {
    param([string]$Message)
    if ($Verbose) {
        Write-Host "[AUDIT] $Message" -ForegroundColor Cyan
    }
}

# Validate workspace path
Write-VerboseLog "Validating workspace path: $WorkspacePath"
if (-not (Test-Path $WorkspacePath)) {
    Write-Error "Workspace path not found: $WorkspacePath"
    Write-Host "Please provide a valid workspace path using -WorkspacePath parameter"
    exit 1
}

$WorkspacePath = Resolve-Path $WorkspacePath
Write-VerboseLog "Resolved path: $WorkspacePath"

# Create output directory
if ([System.IO.Path]::IsPathRooted($OutputDir)) {
    $outputPath = $OutputDir
}
else {
    $outputPath = Join-Path $WorkspacePath $OutputDir
}

if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    Write-VerboseLog "Created output directory: $outputPath"
}

# Initialize profile
$profile = @{
    workspace_name         = Split-Path $WorkspacePath -Leaf
    absolute_path          = $WorkspacePath
    audit_timestamp        = Get-Date -Format "o"
    forensics_completeness = "unknown"
    evidence_type          = "repo_artifact"
    collection_errors      = @()
    repo_type              = "unknown"
    git_signals            = @{}
    languages              = @()
    build_signals          = @{}
    intent_breadcrumbs     = @{}
    markers                = @{}
}

# Detect repo type
Write-VerboseLog "Detecting repository type..."
$gitPath = Join-Path $WorkspacePath ".git"
if (Test-Path $gitPath) {
    $profile.repo_type = "git"
    Write-VerboseLog "Detected: Git repository"
}
else {
    $profile.repo_type = "non-git"
    Write-VerboseLog "Detected: Non-git directory"
}

# Collect git signals (if git repo)
if ($profile.repo_type -eq "git") {
    Write-VerboseLog "Collecting git signals..."
    Push-Location $WorkspacePath
    
    try {
        # Current branch
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) {
            $profile.git_signals.current_branch = $branch
            Write-VerboseLog "  Branch: $branch"
        }
        
        # Status
        $statusOutput = git status --porcelain 2>$null
        $profile.git_signals.status_clean = ($statusOutput.Length -eq 0)
        $profile.git_signals.changed_files_count = ($statusOutput -split "`n").Count
        Write-VerboseLog "  Status: $(if ($profile.git_signals.status_clean) { 'Clean' } else { 'Dirty (' + $profile.git_signals.changed_files_count + ' files)' })"
        
        # Last commit
        $lastCommitRaw = git log -1 --pretty=format:"%h|%ai|%s" 2>$null
        if ($lastCommitRaw) {
            $parts = $lastCommitRaw -split '\|', 3
            $profile.git_signals.last_commit = @{
                hash    = $parts[0]
                date    = $parts[1]
                message = $parts[2]
            }
            Write-VerboseLog "  Last commit: $($parts[0]) - $($parts[2])"
        }
        
        # Commits in last 30 days
        $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
        $recentCommits = git log --since="$thirtyDaysAgo" --oneline 2>$null
        $profile.git_signals.commits_last_30_days = ($recentCommits -split "`n").Count
        Write-VerboseLog "  Recent commits (30 days): $($profile.git_signals.commits_last_30_days)"
        
    }
    catch {
        $profile.collection_errors += "Git command failed: $_"
        Write-VerboseLog "  Warning: Git command failed"
    }
    
    Pop-Location
}

# Detect languages/frameworks
Write-VerboseLog "Detecting languages and frameworks..."

$languageIndicators = @{
    "*.csproj"          = "C#/.NET"
    "*.sln"             = "C#/.NET"
    "package.json"      = "JavaScript/Node.js"
    "requirements.txt"  = "Python"
    "pyproject.toml"    = "Python"
    "Cargo.toml"        = "Rust"
    "go.mod"            = "Go"
    "foundry.toml"      = "Solidity/Foundry"
    "hardhat.config.js" = "Solidity/Hardhat"
}

$detectedLanguages = @{}
foreach ($pattern in $languageIndicators.Keys) {
    $files = Get-ChildItem -Path $WorkspacePath -Filter $pattern -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($files) {
        $lang = $languageIndicators[$pattern]
        $detectedLanguages[$lang] = $true
        Write-VerboseLog "  Detected: $lang"
    }
}
$profile.languages = @($detectedLanguages.Keys)

# Detect build signals
Write-VerboseLog "Detecting build configuration..."

# .NET
$slnFiles = Get-ChildItem -Path $WorkspacePath -Filter "*.sln" -File -ErrorAction SilentlyContinue
if ($slnFiles) {
    $profile.build_signals.solution_file = $slnFiles[0].Name
    $profile.build_signals.build_command = "dotnet build"
    $profile.build_signals.test_command = "dotnet test"
    
    $csprojFiles = Get-ChildItem -Path $WorkspacePath -Filter "*.csproj" -File -Recurse -ErrorAction SilentlyContinue
    $profile.build_signals.project_files = @($csprojFiles | ForEach-Object { $_.Name })
    
    Write-VerboseLog "  Build system: .NET ($($slnFiles[0].Name))"
}

# Node.js
$packageJson = Join-Path $WorkspacePath "package.json"
if (Test-Path $packageJson) {
    $profile.build_signals.package_file = "package.json"
    $profile.build_signals.build_command = "npm run build"
    $profile.build_signals.test_command = "npm test"
    Write-VerboseLog "  Build system: Node.js"
}

# Python
$pyprojectToml = Join-Path $WorkspacePath "pyproject.toml"
if (Test-Path $pyprojectToml) {
    $profile.build_signals.project_file = "pyproject.toml"
    $profile.build_signals.build_command = "pip install -e ."
    $profile.build_signals.test_command = "pytest"
    Write-VerboseLog "  Build system: Python"
}

# Foundry
$foundryToml = Join-Path $WorkspacePath "foundry.toml"
if (Test-Path $foundryToml) {
    $profile.build_signals.config_file = "foundry.toml"
    $profile.build_signals.build_command = "forge build"
    $profile.build_signals.test_command = "forge test"
    Write-VerboseLog "  Build system: Foundry"
}

# Makefile
$makefile = Join-Path $WorkspacePath "Makefile"
if (Test-Path $makefile) {
    $profile.build_signals.build_file = "Makefile"
    $profile.build_signals.build_command = "make"
    $profile.build_signals.test_command = "make test"
    Write-VerboseLog "  Build system: Make"
}

# Scan for intent breadcrumbs
Write-VerboseLog "Scanning for intent breadcrumbs..."

$breadcrumbFiles = @("NEXT.md", "PLAN.md", "STATE.json", "README.md")
foreach ($file in $breadcrumbFiles) {
    $filePath = Join-Path $WorkspacePath $file
    if (Test-Path $filePath) {
        $fileInfo = Get-Item $filePath
        $profile.intent_breadcrumbs[$file] = @{
            exists        = $true
            last_modified = $fileInfo.LastWriteTime.ToString("yyyy-MM-dd")
            size_bytes    = $fileInfo.Length
        }
        Write-VerboseLog "  Found: $file"
    }
    else {
        $profile.intent_breadcrumbs[$file] = @{
            exists = $false
        }
    }
}

# Scan for code markers
Write-VerboseLog "Scanning for code markers..."

$markerPatterns = @("TODO", "FIXME", "HACK", "WIP", "BLOCKED", "NOTE")
foreach ($pattern in $markerPatterns) {
    try {
        $matches = Select-String -Path "$WorkspacePath\*" -Pattern $pattern -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.Path -notmatch '\\(bin|obj|node_modules|\\.git)\\' }
        $count = ($matches | Measure-Object).Count
        if ($count -gt 0) {
            $profile.markers[$pattern] = $count
            Write-VerboseLog "  $pattern`: $count"
        }
    }
    catch {
        # Silently skip marker scanning errors
    }
}

# Determine forensics completeness
Write-VerboseLog "Determining forensics completeness..."

$coreSignalsPresent = $true
if ($profile.repo_type -eq "git") {
    if (-not $profile.git_signals.current_branch) {
        $profile.collection_errors += "Missing git branch"
        $coreSignalsPresent = $false
    }
    if ($null -eq $profile.git_signals.status_clean) {
        $profile.collection_errors += "Missing git status"
        $coreSignalsPresent = $false
    }
    if (-not $profile.git_signals.last_commit) {
        $profile.collection_errors += "Missing git commit history"
        $coreSignalsPresent = $false
    }
}

$profile.forensics_completeness = if ($coreSignalsPresent) { "full" } else { "partial" }
Write-VerboseLog "Completeness: $($profile.forensics_completeness)"

# Generate JSON output
if ($OutputFormat -eq "json" -or $OutputFormat -eq "both") {
    $jsonPath = Join-Path $outputPath "WORKSPACE_PROFILE.json"
    $profile | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8
    Write-Host "✅ Generated: $jsonPath" -ForegroundColor Green
}

# Generate Markdown output
if ($OutputFormat -eq "md" -or $OutputFormat -eq "both") {
    $mdPath = Join-Path $outputPath "FORENSICS_SUMMARY.md"
    
    $markdown = @"
# Workspace Forensics Summary

**Workspace:** $($profile.workspace_name)  
**Path:** $($profile.absolute_path)  
**Audit Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Completeness:** $(if ($profile.forensics_completeness -eq 'full') { '✅ Full' } else { '⚠️ Partial' })

## Git Status

$(if ($profile.repo_type -eq 'git') {
"- **Branch:** $($profile.git_signals.current_branch)
- **Status:** $(if ($profile.git_signals.status_clean) { 'Clean' } else { "Dirty ($($profile.git_signals.changed_files_count) changed files)" })
- **Last Commit:** $($profile.git_signals.last_commit.hash) - `"$($profile.git_signals.last_commit.message)`" ($($profile.git_signals.last_commit.date))
- **Recent Activity:** $($profile.git_signals.commits_last_30_days) commits in last 30 days"
} else {
"- **Type:** Non-git directory"
})

## Technology Stack

$(if ($profile.languages.Count -gt 0) {
    $profile.languages | ForEach-Object { "- $_" } | Out-String
} else {
    "- No languages detected"
})

## Build Configuration

$(if ($profile.build_signals.Count -gt 0) {
    if ($profile.build_signals.solution_file) { "- **Solution:** $($profile.build_signals.solution_file)" }
    if ($profile.build_signals.package_file) { "- **Package:** $($profile.build_signals.package_file)" }
    if ($profile.build_signals.build_command) { "- **Build:** ``$($profile.build_signals.build_command)``" }
    if ($profile.build_signals.test_command) { "- **Test:** ``$($profile.build_signals.test_command)``" }
} else {
    "- No build configuration detected"
})

## Intent Breadcrumbs

$(foreach ($file in @("NEXT.md", "PLAN.md", "STATE.json", "README.md")) {
    $exists = $profile.intent_breadcrumbs[$file].exists
    "- $(if ($exists) { '✅' } else { '❌' }) $file"
})

## Code Markers

$(if ($profile.markers.Count -gt 0) {
    $profile.markers.GetEnumerator() | ForEach-Object { "- $($_.Key): $($_.Value)" } | Out-String
} else {
    "- No markers found"
})

## Recommendations

$(
$recommendations = @()
if (-not $profile.intent_breadcrumbs["PLAN.md"].exists) {
    $recommendations += "1. Add PLAN.md for long-term objectives"
}
if (-not $profile.intent_breadcrumbs["STATE.json"].exists) {
    $recommendations += "$(if ($recommendations.Count -eq 0) { '1' } else { '2' }). Add STATE.json for machine-readable state"
}
if ($profile.markers.FIXME -gt 0) {
    $recommendations += "$(if ($recommendations.Count -eq 0) { '1' } elseif ($recommendations.Count -eq 1) { '2' } else { '3' }). Address $($profile.markers.FIXME) FIXME markers"
}
if ($profile.markers.TODO -gt 5) {
    $recommendations += "$(if ($recommendations.Count -eq 0) { '1' } elseif ($recommendations.Count -eq 1) { '2' } elseif ($recommendations.Count -eq 2) { '3' } else { '4' }). Review $($profile.markers.TODO) TODO items"
}
if ($recommendations.Count -eq 0) {
    "- No recommendations at this time"
} else {
    $recommendations | Out-String
}
)

## Collection Errors

$(if ($profile.collection_errors.Count -gt 0) {
    $profile.collection_errors | ForEach-Object { "- $_" } | Out-String
} else {
    "- None"
})

---

*Generated by SKILL-000: Workspace Forensics Audit*
"@
    
    $markdown | Out-File -FilePath $mdPath -Encoding utf8
    Write-Host "✅ Generated: $mdPath" -ForegroundColor Green
}

Write-Host "`n✅ Workspace audit complete!" -ForegroundColor Green
Write-Host "   Completeness: $($profile.forensics_completeness)" -ForegroundColor $(if ($profile.forensics_completeness -eq 'full') { 'Green' } else { 'Yellow' })
Write-Host "   Languages: $($profile.languages -join ', ')" -ForegroundColor Cyan
