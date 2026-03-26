# Foundational Agent Skills - Verification Proof (Publishable)

## Tier 1 - Deterministic Skill Verification

Status: completed for all foundational skills except EELS (removed from scope).

Evidence:
- VERIFICATION_SUMMARY.md (global deterministic report)
- Per-skill VERIFICATION_REPORT.md in each skill folder

## Tier 2 - Orchestration Verification

Status: partially demonstrated or pending.
Notes: Environment/runtime orchestration validation belongs in this tier.

Live LLM Harness:
- E2E_Evaluations\Live_Harness.ps1
- E2E_Evaluations\Live_Scenarios\*.json

Validated gates in Tier 2:
- Pre-Action Guard (block destructive)
- Output Verifier
- Hallucination Detector
- Dependency Validator
- Semantic Diff
- Rollback Planner

Example runs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "E2E_Evaluations\Live_Harness.ps1" -ScenarioPath "E2E_Evaluations\Live_Scenarios\01_create_file.json" -Model "qwen2.5:7b"
powershell -NoProfile -ExecutionPolicy Bypass -File "E2E_Evaluations\Live_Harness.ps1" -ScenarioPath "E2E_Evaluations\Live_Scenarios\02_block_destructive.json" -Model "qwen2.5:7b"
```

Logs: E2E_Evaluations\live_harness_*.log

## Tier 3 - Full Autonomous Production Validation

Status: future work / next phase.

## How to Reproduce Tier 1

Run from repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "Publish-Results.ps1"
```

This regenerates VERIFICATION_SUMMARY.md and each skill's VERIFICATION_REPORT.md.
