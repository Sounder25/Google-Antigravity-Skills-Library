---
name: Project-Wide Rename
description: Safely renames a .NET project (solution, projects, namespaces, directories) from one name to another. Supports Planned (clean) and Recovery (dirty) modes.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-15
leverage_score: 5/5
---

# SKILL-002: Project-Wide Rename

## Overview

Renaming a complex .NET solution is error-prone. This skill automates the process of renaming files, directories, text content, and git configuration, with safety mechanisms to prevent data loss.

## Trigger Phrases

- `rename project <old> <new>`
- `safe rename <old> to <new>`
- `fix pending rename`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--old-name` | string | Yes | - | Original project name (e.g., "Scrutor") |
| `--new-name` | string | Yes | - | New project name (e.g., "ELR") |
| `--mode` | string | No | `auto` | `planned`, `recovery`, or `auto` |
| `--dry-run` | switch | No | False | Preview changes (mandatory if dirty) |

## Modes

1. **Planned Mode**: Requires a clean git status. Best for starting a rename operation from scratch.
2. **Recovery Mode**: Allows dirty git status. Best for finishing a partial rename or cleaning up a manual attempt.

## Outputs

1. **Console Output**: Progress log of renamed files and updated content.
2. **Report**: `RENAME_SUMMARY.md` with list of changes.
3. **Git Branch**: `rename-<old>-to-<new>` containing the changes.

## Preconditions

1. Git repository root.
2. .NET SDK installed (for build verification).
3. Permissions to modify all files.

## Safety/QA Checks

1. **Exclusions**: Ignores `bin`, `obj`, `.git`, `node_modules`.
2. **Build Check**: optional verification build after rename.
3. **Rollback**: Ability to `git reset --hard` if something goes wrong.

## Implementation

See `rename_project.ps1`.

## Integration

```powershell
# Example
.\skills\02_project_rename\rename_project.ps1 -OldName "Scrutor" -NewName "ELR" -DryRun
```
