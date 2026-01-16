---
name: Workspace Forensics Audit
description: Generate comprehensive workspace profile with git signals, build configs, and forensics completeness tracking. Foundation skill for all other workspace operations.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-15
leverage_score: 5/5
---

# SKILL-000: Workspace Forensics Audit

## Overview

**Foundation skill** that generates a complete workspace profile including git signals, build configurations, language detection, and forensics completeness tracking. All other skills should consume `WORKSPACE_PROFILE.json` or refuse to run without it.

## Trigger Phrases

- `audit workspace`
- `generate workspace profile`
- `forensics audit`
- `workspace scan`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--workspace-path` | string | No | Current directory | Path to workspace to audit |
| `--output-format` | string | No | `json` | Output format: `json`, `md`, or `both` |
| `--output-dir` | string | No | `./.forensics` | Directory to save outputs |
| `--verbose` | flag | No | false | Show detailed progress |

## Outputs

### 1. WORKSPACE_PROFILE.json

Complete workspace metadata in machine-readable format:

```json
{
  "workspace_name": "Scrutor",
  "absolute_path": "C:\\projects\\Scrutor",
  "audit_timestamp": "2026-01-15T20:55:00-06:00",
  "forensics_completeness": "full",
  "evidence_type": "repo_artifact",
  "collection_errors": [],
  
  "repo_type": "git",
  "git_signals": {
    "current_branch": "main",
    "status_clean": false,
    "changed_files_count": 642,
    "last_commit": {
      "hash": "8b693f4",
      "date": "2026-01-08T19:00:36-06:00",
      "message": "Cleanup lock naming, fix build warnings"
    },
    "commits_last_30_days": 15
  },
  
  "languages": ["C#/.NET"],
  "build_signals": {
    "solution_file": "Scrutor.sln",
    "project_files": ["Scrutor.Core.csproj", "Scrutor.RPC.csproj", "..."],
    "build_command": "dotnet build",
    "test_command": "dotnet test"
  },
  
  "intent_breadcrumbs": {
    "NEXT.md": {"exists": true, "last_modified": "2026-01-08"},
    "PLAN.md": {"exists": false},
    "STATE.json": {"exists": false}
  },
  
  "markers": {
    "TODO": 12,
    "FIXME": 3,
    "HACK": 1
  }
}
```

### 2. FORENSICS_SUMMARY.md

Human-readable summary with recommendations.

## Preconditions

1. Workspace path exists and is accessible
2. PowerShell 5.1+ or PowerShell Core 7+
3. Git installed (if analyzing git repo)

## Safety/QA Checks

1. **Path Validation** - Verify workspace path exists, check permissions
2. **Git Safety** - Only read operations, handle missing .git gracefully
3. **File System Safety** - Respect .gitignore, skip binaries, limit recursion

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Workspace path not found | **HALT** - Ask user for correct path |
| Permission denied | **HALT** - Ask user to grant access |
| Git command timeout | **WARN** - Mark git_signals as partial |

## Implementation

See `audit_workspace.ps1` in this directory.

## Integration with Other Skills

**All other skills should:**

1. Check for `WORKSPACE_PROFILE.json`
2. If not found, run SKILL-000 first
3. Consume profile data instead of re-discovering facts
4. Verify `forensics_completeness: full` before proceeding

## References

- Evidence collection: `workspace_forensics_2026-01-15/collect_evidence.ps1`
- Analysis: `workspace_forensics_2026-01-15/analyze_evidence.ps1`
- QA fixes: `workspace_forensics_2026-01-15/QA_FIXES_APPLIED.md`
