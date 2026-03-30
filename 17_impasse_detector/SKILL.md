---
name: impasse-detector
description: "Detect when an agent is stuck in a reasoning loop or unproductive state by analyzing conversation history, tool-usage patterns, and sentiment signals. Returns a confidence-scored status with escalation recommendations. Use when an agent loop exceeds expected turns, token usage spikes without progress, or any workflow needs a circuit breaker against stuck states."
metadata:
  version: 1.0.0
  author: Antigravity Skills Library
  created: 2026-01-16
  leverage_score: 5/5
---

# Impasse Detector

Meta-cognitive circuit breaker that analyzes recent conversation history and tool outputs to detect stuck states, preventing token waste and forcing escalation or delegation.

## Trigger Phrases

- `check logic`
- `am i stuck`
- `detect loop`
- `impasse check`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--TranscriptPath` | string | No | — | Path to conversation log (JSON) |
| `--Content` | string | No | — | Direct string content to analyze |
| `--Lookback` | int | No | 10 | Number of recent turns to analyze |

## Workflow

1. **Load** transcript from `--TranscriptPath` or `--Content` (at least one required). **Validate** the input is parseable JSON or non-empty text before proceeding.
2. **Window** the last `--Lookback` turns.
3. **Scan** for loop indicators using these heuristics:
   - **Apology loop**: 3+ occurrences of "sorry", "I apologize", "let me try again" in the window.
   - **Tool repetition**: same tool called 4+ times with identical arguments.
   - **Oscillation**: output alternates between two states (e.g., create/delete cycle).
   - **No-progress**: token count increases but no new files written or tests passed.
4. **Score** impasse confidence (0–100) — each matched heuristic adds 20–30 points; cap at 100.
5. **Verify** score is consistent: if only one weak signal, cap confidence at 50.
6. **Return** structured JSON with status, reasons, and recommendation.

## Outputs

```json
{
  "status": "IMPASSE",
  "confidence": 0.95,
  "reasons": [
    "Apology loop detected (4 occurrences)",
    "High frequency of file reads (6 in window)"
  ],
  "recommendation": "ESCALATE_TO_USER",
  "score": 80
}
```

### Status Codes

| Status | Meaning |
|--------|---------|
| `CLEAR` | No issues detected |
| `IMPASSE` | Significant loop or blockage detected |
| `UNKNOWN` | Insufficient data to evaluate |

## Preconditions

1. Access to conversation history or a provided transcript string.
2. PowerShell 5.1+ or Core 7+.

## Safety/QA Checks

- **Read-only** — analyzes text only; never modifies state.
- **Fail-safe** — returns `UNKNOWN` (0 confidence) if input is missing or malformed.

## Stop Conditions

| Condition | Action |
|-----------|--------|
| No input provided | Return status `UNKNOWN` (0 confidence) |
| File not found | Return error JSON |

## Implementation

Core detection logic (see `scripts/detect_impasse.ps1` for full implementation):

```powershell
# Pseudocode: count loop indicators in the lookback window
$apologies = ($window | Select-String -Pattern "sorry|apologize|let me try again").Count
$repeatedTools = ($window | Group-Object ToolCall | Where-Object { $_.Count -ge 4 }).Count
$score = ($apologies * 25) + ($repeatedTools * 30)
$status = if ($score -ge 60) { "IMPASSE" } elseif ($score -gt 0) { "CLEAR" } else { "UNKNOWN" }
```

## Integration with Other Skills

Call this skill every 5–10 turns in any agent loop:
- If `IMPASSE` → trigger **Failure Postmortem (Skill-020)** and **Async Feedback (Skill-010)**.
- If `score > 90` → halt execution and warn the user.
