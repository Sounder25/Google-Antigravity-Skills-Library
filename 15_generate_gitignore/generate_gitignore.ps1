# SKILL-015: Generate .gitignore
# Fetches standard gitignore templates

param(
    [string]$WorkspacePath = (Get-Location),
    [string[]]$Templates,
    [switch]$Append
)

$ErrorActionPreference = "Stop"
$WorkspacePath = Resolve-Path $WorkspacePath
$targetFile = Join-Path $WorkspacePath ".gitignore"

if (-not $Templates) {
    Write-Error "Please provide at least one template (e.g. -Templates 'Python', 'Node')"
    exit 1
}

$baseUrl = "https://raw.githubusercontent.com/github/gitignore/master"
$content = ""

if (Test-Path $targetFile) {
    if ($Append) {
        Write-Host "Appending to existing .gitignore..." -ForegroundColor Cyan
        $content = (Get-Content $targetFile -Raw) + "`n"
    }
    else {
        Write-Warning "Overwriting existing .gitignore (Use -Append to preserve)"
    }
}

foreach ($t in $Templates) {
    # Try simple map first
    # GitHub creates files specifically named like "Python.gitignore", "Node.gitignore"
    # Some are in "Global/" directory
    
    $candidates = @("$t.gitignore", "Global/$t.gitignore")
    $found = $null
    
    foreach ($c in $candidates) {
        $uri = "$baseUrl/$c"
        try {
            $temp = Invoke-RestMethod -Uri $uri -ErrorAction Stop
            $found = $temp
            Write-Host "Fetched template: $t" -ForegroundColor Green
            break
        }
        catch {}
    }
    
    if ($found) {
        $content += "`n# --- Template: $t ---`n"
        $content += $found
    }
    else {
        Write-Warning "Could not find template '$t' in github/gitignore"
    }
}

$content | Out-File -FilePath $targetFile -Encoding utf8
Write-Host "✅ .gitignore updated at $targetFile" -ForegroundColor Green
