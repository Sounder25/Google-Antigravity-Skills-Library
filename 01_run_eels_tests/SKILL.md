---
name: Run EELS Test Suite
description: Automates running the Ethereum Execution Layer Specification (EELS) tests against a local EVM implementation. Handles venv setup, execution, and result parsing.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-15
leverage_score: 5/5
---

# SKILL-001: Run EELS Test Suite

## Overview

Automates the execution of EELS compliance tests. This skill handles the complexity of setting up the Python environment, installing dependencies, invoking `pytest` against a target EVM binary, and parsing the results into standardized reports.

## Trigger Phrases

- `run eels tests`
- `eels compliance check`
- `verify evm implementation`
- `run execution specs`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--evm-binary` | string | Yes | - | Path to the EVM executable (e.g., `ELR.CLI.exe`) |
| `--test-filter` | string | No | - | Optional pytest filter (e.g., `-k "add or sub"`) |
| `--specs-path` | string | No | Auto-detect | Path to `execution-specs` repo |
| `--output-dir` | string | No | `./.forensics` | Directory to save reports |
| `--json` | switch | No | False | Return raw JSON output only |

## Outputs

1. **Console Output:** Real-time test execution progress.
2. **Report File:** `EELS_TEST_RESULTS_<timestamp>.md` with pass/fail summary and details.
3. **JSON Results:** `eels_results.json` (if `--json` or requested).

## Preconditions

1. **SKILL-000** must have been run (checked via `WORKSPACE_PROFILE.json`).
2. `execution-specs` repo must exist (usually `C:\projects\Scrutor\execution-specs` or similar).
3. Python 3.10+ installed and accessible.
4. Target EVM binary must be built and executable.

## Safety/QA Checks

1. **Binary Verification:** Checks if `--evm-binary` exists and runs (version check).
2. **Repo State:** Checks if `execution-specs` is clean/valid.
3. **Venv Isolation:** Uses a local `.venv` to avoid system pollution.

## Implementation

See `run_eels_tests.ps1`.

## Integration

```powershell
# Example integration
.\skills\01_run_eels_tests\run_eels_tests.ps1 -EvmBinary ".\bin\Debug\net8.0\ELR.CLI.exe" -TestFilter "tests/shanghai/eip3855_push0"
```
