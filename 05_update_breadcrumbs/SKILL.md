---
name: Update Intent Breadcrumbs
description: Updates standardized intent files (NEXT.md, STATE.json) to maintain context across agent sessions.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-15
leverage_score: 4/5
---

# SKILL-005: Update Intent Breadcrumbs

## Overview

Agents often lose context between sessions. This skill enforces a standard "breadcrumb" trail by creating or updating `NEXT.md` (human readable) and `STATE.json` (machine readable) in the workspace root.

## Trigger Phrases

- `update breadcrumbs`
- `save state`
- `update next steps`
- `checkpoint workspace`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--status` | string | No | `active` | `active`, `blocked`, `paused` |
| `--objective` | string | No | - | Current high-level objective |
| `--next-steps` | string[] | No | - | List of immediate next tasks |
| `--blockers` | string[] | No | - | List of blocking issues |

## Outputs

1. Updated `NEXT.md`.
2. Updated `STATE.json`.

## Preconditions

1. Valid workspace root.

## Safety/QA Checks

1. Preserve existing content in `NEXT.md` (append/update rather than overwrite if possible, or use smart replacement).
2. Validate JSON syntax for `STATE.json`.

## Implementation

See `update_breadcrumbs.ps1`.

## Integration

```powershell
.\skills\05_update_breadcrumbs\update_breadcrumbs.ps1 -Status "active" -Objective "Fix EELS tests" -NextSteps "Run pytest", "Fix bugs"
```
