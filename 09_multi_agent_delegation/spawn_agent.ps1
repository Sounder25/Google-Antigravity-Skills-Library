# SKILL-009: Agent-Swarm Spawner
# Creates isolated context for a sub-agent using templates

param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    
    [Parameter(Mandatory = $true)]
    [string]$Instructions,
    
    [string[]]$ContextFiles
)

$ErrorActionPreference = "Stop"

$swarmRoot = ".swarm"
$taskDir = Join-Path $swarmRoot $TaskName

if (Test-Path $taskDir) {
    Write-Warning "Swarm task '$TaskName' already exists."
    $TaskName = "${TaskName}_$(Get-Random)" 
    $taskDir = Join-Path $swarmRoot $TaskName
    Write-Warning "Created new unique path: $taskDir"
}

New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
Write-Host "Created swarm workspace: $taskDir" -ForegroundColor Cyan

# === DEFINE SKILLS MANIFEST ===
# This list informs the new agent what they can do.
$skillsManifest = @"
| Skill | Trigger / Command | Description |
|-------|-------------------|-------------|
| **Forensics** | `audit workspace` | Learn about the codebase structure and language. |
| **Search** | `prune context -Focus <topic>` | Find the specific files you need. |
| **EELS Tests** | `run eels tests` | Verify EVM compliance (Ethereum). |
| **Rename** | `rename project` | Refactor project names safely. |
| **Recovery** | `run with recovery` | Auto-fix errors (invoke_recovery.ps1). |
| **Planner** | `create plan` | Create a PLAN.json before complex coding. |
| **Feedback** | `check feedback` | See if the user has sent new instructions. |

**Full Library:** `~/.gemini/antigravity/skills/README.md`
"@

# 1. Generate MISSION.md (The Prompt)
$missionPath = Join-Path $taskDir "MISSION.md"
$templatePath = Join-Path $PSScriptRoot "templates\MISSION_TEMPLATE.md"

if (Test-Path $templatePath) {
    $content = Get-Content $templatePath -Raw
    $content = $content -replace "{{TASK_NAME}}", $TaskName
    $content = $content -replace "{{INSTRUCTIONS}}", $Instructions
    
    # Resolve path for clarity
    $absTaskDir = (Resolve-Path $taskDir).Path
    $content = $content -replace "{{TASK_DIR}}", $absTaskDir
    
    # Inject Skills
    $content = $content -replace "{{SKILLS_MANIFEST}}", $skillsManifest
    
    $content | Out-File $missionPath -Encoding utf8
    Write-Host "Generated MISSION.md from template with Skills Manifest" -ForegroundColor Green
}
else {
    Write-Warning "Template not found at $templatePath"
}

# 2. Copy Context
if (Test-Path "WORKSPACE_PROFILE.json") {
    Copy-Item "WORKSPACE_PROFILE.json" $taskDir
}

if ($ContextFiles) {
    foreach ($file in $ContextFiles) {
        if (Test-Path $file) {
            Copy-Item $file $taskDir
            Write-Host "Copied context: $file" -ForegroundColor Gray
        }
        else {
            Write-Warning "Context file not found: $file"
        }
    }
}

Write-Host "Instruction: Open a new terminal, cd to '$taskDir', and start a new agent with MISSION.md." -ForegroundColor Yellow
