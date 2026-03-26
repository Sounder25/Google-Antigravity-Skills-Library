---
name: Checkpoint Manager
description: Creates, validates, and restores verified state snapshots at defined intervals during multi-step tasks. Prevents total loss when an agent fails mid-execution.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-029: Checkpoint Manager

## Overview

Enforces **structured state persistence** across multi-step agent execution. When an agent fails mid-task — context window exhausted, session terminated, unrecoverable error — the only question is whether it resumes from a known good state or starts over into a potentially corrupted one. Without this skill, the answer is always the latter.

QMS equivalent: In-Process Inspection at defined hold points. You do not run the next stage of a production process until the current stage is confirmed and recorded. The record is the recovery mechanism.

## Trigger Phrases

- `create checkpoint`
- `save state`
- `checkpoint here`
- `restore checkpoint`
- `what's the last checkpoint`

## Automatic Trigger

Activates at:
- Every 5 significant actions in a multi-step task
- Before any HIGH or CRITICAL risk action (per SKILL-002)
- Before context window is estimated to be 80% full
- On detection of an impasse (per SKILL-001)
- On any unhandled error

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Operation` | string | Yes | - | `create`, `restore`, `list`, `validate` |
| `--Label` | string | No | auto-generated | Human-readable checkpoint name |
| `--Path` | string | No | `./.checkpoints/` | Where checkpoint files are written |
| `--Context` | string | No | $null | Current task state to serialize |

## Outputs

### 1. Checkpoint Record (JSON)

```json
{
  "checkpoint_id": "chk_20260325_143201",
  "label": "after_schema_migration",
  "timestamp": "2026-03-25T14:32:01Z",
  "status": "VERIFIED",
  "task_intent": "Migrate users table and update API layer",
  "completed_steps": [
    "Schema migration applied",
    "Row count verified: 48,291 records intact"
  ],
  "pending_steps": [
    "Update API endpoints",
    "Run integration tests"
  ],
  "artifacts": [
    ".checkpoints/chk_20260325_143201_state.json"
  ],
  "resumable": true
}
```

### 2. Restore Result

```json
{
  "restored": true,
  "checkpoint_id": "chk_20260325_143201",
  "resume_from": "Update API endpoints",
  "warnings": ["2 hours elapsed since checkpoint — verify external state before resuming"]
}
```

## Preconditions

1. Task has more than 3 sequential steps.
2. Write access to checkpoint directory.

## Safety/QA Checks

1. **Verification Before Record**: A checkpoint is not marked `VERIFIED` until the state it records has been confirmed by SKILL-005 (Output Verifier). An unverified checkpoint is worse than none — it gives false confidence in a bad state.
2. **Stale Warning**: Checkpoints older than 1 hour trigger a staleness warning on restore — external systems may have changed.
3. **No Overwrite**: Checkpoints append only. A new checkpoint never replaces an old one.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Checkpoint write fails | Halt task, surface error |
| Restore target not found | List available checkpoints, ask user to select |
| Checkpoint unverified | Warn before restoring, require user confirmation |

## Implementation

See `scripts/checkpoint_manager.ps1`.

## Integration with Other Skills

1. **SKILL-005 (Output Verifier)** must confirm state before a checkpoint is marked `VERIFIED`.
2. **SKILL-001 (Impasse Detector)** triggers checkpoint creation before escalation.
3. **SKILL-002 (Pre-Action Guard)** triggers checkpoint creation before CRITICAL actions.
4. **SKILL-027 (Rollback Planner)** references checkpoints as the rollback target — a verified checkpoint is the rollback path.
5. **SKILL-030 (Handoff Protocol)** uses the checkpoint record as the canonical state transfer artifact.



