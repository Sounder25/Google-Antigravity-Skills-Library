param(
    [Parameter(Mandatory = $true)]
    [string]$Action,
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [string]$Context = "General",
    [string]$RollbackPath,
    [string[]]$RequiredPreconditions,
    [switch]$Tested,
    [switch]$Manual
)

$ErrorActionPreference = "Stop"

$viability = "NONE"
$blocking = "No rollback path provided."

if ($RollbackPath) {
    if ($Manual) {
        $viability = "MANUAL"
        $blocking = "Rollback requires manual intervention."
    }
    elseif ($Tested) {
        $viability = "FULL"
        $blocking = $null
    }
    else {
        $viability = "PARTIAL"
        $blocking = "Rollback path untested."
    }
}

$rollbackViable = $viability -ne "NONE"

@{
    rollback_viable = $rollbackViable
    rollback_level = $viability
    action = $Action
    target = $Target
    context = $Context
    rollback_path = if ($RollbackPath) { $RollbackPath } else { $null }
    blocking_reason = $blocking
    required_preconditions = if ($RequiredPreconditions) { $RequiredPreconditions } else { @() }
    recommendation = if ($rollbackViable) { "Proceed with rollback safeguards" } else { "BLOCK - define rollback path" }
} | ConvertTo-Json -Depth 4
