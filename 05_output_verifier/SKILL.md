---
name: Output Verifier
description: Performs final inspection by verifying that expected outputs and state changes actually occurred.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-03-25
leverage_score: 5/5
---

# SKILL-005: Output Verifier

## Overview

Enforces a final inspection step before declaring success. Verifies that expected files exist and contain required content, ensuring the real-world state matches the intended outcome.

## Trigger Phrases

- `verify output`
- `final inspection`
- `check results`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--ExpectedPresent` | string[] | No | - | Files or paths that must exist |
| `--ExpectedAbsent` | string[] | No | - | Files or paths that must not exist |
| `--ExpectedContains` | hashtable | No | - | Map of file path -> required substring |

## Outputs

JSON:

```json
{
  "status": "PASS",
  "checks": 3,
  "failures": []
}
```

## Preconditions

1. Read access to target paths.

## Implementation

See `scripts/verify_output.ps1`.

## Integration

```powershell
# Example: verify a file was created with expected content
.\skills\05_output_verifier\scripts\verify_output.ps1 -ExpectedPresent "output.txt" -ExpectedContains @{ "output.txt" = "Success" }
```




