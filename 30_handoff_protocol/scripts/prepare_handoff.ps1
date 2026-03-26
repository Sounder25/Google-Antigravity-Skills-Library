param(
    [Parameter(Mandatory = $true)]
    [string]$From,
    [string]$To = "next_session",
    [Parameter(Mandatory = $true)]
    [string]$Task,
    [string]$CheckpointId,
    [string[]]$Completed,
    [string[]]$Pending,
    [string[]]$Decisions,
    [string[]]$Assumptions,
    [string[]]$Risks,
    [string]$OutputPath = "HANDOFF.md"
)

$ErrorActionPreference = "Stop"

$content = @()
$content += "# HANDOFF DOCUMENT"
$content += "**From:** $From"
$content += "**To:** $To"
$content += "**Task:** $Task"
$content += ""

if ($CheckpointId) {
    $content += "**Checkpoint:** $CheckpointId"
    $content += ""
}

$content += "## What Was Completed"
if ($Completed) { $Completed | ForEach-Object { $content += "- $_" } } else { $content += "- (none)" }
$content += ""

$content += "## What Is Pending"
if ($Pending) { $Pending | ForEach-Object { $content += "- $_" } } else { $content += "- (none)" }
$content += ""

$content += "## Decisions Made"
if ($Decisions) { $Decisions | ForEach-Object { $content += "- $_" } } else { $content += "- (none)" }
$content += ""

$content += "## Assumptions in Play"
if ($Assumptions) { $Assumptions | ForEach-Object { $content += "- $_" } } else { $content += "- (none)" }
$content += ""

$content += "## Known Risks"
if ($Risks) { $Risks | ForEach-Object { $content += "- $_" } } else { $content += "- (none)" }
$content += ""

$content | Out-File -FilePath $OutputPath -Encoding utf8

@{ handoff_path = $OutputPath } | ConvertTo-Json -Depth 2
