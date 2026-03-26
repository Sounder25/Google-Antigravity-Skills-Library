---
name: Assumption Auditor
description: Surfaces unverified assumptions before execution by classifying each as verified or unverified.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-03-25
leverage_score: 5/5
---

# SKILL-006: Assumption Auditor

## Overview

Forces explicit listing of assumptions and flags those not verified. This is the FMEA-style pre-execution checklist for agent plans.

## Trigger Phrases

- `audit assumptions`
- `pre-execution checklist`
- `list assumptions`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Assumptions` | string[] | Yes | - | Assumptions the agent is making |
| `--VerifiedAssumptions` | string[] | No | - | Subset confirmed as verified |

## Outputs

JSON:

```json
{
  "status": "WARN",
  "verified": ["..."],
  "unverified": ["..."]
}
```

## Implementation

See `scripts/audit_assumptions.ps1`.

## Integration

```powershell
# Example: audit assumptions before executing a plan
.\skills\06_assumption_auditor\scripts\audit_assumptions.ps1 -Assumptions "env is test", "credentials valid" -VerifiedAssumptions "credentials valid"
```




