# SKILL-008: Rapid Documentation Mastery (llms.txt)
# Fetches and consolidates documentation from llms.txt standard

param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    [string]$OutputDir = ".docs",
    [int]$MaxDepth = 10
)

$ErrorActionPreference = "Stop"

# Normalize URL
if (-not $Url.StartsWith("http")) { $Url = "https://$Url" }
$Url = $Url.TrimEnd("/")

# locations to check
$candidates = @("$Url/llms.txt", "$Url/llms-full.txt")
$foundUrl = $null
$content = $null

foreach ($c in $candidates) {
    try {
        Write-Host "Checking $c..." -ForegroundColor Cyan
        $content = Invoke-RestMethod -Uri $c -ErrorAction Stop
        $foundUrl = $c
        break
    } catch {
        # Continue
    }
}

if (-not $foundUrl) {
    Write-Error "Could not find llms.txt at provided URL. Ensure the project supports the llms.txt standard."
    exit 1
}

# Setup output
$outputPath = Join-Path (Get-Location) $OutputDir
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath -Force | Out-Null }

Write-Host "Found llms.txt! Parsing..." -ForegroundColor Green

# Parse llms.txt
# Format is loosely: - [Title](link) Optional description
# We need to extract the links.

$lines = $content -split "`n"
$links = @()

foreach ($line in $lines) {
    if ($line -match "\[(.*?)\]\((.*?)\)") {
        $title = $matches[1]
        $link = $matches[2]
        
        # Resolve relative URLs
        if (-not $link.StartsWith("http")) {
            $base = $Url
            if ($link.StartsWith("/")) {
                # relative to root (simple approximation)
                $uri = [System.Uri]$Url
                $base = "$($uri.Scheme)://$($uri.Host)"
            }
            $link = "$base/$($link.TrimStart('/'))"
        }
        
        $links += @{ Title = $title; Link = $link }
    }
}

if ($links.Count -eq 0) {
    Write-Warning "No links found in llms.txt content. Dumping raw content."
    $content | Out-File -FilePath "$outputPath\CONSOLIDATED_KNOWLEDGE.md" -Encoding utf8
    exit 0
}

# Fetch Content
$consolidated = "# Consolidated Documentation from $Url`n`n"
$consolidated += "Source: $foundUrl`nDate: $(Get-Date)`n`n"

$count = 0
foreach ($item in $links) {
    if ($count -ge $MaxDepth) { break }
    
    Write-Host "Fetching: $($item.Title) ($($item.Link))"
    try {
        $remoteContent = Invoke-RestMethod -Uri $item.Link -ErrorAction SilentlyContinue
        
        # Simple HTML to Text cleanup if necessary (though llms.txt usually points to md)
        # Assuming markdown for now as per spec
        
        $consolidated += "## $($item.Title)`n`n"
        $consolidated += "Source: $($item.Link)`n`n"
        $consolidated += "$remoteContent`n`n"
        $consolidated += "---`n`n"
        
        $count++
    } catch {
        Write-Warning "Failed to fetch $($item.Link)"
    }
}

# Save
$finalPath = Join-Path $outputPath "CONSOLIDATED_KNOWLEDGE.md"
$consolidated | Out-File -FilePath $finalPath -Encoding utf8

Write-Host "`n✅ Success! Documentation consolidated to:" -ForegroundColor Green
Write-Host "   $finalPath" -ForegroundColor Cyan
Write-Host "   Read this file to gain rapid mastery of the library." -ForegroundColor Cyan
