---
name: Scope Guard
description: Detects task scope drift by comparing observed targets against allowed boundaries.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-03-25
leverage_score: 5/5
---

# SKILL-007: Scope Guard

## Overview

Containment control to prevent scope creep. Compares observed paths to allowed roots and flags drift.

## Trigger Phrases

- `check scope`
- `guard scope`
- `detect drift`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--AllowedRoots` | string[] | Yes | - | Root directories that define allowed scope |
| `--ObservedPaths` | string[] | Yes | - | Paths touched or proposed by the agent |

## Outputs

JSON:

```json
{
  "status": "PASS",
  "out_of_scope": []
}
```

## Implementation

See `scripts/check_scope.ps1`.

## Integration

```powershell
# Example: block drift outside the allowed workspace
.\skills\07_scope_guard\scripts\check_scope.ps1 -AllowedRoots "C:\projects\target" -ObservedPaths "C:\projects\target\file.txt", "C:\Windows\System32\config"
```




