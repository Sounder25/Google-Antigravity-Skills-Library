---
name: Error-State Recovery
description: Wraps command execution in a self-healing loop. Uses heuristics to auto-fix common errors (missing deps, locked files) or escalates to the Agent with structured error context.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-006: Error-State Recovery

## Overview

Agents often fail due to transient or trivial errors (e.g., missing Python module, locked file, timeout). This skill provides a `Invoke-Recoverable` wrapper that catches these errors, attempts to apply known fixes, and retries the operation.

## Trigger Phrases

- `run with recovery`
- `auto-fix <command>`
- `try hard <command>`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--command` | string | Yes | - | The command to execute |
| `--retries` | int | No | 3 | Max retry attempts |
| `--heuristics` | switch | No | True | Enable heuristic auto-fixes (pip, npm, mkdir) |

## Outputs

1. **Success:** Standard output of the command.
2. **Failure:** `ERROR_STATE.json` containing the stack trace, context, and failed fix attempts.

## Supported Heuristics

1. **Python `ModuleNotFoundError`**: Auto-runs `pip install <module>`.
2. **DirectoryNotFound**: Auto-runs `mkdir -p`.
3. **File Locked**: Waits 2s and retries.
4. **CLI Missing**: Checks standard paths for tool (e.g., `forge`, `dotnet`).

## Preconditions

1. PowerShell 7+

## Implementation

See `invoke_recovery.ps1`.

## Integration

```powershell
.\skills\06_error_recovery\invoke_recovery.ps1 -Command "python hunt.py" -Retries 3
```
