<#
.SYNOPSIS
    Evaluates the safety of a proposed agent action.
.DESCRIPTION
    Checks destructive commands, file modifications, and plan alignment.
.PARAMETER Action
    The operation being performed (write_to_file, run_command, etc.)
.PARAMETER Target
    The file path or command string.
.PARAMETER Plan
    Optional context about the current goal.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$Target,

    [Parameter(Mandatory = $false)]
    [string]$Plan
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RiskLevel = "LOW"
$Allowed = $true
$Warnings = @()
$Reason = "Action appears safe."

# 1. Normalize
$Action = $Action.ToLower()
$Target = $Target.ToLower()

# 2. Category Check
if ($Action -match "^(view_|list_|search_|read_|get-)") {
    $RiskLevel = "NONE"
    $Reason = "Read-only operation."
}
elseif ($Action -eq "write_to_file" -or $Action -eq "replace_file_content" -or $Action -eq "set-content") {
    $RiskLevel = "MEDIUM"
    $Reason = "Modifying file content."
    
    # Check for critical files
    if ($Target -match "(\.env|\.config|secrets|passwd|key|\.pem)") {
        $RiskLevel = "HIGH"
        $Warnings += "Modifying sensitive configuration or secret file."
        $Reason = "High risk target file."
    }
}
elseif ($Action -eq "run_command" -or $Action -eq "invoke-expression") {
    $RiskLevel = "HIGH"
    $Reason = "Executing shell command."
    
    # Check for destructive commands
    if ($Target -match "(rm\s|del\s|remove-item|drop\s|truncate\s|format\s)") {
        $RiskLevel = "CRITICAL"
        $Warnings += "Detected destructive command pattern."
        $Reason = "Destructive command detected."
        
        # Auto-block absolute root paths or broad wildcards
        if ($Target -match "(\s/|\s[c-d]:\\|\s\*)$") {
            $Allowed = $false
            $Warnings += "Broad or root deletion BLOCKED automatically."
            $Reason = "Unsafe wide deletion attempt."
        }
        else {
            # Critical but focused (e.g. rm file.txt) -> Requires Warning
            $Allowed = $true 
            $Warnings += "Confirm intent before execution."
        }
    }
}

$Output = @{
    allowed    = $Allowed
    risk_level = $RiskLevel
    reason     = $Reason
    warnings   = $Warnings
    timestamp  = (Get-Date).ToString("o")
}

Write-Output ($Output | ConvertTo-Json -Depth 3)
