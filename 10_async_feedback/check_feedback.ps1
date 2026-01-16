# SKILL-010: Async Feedback Loop
# Checks for new user instructions in FEEDBACK.md

param(
    [string]$File = "FEEDBACK.md",
    [switch]$Acknowledge
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $File)) {
    # If not exists, create it from template
    $templatePath = Join-Path $PSScriptRoot "templates\FEEDBACK_TEMPLATE.md"
    if (Test-Path $templatePath) {
        Copy-Item $templatePath $File
        Write-Host "Created new feedback channel: $File" -ForegroundColor Cyan
    }
    else {
        # Fallback
        Set-Content $File -Value "# Feedback Channel`nWrite your instructions here. The agent will read them."
    }
    exit 1 # No feedback yet
}

$content = Get-Content $File -Raw
if (-not $content) { exit 1 } # Empty

# logic to determine if "New"
# We act if the file doesn't end with "ACKNOWLEDGED_BY_AGENT"
# or we just print it. Simple approach: Print content that isn't acknowledging.

if ($content -match "<!-- ACKNOWLEDGED -->") {
    Write-Host "No new feedback (Active channel)." -ForegroundColor Gray
    exit 1
}

Write-Host "🚨 NEW FEEDBACK DETECTED 🚨" -ForegroundColor Magenta
Write-Host "---------------------------"
Write-Host $content -ForegroundColor Yellow
Write-Host "---------------------------"

if ($Acknowledge) {
    Add-Content $File -Value "`n`n<!-- ACKNOWLEDGED -->`n*Read by Agent at $(Get-Date)*"
    Write-Host "Feedback marked as read." -ForegroundColor Green
}

exit 0 # Found feedback
