---
name: State Overlay Consistency Checker
description: Detect and prevent state-visibility violations across execution contexts within a single transaction.
---

# SKILL-022 — State Overlay Consistency Checker

## Status

**PROPOSED → VERIFIED (after EELS reproduction)**

## Purpose

Detect and prevent state-visibility violations across execution contexts within a single transaction.

This skill ensures that state mutations (code deployment, storage writes, warm slots, balances) performed in one execution frame (e.g., CREATE, CREATE2) are visible and inherited by all subsequent execution contexts (CALL, DELEGATECALL, STATICCALL) during the same transaction.

This skill exists to stop silent gas under-charging and consensus-breaking execution paths.

## Problem Class

### Silent Overlay Forking

A transaction performs:

1. **CREATE / CREATE2**
2. Writes code to state
3. Immediately performs **CALL** to the created address

**But:**

- Child execution context does not see the deployed code.
- Call executes as if target is empty.
- Gas accounting under-charges.
- Final balances diverge from expected EELS state.

This failure is invisible to standard unit tests unless gas and state continuity are explicitly validated.

## Trigger

- **Manual:** `verify state continuity`
- **Automatic (any single transaction):**
  - CREATE → CALL
  - CREATE2 → CALL
  - CREATE → DELEGATECALL
  - TSTORE → CALL
  - SSTORE → CALL

## Preconditions

- Transaction-scoped execution
- Nested execution contexts / overlays
- Ability to inspect:
  - Code
  - Storage
  - Gas accounting
  - Frame hierarchy

## Core Invariants

### 1. Code Visibility Invariant

If code is written at address A at time T, then:
`GetCode(A)` MUST return non-empty for all execution frames at time > T within the same transaction.

**Violation ⇒ FAIL**

### 2. Overlay Inheritance Invariant

Every child execution frame must:

- Inherit parent overlay state
- Not fork from base/global snapshot
- Preserve:
  - Code hashes
  - Storage roots
  - Warm slot sets

**Unexpected divergence ⇒ FAIL**

### 3. Gas Propagation Sanity Check

For any CALL:

- If target address has non-empty code: Child execution must consume gas.
- If total gas charged equals base cost only (e.g., 2600): Flag as probable invisible execution.

This check is heuristic but high-confidence.

### 4. Write-Then-Read Consistency

Detect patterns:

- SetCode → GetCode
- SSTORE → SLOAD
- TSTORE → TLOAD

If a read does not observe a prior write within the same transaction, fail immediately.

## Output

### PASS

```json
{
  "status": "PASS",
  "frames_checked": 7,
  "mutations_verified": 14
}
```

### FAIL

```json
{
  "status": "FAIL",
  "failure_type": "state_overlay_inconsistency",
  "address": "0x05d4acfafec9c8ac000000000000000000000000",
  "symptoms": [
    "CALL charged base gas only",
    "child execution gas == 0",
    "deployed code invisible"
  ],
  "root_cause_hint": "Subcall created fresh overlay without inheriting parent state"
}
```

## Severity

- **Critical**
- Silent gas mis-accounting
- Invalid execution semantics
- Potential consensus divergence
- Auto-block recommended

## Integration

| Skill | Role |
|-------|------|
| **SKILL-007** | Requires invariants |
| **SKILL-017** | Detects stuck execution |
| **SKILL-018** | Hard pre-execution gate |
| **SKILL-019** | Red-team scenario gen |
| **SKILL-020** | Postmortem logging |

## Design Principle

State changes are meaningless unless they are observable.

### Origin

Derived from:  
**CS-001 — State Overlay Visibility Failure during CREATE2 → CALL execution.**

This skill exists to prevent gas-math patches that mask state-propagation bugs.
