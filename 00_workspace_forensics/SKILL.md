---
name: workspace-forensics-audit
description: "Generate a comprehensive workspace profile with git signals, build configs, language detection, and forensics completeness tracking. Foundation skill that produces WORKSPACE_PROFILE.json consumed by all other skills. Use when starting work in a new repository, onboarding to an unfamiliar codebase, or any skill requires workspace context before execution."
metadata:
  version: 1.0.0
  author: Antigravity Skills Library
  created: 2026-01-15
  leverage_score: 5/5
---

# Workspace Forensics Audit

Foundation skill that generates a complete workspace profile. All other skills consume `WORKSPACE_PROFILE.json` — run this first.

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

## Workflow

1. **Validate** the workspace path exists and is accessible.
2. **Detect** repository type (git, svn, or none) and collect VCS signals.
3. **Scan** for build configs, language markers, and project files.
4. **Collect** intent breadcrumbs (NEXT.md, PLAN.md, STATE.json).
5. **Count** code markers (TODO, FIXME, HACK).
6. **Write** `WORKSPACE_PROFILE.json` and optionally `FORENSICS_SUMMARY.md`.

## Outputs

### WORKSPACE_PROFILE.json

```json
{
  "workspace_name": "Scrutor",
  "absolute_path": "C:\\projects\\Scrutor",
  "audit_timestamp": "2026-01-15T20:55:00-06:00",
  "forensics_completeness": "full",
  "repo_type": "git",
  "git_signals": {
    "current_branch": "main",
    "status_clean": false,
    "changed_files_count": 642,
    "last_commit": { "hash": "8b693f4", "date": "2026-01-08", "message": "Cleanup lock naming" },
    "commits_last_30_days": 15
  },
  "languages": ["C#/.NET"],
  "build_signals": {
    "solution_file": "Scrutor.sln",
    "build_command": "dotnet build",
    "test_command": "dotnet test"
  },
  "intent_breadcrumbs": {
    "NEXT.md": { "exists": true, "last_modified": "2026-01-08" },
    "PLAN.md": { "exists": false }
  },
  "markers": { "TODO": 12, "FIXME": 3, "HACK": 1 }
}
```

### FORENSICS_SUMMARY.md

Human-readable summary with recommendations for next steps.

## Preconditions

1. Workspace path exists and is accessible.
2. PowerShell 5.1+ or PowerShell Core 7+.
3. Git installed (if analyzing a git repo).

## Safety/QA Checks

- **Read-only** — no files are modified in the target workspace.
- **Respects .gitignore** — skips ignored paths and binaries.
- **Handles missing .git gracefully** — marks git_signals as unavailable.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| Workspace path not found | **HALT** — ask user for correct path |
| Permission denied | **HALT** — ask user to grant access |
| Git command timeout | **WARN** — mark git_signals as partial |

## Implementation

See `audit_workspace.ps1` in this directory.

## Integration with Other Skills

All skills should check for `WORKSPACE_PROFILE.json` and run this skill first if missing. Verify `forensics_completeness: full` before proceeding.

## References

- Evidence collection: `workspace_forensics_2026-01-15/collect_evidence.ps1`
- Analysis: `workspace_forensics_2026-01-15/analyze_evidence.ps1`
