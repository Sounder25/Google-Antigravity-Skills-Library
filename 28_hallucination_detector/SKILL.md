---
name: Hallucination Detector
description: Identifies confident, specific, unverifiable claims in agent output before those claims become the foundation for subsequent actions.
version: 1.0.0
author: Foundational Agent Skills
created: 2026-03-25
leverage_score: 5/5
gold_standard: true
---

# SKILL-028: Hallucination Detector

## Overview

Catches the failure mode where the agent produces **confident, specific, factually unverifiable claims** and subsequent steps are built on top of them. The danger is not vague output — vague output is caught by other skills. The danger is output that is specific and sounds authoritative but is fabricated or unverified: exact API parameters, version numbers, file paths, function signatures, configuration values.

QMS equivalent: Material Traceability. Every component must have a verified source. A part with no traceable provenance does not go into the assembly, regardless of how correct it looks.

## Trigger Phrases

- `fact check this`
- `verify claims`
- `hallucination check`
- `source check`
- `is this real`

## Automatic Trigger

Activates when agent output contains:
- Specific version numbers (e.g. `v2.3.1`)
- Exact API endpoint paths or parameter names
- File paths stated as confirmed existing
- Function signatures or method names presented as correct
- Numerical data (counts, percentages, dates) without cited source
- Quotes or documentation references stated as verbatim

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Content` | string | Yes | - | The agent output to analyze |
| `--Domain` | string | No | `General` | Context domain: `Code`, `Data`, `Documentation`, `General` |
| `--Threshold` | float | No | 0.7 | Confidence threshold below which claims are flagged |

## Outputs

### 1. Claim Analysis (JSON)

```json
{
  "hallucination_risk": "HIGH",
  "flagged_claims": [
    {
      "claim": "The requests library uses `verify_ssl=False` as the parameter name",
      "type": "API_parameter",
      "verifiable": false,
      "confidence": 0.3,
      "risk": "HIGH",
      "required_action": "Check official requests documentation before using"
    },
    {
      "claim": "This function was deprecated in version 3.9",
      "type": "version_reference",
      "verifiable": false,
      "confidence": 0.4,
      "risk": "MEDIUM",
      "required_action": "Verify against changelog"
    }
  ],
  "safe_to_proceed": false,
  "recommendation": "Verify flagged claims against authoritative source before building on this output"
}
```

### 2. Risk Levels

- `LOW`: Claims are general, verifiable from context, or explicitly hedged.
- `MEDIUM`: Some specific claims present, verifiability unclear.
- `HIGH`: Specific technical claims with no verifiable source. Do not build on this output.
- `CRITICAL`: Fabricated references, nonexistent APIs, or invented documentation detected.

## Preconditions

1. Agent has produced output containing specific factual claims.
2. Those claims are candidates for use in subsequent steps.

## Safety/QA Checks

1. **Build Block**: If risk is `HIGH` or `CRITICAL`, the agent cannot use these claims as inputs to subsequent steps until verified.
2. **Hedge Enforcement**: Agent must explicitly qualify unverified specific claims before surfacing them to the user.
3. **No Chain Building**: A hallucinated claim that passes undetected and becomes the foundation for the next step multiplies the error. This skill breaks that chain.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| HIGH risk claims detected | Block use in subsequent steps, surface to user |
| CRITICAL risk detected | Halt, flag entire output as unreliable |
| Unverifiable technical specifics | Require external verification before proceeding |

## Implementation

See `scripts/detect_hallucination.ps1`.

## Integration with Other Skills

1. Runs after any agent output that will be used as input to the next step.
2. HIGH risk output → **SKILL-003 (Adversarial Reviewer)** to stress-test the claims.
3. If fabricated source detected → **SKILL-004 (Failure Postmortem)** to record the failure pattern.
4. Pairs with **SKILL-006 (Assumption Auditor)** — unverified assumptions and hallucinated facts are the same failure class at different points in the task.




