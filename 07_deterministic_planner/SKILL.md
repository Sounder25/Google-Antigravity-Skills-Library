---
name: Deterministic Planner
description: Enforces a structural planning phase before execution. Generates and validates PLAN.json to ensure every task has a clear objective, steps, verification method, and rollback strategy.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-007: Deterministic Planner

## Overview

Complex tasks fail when agents improvise. This skill enforces a "Measure Twice, Cut Once" discipline by requiring a valid `PLAN.json` artifact before significant changes are made.

## Trigger Phrases

- `create plan <objective>`
- `start task <name>`
- `initialize mission`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--objective` | string | Yes | - | High-level goal (e.g., "Refactor gas logic") |
| `--output` | string | No | `PLAN.json` | Output file path |

## Outputs

1. `PLAN.json` with the following rigid schema:
    - `objective`: String
    - `steps`: Array of Objects `{ step: int, description: string, verification: string }`
    - `rollback_strategy`: String
    - `risks`: Array of strings

## Preconditions

None.

## Safety Checks

- Validates that `rollback_strategy` is not empty/null.
- Validates that every step has a `verification` criteria.

## Implementation

See `init_plan.ps1`.

## Integration

```powershell
.\skills\07_deterministic_planner\init_plan.ps1 -Objective "Migrate Database Schema"
# Returns valid JSON structure to fill
```
