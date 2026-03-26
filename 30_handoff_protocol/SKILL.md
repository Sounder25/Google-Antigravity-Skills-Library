---
name: Handoff Protocol
description: Defines and enforces structured state transfer between agents, sessions, or models. Standardizes what is passed, what is dropped, and what must be re-verified on the receiving end.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-030: Handoff Protocol

## Overview

Eliminates **unstructured context transfer** between agent sessions, models, or sub-agents. When a task moves from one agent to another — or one session to the next — the receiving agent has no reliable mechanism to know what was completed, what was assumed, what failed, and what decisions were made. It infers. Inference at handoff is where tasks degrade silently.

QMS equivalent: Traveler Document / Router Card in manufacturing. Every part that moves between stations carries a documented record of what was done to it, what was verified, and what the next station is responsible for. The receiving operator does not guess. They read the traveler.

## Trigger Phrases

- `handoff`
- `transfer state`
- `prepare handoff`
- `context transfer`
- `pass to agent`

## Automatic Trigger

Activates when:
- A sub-agent is being delegated a task
- A session is ending with work incomplete
- A model switch is occurring mid-task
- User says "continue this in a new chat" or similar

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--From` | string | Yes | - | Sending agent or session identifier |
| `--To` | string | No | `next_session` | Receiving agent or session |
| `--CheckpointId` | string | No | $null | Reference to SKILL-029 checkpoint |
| `--Task` | string | Yes | - | Original task statement verbatim |

## Outputs

### 1. Handoff Document (Markdown)

```markdown
# HANDOFF DOCUMENT
**From:** Agent Session A / 2026-03-25T14:32
**To:** Agent Session B
**Task:** Migrate users table and update API layer

## What Was Completed
- Schema migration applied and verified (48,291 rows confirmed intact)
- Checkpoint: chk_20260325_143201 (VERIFIED)

## What Is Pending
- Update /api/v2/users endpoints
- Run integration test suite

## Decisions Made
- Chose additive migration (no column drops) to preserve rollback path
- Deferred index rebuild to maintenance window

## Assumptions in Play
- Staging environment mirrors production schema
- API consumers are on contract version 2.1+

## Known Risks
- Legacy client on v1.3 still active — backward compat not confirmed
- No rollback path for API layer changes once deployed

## What the Receiving Agent Must NOT Do
- Do not assume schema migration is complete without reading checkpoint
- Do not deploy API changes before running integration tests

## First Action for Receiving Agent
Read checkpoint chk_20260325_143201, verify row count, then proceed to API endpoint updates.
```

## Preconditions

1. A task is in progress with documented state.
2. Transfer recipient is identified (agent, session, or human).

## Safety/QA Checks

1. **No Implicit State**: Anything not in the handoff document does not transfer. The receiving agent cannot assume knowledge not explicitly recorded.
2. **Pending Risks Must Transfer**: Known risks are non-optional fields. A handoff that omits known risks is incomplete.
3. **Verified Checkpoint Reference**: Handoff document must reference a SKILL-029 checkpoint ID or explicitly state no checkpoint exists.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| No checkpoint exists | Warn, require user to confirm handoff without recovery point |
| Task intent unclear | Block handoff, require clarification of original task |
| Pending risks not documented | Block handoff until risks section is complete |

## Implementation

See `scripts/prepare_handoff.ps1`.

## Integration with Other Skills

1. **SKILL-029 (Checkpoint Manager)** provides the verified state the handoff document references.
2. **SKILL-006 (Assumption Auditor)** populates the "Assumptions in Play" section.
3. **SKILL-007 (Scope Guard)** populates the "What the Receiving Agent Must NOT Do" section.
4. Receiving agent runs **SKILL-005 (Output Verifier)** to confirm completed steps before resuming.




