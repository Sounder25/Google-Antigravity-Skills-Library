---
name: error-state-recovery
description: "Wrap command execution in a self-healing retry loop that applies heuristic auto-fixes for common errors (missing dependencies, locked files, missing directories) or escalates with structured error context. Use when running unreliable commands, automating build pipelines, or any agent workflow needs resilience against transient failures."
metadata:
  version: 1.0.0
  author: Antigravity Skills Library
  created: 2026-01-16
  leverage_score: 5/5
---

# Error-State Recovery

Wraps any command in a self-healing `Invoke-Recoverable` loop — catches errors, applies known fixes, and retries automatically.

## Trigger Phrases

- `run with recovery`
- `auto-fix <command>`
- `try hard <command>`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--command` | string | Yes | — | The command to execute |
| `--retries` | int | No | 3 | Max retry attempts |
| `--heuristics` | switch | No | True | Enable heuristic auto-fixes |

## Workflow

1. **Execute** the provided command via `Invoke-Expression`.
2. **Catch** any error and match the message against heuristic patterns (see table below).
3. **Apply fix** if a heuristic matches. **Verify the fix succeeded** (e.g., confirm the module is importable, directory exists, file is unlocked) before retrying.
4. **Retry** up to `--retries` times. Log each attempt to the errors array.
5. **Escalate** if all retries fail — write `ERROR_STATE.json` with stack trace, context, and failed fix attempts.

## Supported Heuristics

| Error Pattern | Auto-Fix |
|---------------|----------|
| Python `ModuleNotFoundError` | `pip install <module>` |
| `DirectoryNotFound` | `mkdir -p <path>` |
| File locked | Wait 2s, then retry |
| CLI tool missing | Check standard paths for the tool (e.g., `forge`, `dotnet`) |

## Outputs

- **On success:** Standard output of the command.
- **On failure:** `ERROR_STATE.json` with stack trace, context, and attempted fixes.

```json
{
  "command": "python hunt.py",
  "retries_attempted": 3,
  "errors": [
    { "attempt": 1, "error": "ModuleNotFoundError: No module named 'requests'", "fix_applied": "pip install requests" }
  ],
  "final_status": "FAILED"
}
```

## Preconditions

1. PowerShell 7+.

## Safety/QA Checks

- **Non-destructive fixes only** — heuristics install missing deps or create directories; never delete or overwrite.
- **Retry cap enforced** — prevents infinite loops via `--retries` limit.

## Implementation

Core retry loop (see `invoke_recovery.ps1` for full implementation):

```powershell
for ($i = 1; $i -le $Retries; $i++) {
    try { Invoke-Expression $Command; return }
    catch {
        $msg = $_.Exception.Message
        $fix = $null
        if ($msg -match "ModuleNotFoundError.*'(\w+)'") { $fix = "pip install $($Matches[1])" }
        elseif ($msg -match "DirectoryNotFound.*'(.+)'") { $fix = "mkdir -p $($Matches[1])" }
        elseif ($msg -match "locked|in use") { Start-Sleep 2; $fix = "(waited 2s)" }

        if ($fix) {
            Invoke-Expression $fix
            # Verify fix worked before retrying
            if ($fix -match "pip install") { python -c "import $($Matches[1])" 2>$null || Write-Warning "Fix may not have succeeded" }
        }
        $errors += @{ attempt=$i; error=$msg; fix_applied=$fix }
    }
}
$errors | ConvertTo-Json | Set-Content "ERROR_STATE.json"
```

## Integration

```powershell
.\skills\06_error_recovery\invoke_recovery.ps1 -Command "python hunt.py" -Retries 3
```
