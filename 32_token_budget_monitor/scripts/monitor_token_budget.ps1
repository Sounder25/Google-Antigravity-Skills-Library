param(
    [int]$ModelLimit = 128000,
    [int]$EstimatedUsed,
    [ValidateSet("LOW","MEDIUM","HIGH")]
    [string]$TaskCriticality = "MEDIUM"
)

$ErrorActionPreference = "Stop"

if (-not $EstimatedUsed) { $EstimatedUsed = [int]($ModelLimit * 0.5) }

$util = [math]::Round(($EstimatedUsed / $ModelLimit) * 100, 1)
$warn = 60
$critical = 80
$ceiling = 90

if ($TaskCriticality -eq "HIGH") {
    $warn = 50
    $critical = 70
    $ceiling = 85
}

$status = "NOMINAL"
$action = "NONE"

if ($util -ge $ceiling) { $status = "CEILING"; $action = "BLOCK_AND_CHECKPOINT" }
elseif ($util -ge $critical) { $status = "CRITICAL"; $action = "CHECKPOINT_NOW" }
elseif ($util -ge $warn) { $status = "WARNING"; $action = "PREPARE_CHECKPOINT" }

@{
    model_limit = $ModelLimit
    estimated_used = $EstimatedUsed
    estimated_remaining = ($ModelLimit - $EstimatedUsed)
    utilization_pct = $util
    status = $status
    recommended_action = $action
} | ConvertTo-Json -Depth 3
