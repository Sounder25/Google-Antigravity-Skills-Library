---
name: Pre-Action Guard
description: A QA gate that validates potentially destructive or irreversible actions before execution.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-018: Pre-Action Guard

## Overview

Enforces a **"Measure Twice, Cut Once"** philosophy. This skill intercepts high-stakes actions (file writes, command execution) and validates them against safety rules and the current active plan to prevent accidental data loss or system corruption.

## Trigger Phrases

- `check safety`
- `verify action`
- `is this safe`
- `guard check`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Action` | string | Yes | - | The tool/verb being performed (e.g. `write_to_file`, `rm`) |
| `--Target` | string | Yes | - | The file path or command argument |
| `--Plan` | string | No | $null | The current plan context for alignment check |

## Outputs

### 1. Assessment Result (JSON)

```json
{
  "allowed": false,
  "risk_level": "CRITICAL",
  "reason": "Root directory deletion detected.",
  "warnings": ["Target matches blocked pattern '/*'."]
}
```

### 2. Risk Levels

- `NONE`: Read-only operations.
- `LOW`: Safe writes (files in temp, new files).
- `MEDIUM`: Modifying existing non-critical files.
- `HIGH`: Modifying config/env files.
- `CRITICAL`: Destructive delete/format commands.

## Preconditions

1. Valid tool/action inputs.
2. PowerShell 5.1+ or Core 7+.

## Safety/QA Checks

1. **Auto-Block**: Root deletions (`/`, `C:\`) are automatically blocked.
2. **Context Awareness**: Checks `.env` and `config` keywords for higher sensitivity.
3. **Command-Only Discipline**:
   - Rejects output containing shell prompts (`PS C:\`, `>`).
   - Rejects lines that look like terminal output (e.g., `Everything up-to-date`, `At line:`, `CategoryInfo:`).
   - Rejects mixed snippets containing both commands and output.
   - **Enforcement**: All runnable commands must be isolated in a clean, validated block.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Missing Action/Target | Return error |
| CRITICAL risk | Return `allowed: false` |
| Mixed Output Detected | Return `allowed: false` |

## Implementation

See `scripts/guard_check.ps1`.

## Integration with Other Skills

**All agents must:**

1. Call this skill BEFORE running `write_to_file` on existing files.
2. Call this skill BEFORE running any `run_command` containing `rm`, `del`, `drop`.
3. If `allowed` is false, **STOP** and ask user for confirmation.
