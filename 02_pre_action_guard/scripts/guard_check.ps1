<#
.SYNOPSIS
    Evaluates the safety of a proposed agent action.
.DESCRIPTION
    Pre-Action Guard (SKILL-006). Checks destructive commands, file
    modifications, system-path access, command chaining, and broad
    wildcard patterns. Returns a JSON verdict.
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

# ── 1. Normalize ────────────────────────────────────────────
$Action = $Action.ToLower()
$Target = $Target.ToLower()
# Collapse double-backslashes from JSON escaping
$TargetNorm = $Target -replace '\\\\', '\'

# ── 2. Read-Only Actions ────────────────────────────────────
if ($Action -match "^(view_|list_|search_|read_|get-)") {
    $RiskLevel = "NONE"
    $Reason = "Read-only operation."
}

# ── 3. File Modifications ───────────────────────────────────
elseif ($Action -eq "write_to_file" -or $Action -eq "replace_file_content" -or $Action -eq "set-content") {
    $RiskLevel = "MEDIUM"
    $Reason = "Modifying file content."

    # Sensitive files
    if ($TargetNorm -match "(\.env|\.config|secrets|passwd|shadow|key|\.pem|\.pfx|\.cer|authorized_keys|id_rsa)") {
        $RiskLevel = "HIGH"
        $Warnings += "Modifying sensitive configuration or secret file."
        $Reason = "High risk target file."
    }
}

# ── 4. Shell Commands ───────────────────────────────────────
elseif ($Action -eq "run_command" -or $Action -eq "invoke-expression") {
    $RiskLevel = "HIGH"
    $Reason = "Executing shell command."

    # ── 4a. Destructive command patterns ────────────────────
    # Covers: rm, rmdir, rd, del, erase, remove-item, shred, wipe,
    #         drop (SQL), truncate (SQL), format (disk)
    $DestructivePattern = "(^|\s|;|&&|\|)(rm\s|rm\b|rmdir|rd\s|del\s|del\b|erase\s|remove-item|shred|wipe|drop\s|truncate\s|format\s|deltree)"
    if ($TargetNorm -match $DestructivePattern) {
        $RiskLevel = "CRITICAL"
        $Warnings += "Detected destructive command pattern."
        $Reason = "Destructive command detected."

        # ── 4b. Root / System path block ────────────────────
        # Block any destructive command targeting:
        #   - Drive roots:  C:\  D:\  C:/  /  
        #   - System dirs:  windows, system32, program files, users
        #   - Env vars:     %systemroot%, $env:
        #   - Broad wildcards:  *  *.*
        $RootPathPattern  = "([a-z]:[\\\/](\s|$|`"|'|\*))|(^|\s)[\\\/](\s|$)"
        $SystemDirPattern = "(windows|system32|program files|\\users\\|\\appdata\\|%systemroot%|\`$env:)"
        $BroadWildcard    = "(\s\*(\.\*)?(\s|$))|(\/s\s|\/q\s|-r\s|-rf\s|--force|-recurse)"

        if ($TargetNorm -match $RootPathPattern) {
            $Allowed = $false
            $Warnings += "BLOCKED: Destructive command targets drive root."
            $Reason = "Unsafe wide deletion attempt - drive root."
        }
        elseif ($TargetNorm -match $SystemDirPattern) {
            $Allowed = $false
            $Warnings += "BLOCKED: Destructive command targets protected system path."
            $Reason = "Unsafe deletion attempt - system directory."
        }
        elseif ($TargetNorm -match $BroadWildcard) {
            $Allowed = $false
            $Warnings += "BLOCKED: Destructive command uses recursive/force/broad wildcard flags."
            $Reason = "Unsafe deletion attempt - broad scope."
        }
        else {
            # Critical but focused (e.g. rm temp.txt) -> Warn, but allow
            $Allowed = $true
            $Warnings += "Confirm intent before execution."
        }
    }

    # ── 4c. Command chaining detection ──────────────────────
    if ($TargetNorm -match '(&&|\|\||;)\s*(rm\s|del\s|rmdir|rd\s|remove-item|format|drop)') {
        $RiskLevel = "CRITICAL"
        $Allowed = $false
        $Warnings += "BLOCKED: Chained destructive command detected."
        $Reason = "Chained destructive command - possible injection."
    }

    # ── 4d. Privilege escalation detection ──────────────────
    if ($TargetNorm -match "(sudo|runas|start-process.*-verb\s+runas|net\s+user|net\s+localgroup|icacls|chmod\s+777)") {
        if ($RiskLevel -ne "CRITICAL") { $RiskLevel = "CRITICAL" }
        $Warnings += "Detected privilege escalation pattern."
        if ($Reason -eq "Executing shell command.") { $Reason = "Privilege escalation attempt." }
    }
}

# ── 5. Output ───────────────────────────────────────────────
$Output = @{
    allowed    = $Allowed
    risk_level = $RiskLevel
    reason     = $Reason
    warnings   = $Warnings
    timestamp  = (Get-Date).ToString("o")
}

Write-Output ($Output | ConvertTo-Json -Depth 3)




