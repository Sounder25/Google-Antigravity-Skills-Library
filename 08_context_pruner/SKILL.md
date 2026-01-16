---
name: Context Window Pruner
description: Optimize information density by filtering workspace files based on relevance to the current task. Excludes high-noise files (lockfiles, assets) and prioritizes source code matching semantic queries.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-008: Context Window Pruner

## Overview

Large repos flood the agent's context window with noise. This skill generates a `RELEVANT_FILES.txt` list by aggressively pruning irrelevant directories and searching for files related to a specific "Focus".

## Trigger Phrases

- `focus on <topic>`
- `find relevant files for <task>`
- `prune context`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--focus` | string | Yes | - | Keywords to filter file names/content (e.g. "gas", "auth") |
| `--max-files` | int | No | 50 | Limit output size |

## Outputs

1. `RELEVANT_FILES.txt`: List of absolute paths to read.
2. Console output summarizing token savings (estimated).

## Safety Checks

- Always respects `.gitignore`.
- Never includes binary files.
- Caps output to avoid context overflow.

## Implementation

See `prune_context.ps1`.

## Integration

```powershell
$files = .\skills\08_context_pruner\prune_context.ps1 -Focus "EVM opcode"
# Agent works only with $files
```
