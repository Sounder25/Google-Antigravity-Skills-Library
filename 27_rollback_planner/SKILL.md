---
name: Rollback Planner
description: Forces definition of a complete undo path before any irreversible action executes. No rollback plan, no execution.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-027: Rollback Planner

## Overview

Enforces the requirement that **every irreversible action has a defined undo path before it executes**. Pre-Action Guard decides whether an action is safe to run. Rollback Planner decides whether the consequences can be reversed if it goes wrong. These are different questions. An action can pass the guard and still have no rollback path — that is its own failure mode.

QMS equivalent: Engineering Change Control. No process change goes to production without a documented reversal procedure. If you cannot describe how to undo it, you are not ready to do it.

## Trigger Phrases

- `plan rollback`
- `how do we undo this`
- `rollback check`
- `what's the revert`
- `define undo path`

## Automatic Trigger

Activates automatically when the agent plans any of the following:
- Database migrations or schema changes
- Dependency upgrades
- Infrastructure changes (DNS, load balancer, firewall)
- Deployment to production
- File system restructuring across multiple paths
- API version changes

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Action` | string | Yes | - | The planned irreversible action |
| `--Target` | string | Yes | - | What is being acted on |
| `--Context` | string | No | `General` | Environment or system context |

## Outputs

### 1. Rollback Assessment (JSON)

```json
{
  "rollback_viable": false,
  "action": "ALTER TABLE users DROP COLUMN legacy_id",
  "rollback_path": null,
  "blocking_reason": "Column drop is irreversible in this engine without prior backup. No snapshot confirmed.",
  "required_preconditions": [
    "Full table backup confirmed at known path",
    "Backup restoration tested in staging",
    "Point-in-time recovery window confirmed active"
  ],
  "recommendation": "BLOCK — define and verify rollback path before executing"
}
```

### 2. Rollback Viability Levels

- `FULL`: Complete undo path defined, tested, and ready.
- `PARTIAL`: Undo path exists but untested or incomplete.
- `MANUAL`: Rollback requires human intervention — must be documented and agreed to.
- `NONE`: No viable rollback path. Action requires explicit user authorization to proceed.

## Preconditions

1. Action has been identified as irreversible or high-consequence.
2. Target system or resource is known.

## Safety/QA Checks

1. **Hard Block on NONE**: If rollback viability is `NONE`, execution is blocked until the user explicitly authorizes proceeding without a rollback path.
2. **No Assumed Backups**: The agent cannot assume a backup exists. It must confirm one.
3. **Staging First**: If a rollback path exists but is untested, the skill requires staging validation before production execution.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| No rollback path identified | Block execution, surface to user |
| Backup unconfirmed | Require confirmation before proceeding |
| Rollback untested | Require staging validation |

## Implementation

See `scripts/plan_rollback.ps1`.

## Integration with Other Skills

1. Runs after **SKILL-002 (Pre-Action Guard)** confirms the action is intended.
2. Runs before **SKILL-006 (Assumption Auditor)** validates environment assumptions.
3. If rollback is `NONE` and user authorizes anyway → **SKILL-029 (Checkpoint Manager)** must create a recovery point immediately before execution.
4. On failure → **SKILL-004 (Failure Postmortem)** documents whether the rollback path worked.



