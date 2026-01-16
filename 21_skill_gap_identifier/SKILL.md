---
name: Skill Gap Identifier
description: Analyzes failures or user requests to automatically scaffold new skills, ensuring structural evolution.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-021: Skill Gap Identifier

## Overview

A **meta-skill** for system evolution. It transforms "I wish I could do X" into a concrete plan for "Method X" by scaffolding the directory structure, metadata, and templates for a new skill. This ensures the system evolves structurally rather than relying on ad-hoc scripts.

## Trigger Phrases

- `create skill`
- `new capability`
- `missing tool`
- `scaffold skill`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--Name` | string | Yes | - | Short name (e.g., `log_parser`) |
| `--Trigger` | string | Yes | - | When should this run? |
| `--Description` | string | Yes | - | What does it do? |

## Outputs

### 1. New Directory Structure

```
skills/
  22_log_parser/
    SKILL.md      (Template)
    scripts/
    examples/
    templates/
```

### 2. JSON Status

```json
{
  "status": "CREATED",
  "id": "SKILL-22",
  "path": "C:\\...\\skills\\22_log_parser"
}
```

## Preconditions

1. `skills` root directory exists and is writable.
2. PowerShell 5.1+ or Core 7+.

## Safety/QA Checks

1. **Collision Detection**: Checks strict naming and ID availability.
2. **Sanitization**: Cleans directory names to be safe.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Name already exists | Fail or increment ID |

## Implementation

See `scripts/propose_skill.ps1`.

## Integration with Other Skills

1. **SKILL-020 (Postmortem)** identifies a gap.
2. User or Agent calls **SKILL-021** to fill it.
3. Agent then implements the logic in the new folder.
