# SKILL-008: Context Pruner
# Selects high-relevance files based on a focus query

param(
    [Parameter(Mandatory = $true)]
    [string]$Focus,
    
    [int]$MaxFiles = 50,
    [string[]]$Extensions = @(".cs", ".py", ".js", ".ts", ".rs", ".go", ".md", ".json", ".sol", ".ps1")
)

$ErrorActionPreference = "Stop"

Write-Host "Pruning context for focus: '$Focus'..." -ForegroundColor Cyan

# 1. Get Candidate Files (respecting ignore lists roughly)
# In a real shell, we'd use 'git ls-files' if available, otherwise recurse
$candidates = @()

if (Test-Path ".git") {
    $candidates = git ls-files | Where-Object { 
        $ext = [System.IO.Path]::GetExtension($_)
        $Extensions -contains $ext
    }
}
else {
    $candidates = Get-ChildItem -Recurse -File | 
    Where-Object { $Extensions -contains $_.Extension } | 
    ForEach-Object { $_.FullName }
}

# 2. Score Files
$scored = @()

foreach ($file in $candidates) {
    $path = $file
    $score = 0
    
    # Path match (High weight)
    if ($path -match "$Focus") { $score += 10 }
    
    # Content match (Expensive, so maybe skip for large repos? No, we need it.)
    # Optimization: Only check small files or filename matches first? 
    # Let's do a quick 'Select-String' if we have few candidates, but if we have thousands, this is slow.
    # Heuristic: Filename match is paramount.
    
    if ($score -gt 0) {
        $scored += [PSCustomObject]@{ Path = $path; Score = $score }
    }
}

# If we don't have enough filename matches, search content
if ($scored.Count -lt 5) {
    Write-Host "Few filename matches. Scanning content (this may take a moment)..." -ForegroundColor Gray
    # Use git grep if possible for speed
    if (Test-Path ".git") {
        try {
            $grepParams = "--name-only", "-i", "$Focus"
            $contentMatches = git grep $grepParams
            foreach ($m in $contentMatches) {
                # Add if not already present
                if (-not ($scored.Path -contains $m)) {
                    $scored += [PSCustomObject]@{ Path = $m; Score = 5 }
                }
            }
        }
        catch {
            Write-Warning "Git grep failed."
        }
    }
}

# 3. Sort and Limit
$final = $scored | Sort-Object Score -Descending | Select-Object -First $MaxFiles

if ($final.Count -eq 0) {
    Write-Warning "No files found strictly matching '$Focus'. Try a broader term."
    exit 0
}

# 4. Output
$outputFile = "RELEVANT_FILES.txt"
$final.Path | Out-File $outputFile -Encoding utf8

Write-Host "Found $($final.Count) relevant files." -ForegroundColor Green
$final | Format-Table -AutoSize

Write-Host "Saved list to: $outputFile" -ForegroundColor Cyan
