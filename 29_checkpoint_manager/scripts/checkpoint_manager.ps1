param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("create","restore","list","validate")]
    [string]$Operation,
    [string]$Label,
    [string]$Path = ".\.checkpoints",
    [string]$Context,
    [switch]$Verified
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }

function New-CheckpointId {
    return "chk_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
}

if ($Operation -eq "create") {
    $id = New-CheckpointId
    $statePath = Join-Path $Path "${id}_state.json"
    $record = @{
        checkpoint_id = $id
        label = if ($Label) { $Label } else { $id }
        timestamp = (Get-Date).ToString("o")
        status = if ($Verified) { "VERIFIED" } else { "UNVERIFIED" }
        context = $Context
        artifacts = @($statePath)
        resumable = $true
    }
    $record | ConvertTo-Json -Depth 5 | Out-File -FilePath $statePath -Encoding utf8
    $record | ConvertTo-Json -Depth 5
    exit 0
}

if ($Operation -eq "list") {
    $items = Get-ChildItem -Path $Path -Filter "*_state.json" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    @{ checkpoints = $items } | ConvertTo-Json -Depth 2
    exit 0
}

if ($Operation -eq "validate") {
    $items = Get-ChildItem -Path $Path -Filter "*_state.json" -ErrorAction SilentlyContinue
    $status = if ($items.Count -gt 0) { "OK" } else { "EMPTY" }
    @{ status = $status; count = $items.Count } | ConvertTo-Json -Depth 2
    exit 0
}

if ($Operation -eq "restore") {
    $items = Get-ChildItem -Path $Path -Filter "*_state.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $items) { throw "No checkpoints to restore." }
    $latest = $items[0]
    @{ restored = $true; checkpoint_id = ($latest.BaseName -replace "_state$","") } | ConvertTo-Json -Depth 2
    exit 0
}
