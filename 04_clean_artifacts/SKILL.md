---
name: Clean Build Artifacts
description: Removes ignored build artifacts (bin, obj, node_modules) to reclaim space and fix ghost build errors. Safely respects .gitignore.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-15
leverage_score: 4/5
---

# SKILL-004: Clean Build Artifacts

## Overview

Build artifacts can accumulate and cause subtle build errors or disk bloat. This skill "deep cleans" a workspace by removing generated folders that match standard patterns.

## Trigger Phrases

- `clean artifacts`
- `clean build`
- `wipe bin obj`
- `reset workspace`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--target` | string[] | No | `bin`,`obj`,`node_modules` | Folders to remove |
| `--dry-run` | switch | No | False | List what would be deleted |

## Outputs

1. Console log of deleted paths.
2. Space reclaimed summary.

## Safety/QA Checks

1. **Git Check:** Uses `git clean -fdX` if possible (safest).
2. **Explicit List:** If not git, only deletes explicit target list (`bin`, `obj`).
3. **No Source Code:** Never deletes `.cs`, `.py`, etc.

## Implementation

See `clean_artifacts.ps1`.
