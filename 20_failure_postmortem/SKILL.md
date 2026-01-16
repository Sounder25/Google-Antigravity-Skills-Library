---
name: Failure Postmortem
description: Structured logging and analysis of execution failures to prevent recurrence.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-020: Failure Postmortem

## Overview

Systematically captures failure data. When a tool fails or a plan is abandoned, this skill logs the event to a persistent registry (`POSTMORTEMS.md`), forcing an synchronous analysis of *why* it happened (Root Cause) and *how* to prevent it (Preventive Rule).

## Trigger Phrases

- `log failure`
- `postmortem`
- `why did this fail`
- `record error`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Command` | string | Yes | - | The command or action that failed |
| `--Error` | string | Yes | - | The error message or exception trace |
| `--Context` | string | No | `General` | What was the agent trying to do? |

## Outputs

### 1. Log Entry

Appends to `.gemini/antigravity/.forensics/POSTMORTEMS.md`:

```markdown
## [2026-01-16 10:00:00] Failure Analysis
**Context:** Deployment
**Command:** `npm build`
**Error:** `Heap out of memory`

### 🕵️ Analysis
1. **Root Cause:** Node processes default to 512MB RAM.
2. **Preventive Rule:** Always set NODE_OPTIONS="--max-old-space-size=4096" for builds.
```

## Preconditions

1. `.forensics` directory exists (auto-created).
2. PowerShell 5.1+ or Core 7+.

## Safety/QA Checks

1. **Persist**: Ensures the log file is always writable.
2. **No Data Loss**: Appends only, never overwrites previous logs.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Disk Full | Fail gracefully (stdout only) |

## Implementation

See `scripts/log_failure.ps1`.

## Integration with Other Skills

1. **Agent Catch Block**: On exception -> Call `log_failure.ps1`.
2. **Agent Step**: Read the output path.
3. **Agent Step**: "Thinking" block -> Fill in the "Analysis" section mentally or in next turn.
