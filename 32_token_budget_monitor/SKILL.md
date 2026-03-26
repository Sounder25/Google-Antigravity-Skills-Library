---
name: Token Budget Monitor
description: Tracks context window consumption during multi-step tasks and triggers structured action before the agent degrades silently or truncates critical context.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-032: Token Budget Monitor

## Overview

Prevents **silent context degradation** — the failure mode where an agent approaching its context ceiling begins dropping earlier context, producing inconsistent output, or failing without explanation. The agent does not announce this. It just gets worse. Without monitoring, the user cannot distinguish model degradation from task complexity.

QMS equivalent: Resource Constraint Monitoring. A production line does not run a shift without tracking material inventory. When a critical resource approaches depletion, the line flags it and adjusts — it does not run out mid-cycle and produce defective parts.

## Trigger Phrases

- `check token budget`
- `context check`
- `how much context left`
- `budget check`
- `am i running out of context`

## Automatic Trigger

Activates when:
- Estimated context usage exceeds 60% (warning)
- Estimated context usage exceeds 80% (checkpoint trigger)
- Estimated context usage exceeds 90% (execution block — must prune or checkpoint before continuing)
- Task has exceeded 20 significant turns

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--ModelLimit` | int | No | 128000 | Context window size in tokens for current model |
| `--EstimatedUsed` | int | No | auto | Estimated tokens consumed so far |
| `--TaskCriticality` | string | No | `MEDIUM` | `LOW`, `MEDIUM`, `HIGH` — affects threshold sensitivity |

## Outputs

### 1. Budget Status (JSON)

```json
{
  "model_limit": 128000,
  "estimated_used": 108000,
  "estimated_remaining": 20000,
  "utilization_pct": 84.4,
  "status": "CRITICAL",
  "recommended_action": "CHECKPOINT_NOW",
  "options": [
    "Create checkpoint via SKILL-029 and continue in new session",
    "Run SKILL-015 (Context Pruner) to compress conversation history",
    "Summarize completed steps and drop raw transcript from context"
  ],
  "warning": "At current rate, context ceiling reached in approximately 3 more steps"
}
```

### 2. Status Levels

- `NOMINAL`: Under 60% — no action required.
- `WARNING`: 60–80% — begin preparing checkpoint.
- `CRITICAL`: 80–90% — checkpoint now before continuing.
- `CEILING`: 90%+ — stop execution, checkpoint and prune required before any further steps.

## Preconditions

1. Active multi-step task in progress.
2. Known or estimable model context limit.

## Safety/QA Checks

1. **Ceiling Block**: At `CEILING` status, the agent does not continue execution. It checkpoints, prunes, or hands off — it does not degrade silently.
2. **Proactive Warning**: The skill warns at 60%, not 90%. Recovery options at 60% are far better than at 90%.
3. **Critical Task Sensitivity**: `HIGH` criticality tasks trigger warning at 50% and block at 75%.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Status CEILING | Block execution, require checkpoint or prune |
| Critical task at 75% | Trigger checkpoint, warn user |
| Remaining tokens insufficient for next step | Block step, surface options |

## Implementation

See `scripts/monitor_token_budget.ps1`.

## Integration with Other Skills

1. At `CRITICAL` → trigger **SKILL-029 (Checkpoint Manager)** immediately.
2. At `WARNING` → trigger **SKILL-015 (Context Pruner)** to compress history.
3. At `CEILING` → trigger **SKILL-030 (Handoff Protocol)** if task must continue in new session.
4. Pairs with **SKILL-001 (Impasse Detector)** — an agent looping near context ceiling is a compounded failure mode requiring both skills.




