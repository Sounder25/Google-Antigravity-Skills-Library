---
name: Generate .gitignore
description: Create or update .gitignore files by fetching standard templates from the GitHub/gitignore repository.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 3/5
---

# SKILL-015: Generate .gitignore

## Overview

Ensures the workspace has a proper `.gitignore` file by fetching industry-standard templates (e.g., Python, Node, VisualStudio, macOS) and merging them. Prevents binary artifacts and secrets from being committed.

## Trigger Phrases

- `create gitignore`
- `update gitignore`
- `ignore build files`
- `add python to gitignore`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--workspace-path` | string | No | Current directory | Root to check |
| `--templates` | string[] | Yes | - | List of templates (e.g. `Python`, `Node`, `VisualStudio`) |
| `--append` | switch | No | false | If file exists, append instead of overwrite |

## Outputs

### 1. .gitignore

The resulting ignore file at the workspace root.

## Implementation

### Script: generate_gitignore.ps1

1. Validates input templates against GitHub/gitignore API or raw URLs.
2. Fetches content for each requested template.
3. Merges them.
4. Writes to `.gitignore`.

## Use Cases

1. **New Project:** Setting up a fresh repo for a combined C#/React project (`VisualStudio` + `Node`).
2. **Maintenance:** Realizing your Python project is committing `__pycache__` and fixing it instantly.
