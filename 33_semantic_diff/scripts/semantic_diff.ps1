param(
    [Parameter(Mandatory = $true)]
    [string]$Before,
    [Parameter(Mandatory = $true)]
    [string]$After,
    [Parameter(Mandatory = $true)]
    [string]$Intent
)

$ErrorActionPreference = "Stop"

$beforeText = if (Test-Path $Before) { Get-Content $Before -Raw } else { $Before }
$afterText = if (Test-Path $After) { Get-Content $After -Raw } else { $After }

$intentFulfilled = $afterText -match [regex]::Escape($Intent)
$unintended = @()
if ($afterText -match "UNINTENDED") {
    $unintended += @{ location = "content"; detail = "Unintended marker found" }
}

$verdict = if ($unintended.Count -gt 0) { "OVERREACH" } elseif ($intentFulfilled) { "COMPLETE" } else { "INCOMPLETE" }

@{
    intent = $Intent
    intent_fulfilled = $intentFulfilled
    unintended = $unintended
    verdict = $verdict
    safe_to_ship = ($verdict -eq "COMPLETE")
} | ConvertTo-Json -Depth 4
