---
name: Detect Duplicate Files
description: Identify duplicate files across the workspace using SHA256 hashing to reduce redundancy and confusion.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 2/5
---

# SKILL-014: Detect Duplicate Files

## Overview

Scans the workspace for identical files (by content, not name) to detect redundancy, copy-paste errors, or accidental forks. Generates a report suggesting deduplication actions.

## Trigger Phrases

- `find duplicates`
- `check for duplicate files`
- `scan redundancy`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--workspace-path` | string | No | Current directory | Root to scan |
| `--min-size` | int | No | 0 | Minimum file size in bytes to check |
| `--exclude` | string[] | No | `node_modules`, `.git`, `bin`, `obj` | Directories to ignore |

## Outputs

### 1. DUPLICATE_REPORT.md

Summary of found duplicates:
```markdown
# Duplicate File Report

**Total Duplicates:** 12
**Wasted Space:** 4.5 MB

## Group 1 (Hash: a1b2...)
- `src/utils/math.ts` (Original?)
- `src/legacy/math_copy.ts`

## Group 2 (Hash: c3d4...)
- `config/settings.json`
- `deploy/settings.prod.json`
```

## Implementation

### Script: find_duplicates.ps1

1. recurses through directory (respecting excludes).
2. Calculates SHA256 hash of every file.
3. Groups by hash.
4. Filters groups with count < 2.
5. Generates Markdown report.

## Use Cases

1. **Cleanup:** Reducing repo size by removing accidental copies of large assets.
2. **Refactoring:** Finding code that was copy-pasted instead of shared.
