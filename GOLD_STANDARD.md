# Gold Standard Skills (v1)

This document defines the seven foundational, QMS-aligned reliability gates that form the Gold Standard set.

## Definition

Gold Standard skills are deterministic, test-backed, and non-optional when applicable. They enforce safety gates before, during, and after execution and create auditable proof of correct behavior.

## The Gold Standard Set (11)

1. **SKILL-001: Impasse Detector** — loop detection / escalation threshold
2. **SKILL-002: Pre-Action Guard** — destructive action inspection gate
3. **SKILL-003: Adversarial Reviewer** — plan stress-testing / RCA trigger
4. **SKILL-004: Failure Postmortem** — failure memory (NCR)
5. **SKILL-005: Output Verifier** — final inspection / postcondition check
6. **SKILL-006: Assumption Auditor** — FMEA-style pre-execution checklist
7. **SKILL-007: Scope Guard** — containment action / scope drift prevention
8. **SKILL-027: Rollback Planner** — reversible execution gate
9. **SKILL-028: Hallucination Detector** — claim validity gate
10. **SKILL-031: Dependency Validator** — pre-run readiness gate
11. **SKILL-033: Semantic Diff** — intent completeness gate

## Evidence

Each skill is verified via deterministic tests. See `VERIFICATION_SUMMARY.md` and the per-skill `VERIFICATION_REPORT.md` files.



