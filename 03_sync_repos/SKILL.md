---
name: Sync Multi-Repo State
description: Detects drift between multiple git repositories (e.g. forks, mirrors, or multi-module projects). Generates a drift report and optionally applies sync actions.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-15
leverage_score: 4/5
---

# SKILL-003: Sync Multi-Repo State

## Overview

When working with split repositories (e.g., `Scrutor` and `Scrutor Test` having copies of `execution-specs`), state drift is a major risk. This skill analyzes multiple repos to report on ahead/behind commits, uncommitted changes, and branch divergence.

## Trigger Phrases

- `sync repos`
- `check repo drift`
- `compare repos`
- `multi-repo status`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--repos` | string[] | No | Auto-detect | List of repo paths to compare |
| `--reference` | string | No | First repo | The "source of truth" repo path |
| `--apply` | switch | No | False | **Unsafe:** Attempt to fast-forward/merge |

## Outputs

1. **Console Report:** Matrix of repo status.
2. **Markdown Report:** `REPO_SYNC_REPORT.md`.

## Preconditions

1. All targets must be valid git repositories.

## Safety/QA Checks

1. **Read-Only Default:** By default, only reports status.
2. **Safety Check:** `--apply` requires clean status in target repos.
3. **Backup:** `--apply` creates backup branch before merging.

## Implementation

See `sync_repos.ps1`.

## Integration

```powershell
.\skills\03_sync_repos\sync_repos.ps1 -Repos "C:\projects\Scrutor\execution-specs", "C:\projects\Scrutor Test\execution-specs"
```
