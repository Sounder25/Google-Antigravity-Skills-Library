---
name: Semantic Diff
description: Determines not just what changed between two states, but whether the change was intentional, complete, and consequence-free relative to the original task.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-033: Semantic Diff

## Overview

Goes beyond syntactic diff to answer the question that matters: **was this change the right change, made completely, with no unintended side effects?** A line diff tells you what bytes changed. A semantic diff tells you whether the intent was fulfilled, whether anything changed that shouldn't have, and whether the change is complete or partial.

QMS equivalent: First Article Inspection. When a new part is produced, you do not just check dimensions. You verify that the part is the right part, made to the right revision, with no unintended deviations from nominal — and that nothing that should have changed was missed.

## Trigger Phrases

- `semantic diff`
- `what actually changed`
- `intent diff`
- `was this change right`
- `review the diff`

## Automatic Trigger

Activates when:
- Agent has modified one or more files
- A migration or transformation has been applied
- Before/after states are available for comparison
- Agent is about to declare a refactor complete

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Before` | string | Yes | - | Original state (file path, content, or snapshot ID) |
| `--After` | string | Yes | - | Modified state (file path, content, or snapshot ID) |
| `--Intent` | string | Yes | - | What the change was supposed to accomplish |
| `--Scope` | string | No | `file` | `file`, `directory`, `database`, `api` |

## Outputs

### 1. Semantic Diff Report (JSON)

```json
{
  "intent": "Replace deprecated `get_user()` calls with `fetch_user()`",
  "intent_fulfilled": false,
  "summary": {
    "intended_changes": 12,
    "confirmed_changes": 9,
    "missed_changes": 3,
    "unintended_changes": 2
  },
  "missed": [
    {
      "location": "src/auth/session.py:line 47",
      "detail": "get_user() call not replaced"
    }
  ],
  "unintended": [
    {
      "location": "src/utils/helpers.py:line 12",
      "detail": "Whitespace normalization altered unrelated function signature formatting"
    }
  ],
  "verdict": "INCOMPLETE — 3 missed replacements, 2 unintended changes",
  "safe_to_ship": false
}
```

### 2. Verdict Codes

- `COMPLETE`: All intended changes present, no unintended changes detected.
- `INCOMPLETE`: Intended changes missing — task not done.
- `OVERREACH`: Unintended changes detected — agent modified something outside scope.
- `CONFLICT`: Changes conflict with each other or introduce logical inconsistency.
- `UNKNOWN`: Insufficient context to evaluate intent against output.

## Preconditions

1. Before and after states are available.
2. Original intent is documented.

## Safety/QA Checks

1. **Ship Block on INCOMPLETE or OVERREACH**: Agent cannot declare task complete if either verdict is present.
2. **Unintended Change Escalation**: Any unintended change is surfaced to the user — the agent does not silently revert it.
3. **Completeness Is Binary**: A change that is 9/12 complete is not complete. Partial completion is treated as incomplete, not partial success.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| INCOMPLETE verdict | Block completion, list missed changes |
| OVERREACH verdict | Surface unintended changes, require user decision |
| CONFLICT verdict | Block entirely, trigger SKILL-003 (Adversarial Reviewer) |

## Implementation

See `scripts/semantic_diff.ps1`.

## Integration with Other Skills

1. Runs before **SKILL-005 (Output Verifier)** declares the task complete — semantic diff is the evidence verifier uses.
2. `OVERREACH` → **SKILL-007 (Scope Guard)** to investigate how drift occurred.
3. `INCOMPLETE` → agent continues task, then re-runs semantic diff.
4. `CONFLICT` → **SKILL-003 (Adversarial Reviewer)** to identify what the conflict breaks downstream.
5. Results feed **SKILL-004 (Failure Postmortem)** when a ship decision was made on an incomplete diff.




