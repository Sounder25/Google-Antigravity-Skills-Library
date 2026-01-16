# SKILL-014: Detect Duplicate Files
# Scans workspace for content-identical files

param(
    [string]$WorkspacePath = (Get-Location),
    [string]$OutputDir = ".forensics",
    [int]$MinSizeBytes = 10,
    [string[]]$Exclude = @("node_modules", ".git", "bin", "obj", ".vs", ".idea", "dist", "build")
)

$ErrorActionPreference = "Stop"
$WorkspacePath = Resolve-Path $WorkspacePath

# Setup output
$outputPath = Join-Path $WorkspacePath $OutputDir
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath -Force | Out-Null }

Write-Host "Scanning for duplicates in: $WorkspacePath" -ForegroundColor Cyan

# Gather files
$files = Get-ChildItem -Path $WorkspacePath -Recurse -File | 
Where-Object { 
    $path = $_.FullName
    $paramsExclude = $Exclude
    $shouldExclude = $false
    foreach ($ex in $paramsExclude) {
        if ($path -match "\\$ex\\") { $shouldExclude = $true; break }
    }
    (-not $shouldExclude) -and ($_.Length -ge $MinSizeBytes)
}

Write-Host "Hashing $($files.Count) files..." -ForegroundColor Cyan

$hashes = @{}

foreach ($file in $files) {
    try {
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        
        if (-not $hashes.ContainsKey($hash)) {
            $hashes[$hash] = @()
        }
        $hashes[$hash] += $file
    }
    catch {
        Write-Warning "Could not hash $($file.FullName)"
    }
}

# Filter for duplicates
$duplicateGroups = $hashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$totalGroups = ($duplicateGroups | Measure-Object).Count

$report = "# Duplicate File Report`n`n"
$report += "Generated: $(Get-Date)`n"
$report += "Scope: $WorkspacePath`n"
$report += "Total Groups: $totalGroups`n`n"

$wastedBytes = 0

foreach ($group in $duplicateGroups) {
    $firstFile = $group.Value[0]
    $size = $firstFile.Length
    $count = $group.Value.Count
    $groupWasted = $size * ($count - 1)
    $wastedBytes += $groupWasted
    
    $report += "## Hash: $($group.Key.Substring(0, 8))...`n"
    $report += "- Size: $size bytes`n"
    $report += "- Count: $count`n"
    
    foreach ($f in $group.Value) {
        $relPath = $f.FullName.Replace($WorkspacePath, "").TrimStart("\")
        $report += "  - `$relPath`n"
    }
    $report += "`n"
}

$report += "---`n**Total Wasted Space:** $([math]::Round($wastedBytes / 1KB, 2)) KB`n"

$reportPath = Join-Path $outputPath "DUPLICATE_REPORT.md"
$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "✅ Found $totalGroups duplicate groups." -ForegroundColor Green
Write-Host "   Report: $reportPath" -ForegroundColor Cyan
