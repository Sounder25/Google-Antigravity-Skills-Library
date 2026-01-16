---
name: Environment-Specific Bash Mastery
description: Generate optimized scripts that utilize the specific hardware (cores, GPU, OS) of the execution environment.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 4/5
---

# SKILL-013: Environment-Specific Bash Mastery

## Overview

Executes "Hardware-Aware Execution" by profiling the host machine (CPU cores, RAM availability, OS Version, GPU presence) to generate execution scripts that maximize performance. No more single-threaded scripts on a 12-core beast.

## Trigger Phrases

- `optimize script execution`
- `get system profile`
- `run with max performance`
- `generate hardware aware script`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--output-dir` | string | No | `.env` | Directory to save profile |

## Outputs

### 1. SYSTEM_PROFILE.json

Detailed hardware specs:
```json
{
  "os": "Microsoft Windows 10.0.22631",
  "cpu": {
    "name": "AMD Ryzen 9 7900X 12-Core Processor",
    "cores": 12,
    "logical_processors": 24
  },
  "memory": {
    "total_gb": 64,
    "free_gb": 32
  },
  "flags": {
    "has_cuda": true,
    "has_avx2": true,
    "is_wsl": false
  }
}
```

### 2. OPTIMIZED_FLAGS.env

Environment variables ready to be sourced:
```bash
export MAKE_JOBS=24
export OMP_NUM_THREADS=24
export NODE_OPTIONS="--max-old-space-size=60000"
export PYTHON_MULTIPROCESSING=1
```

## Preconditions

1. PowerShell access to WMI/CIM or system commands.

## Implementation

### Script: detect_env.ps1

1. **Queries WMI** (Win32_Processor, Win32_OperatingSystem) to get raw stats.
2. **Detects Capabilities:** Checks for `nvidia-smi` to infer CUDA.
3. **Calculates Optimal Settings:**
   - Compile Jobs (`-j`): Logical Cores.
   - Node Memory: 90% of Total RAM.
4. **Outputs JSON & ENV profiles.**

## Use Cases

1. **High Performance:** Writing a Python script that uses `multiprocessing` to crunch data, utilizing all 12 cores of "The Beast".
2. **System Hardening:** Generating backup scripts that know exactly which drive is the encrypted local backup based on volume labels.
