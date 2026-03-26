---
name: Dependency Validator
description: Confirms that every resource, service, file, and capability a plan depends on actually exists and is in the required state before execution begins.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-031: Dependency Validator

## Overview

Catches the failure mode where an agent **builds a plan that depends on things it assumes exist** — and never verifies they do. The plan looks complete. It runs. It fails at step 3 because the service it expected was down, the file it expected was missing, or the API version it targeted had been deprecated.

QMS equivalent: Pre-Production Readiness Check. Before a production run begins, every material, tool, fixture, and resource required is confirmed present and in specification. You do not start a run on assumptions.

## Trigger Phrases

- `validate dependencies`
- `check deps`
- `dependency check`
- `confirm prerequisites`
- `are we ready`

## Automatic Trigger

Activates before execution of any plan that references:
- External services or APIs
- File paths or directories
- Environment variables or secrets
- Database connections
- Installed packages or specific versions
- Network resources

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Plan` | string | Yes | - | The planned task or script to analyze |
| `--Environment` | string | No | `local` | Target environment: `local`, `staging`, `production` |
| `--Strict` | bool | No | true | If true, any unconfirmed dependency blocks execution |

## Outputs

### 1. Dependency Report (JSON)

```json
{
  "ready_to_execute": false,
  "environment": "production",
  "dependencies": [
    {
      "name": "PostgreSQL connection",
      "type": "service",
      "status": "CONFIRMED",
      "detail": "Connection verified, version 15.2"
    },
    {
      "name": "AWS_SECRET_KEY",
      "type": "environment_variable",
      "status": "MISSING",
      "detail": "Variable not found in current environment",
      "blocking": true
    },
    {
      "name": "/data/input/users_export.csv",
      "type": "file",
      "status": "MISSING",
      "detail": "File not found at expected path",
      "blocking": true
    }
  ],
  "blocking_count": 2,
  "recommendation": "BLOCK — resolve 2 missing dependencies before execution"
}
```

### 2. Dependency Status Codes

- `CONFIRMED`: Dependency verified present and in required state.
- `DEGRADED`: Present but not in expected state (wrong version, partial data).
- `MISSING`: Not found. Blocks execution if `Strict` is true.
- `ASSUMED`: Not verified — agent assumed it exists. Treated as `MISSING` in strict mode.

## Preconditions

1. A plan or script has been defined.
2. Agent has access to check the environment (read files, ping services, check env vars).

## Safety/QA Checks

1. **No Assumed Dependencies**: Any dependency marked `ASSUMED` is treated as unverified and requires explicit confirmation.
2. **Environment Isolation**: Dependencies confirmed in staging are not assumed confirmed in production. Environments are validated independently.
3. **Version Specificity**: If the plan requires a specific version, the validator confirms that version — not just that the dependency exists.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Any blocking dependency MISSING | Block execution, list all missing items |
| ASSUMED dependencies present | Require explicit verification before proceeding |
| Environment mismatch | Warn and require confirmation to proceed |

## Implementation

See `scripts/validate_dependencies.ps1`.

## Integration with Other Skills

1. Runs before **SKILL-002 (Pre-Action Guard)** — dependencies must exist before the guard evaluates the action itself.
2. `MISSING` dependencies → **SKILL-006 (Assumption Auditor)** to surface what the agent had assumed.
3. Dependency failures during execution → **SKILL-004 (Failure Postmortem)**.
4. Pairs with **SKILL-027 (Rollback Planner)** — rollback dependencies (backup files, restore scripts) must also be validated.



