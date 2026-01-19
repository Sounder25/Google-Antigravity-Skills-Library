![Antigravity Skills Library](Images/antigravity-banner.png)

# Antigravity Skills Library

A collection of **operational skills** for AI agents and automation systems.
Focused on deterministic execution, safety gates, adversarial review,
and structured learning from failure. This repository provides **capabilities**,
not autonomy, policy enforcement, or agent orchestration.

## 📦 Installation

This library is designed to live within the **Antigravity** configuration directory.

1. **Locate your specific installation directory:**

   ```bash
   ~/.gemini/antigravity/skills/
   ```

2. **Clone this repository:**

   ```bash
   cd ~/.gemini/antigravity/
   git clone https://github.com/Sounder25/Google-Antigravity-Skills-Library.git skills
   ```

3. **Verify:**
   Ensure the directory structure matches:
   `~/.gemini/antigravity/skills/00_workspace_forensics/SKILL.md`

## ⚙️ Prerequisites

**PowerShell 5.1+ or Core 7+** is required for the underlying automation scripts.

One-time setup for your PowerShell session:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
```

---

## 🛡️ Robustness & Safety (Gold Standard)

**Legend:** `✅ Verified` indicates the skill has passed deterministic tests
and is behavior-frozen for v1.0.0.

### 17. Impasse Detector (Self-Correction)

**Skill:** SKILL-017: Impasse Detector `✅ Verified`  
**Trigger:** `check logic`, `am i stuck`  
`detect_impasse.ps1` - Analyzes transcripts for unproductive loops.

### 18. Pre-Action Guard (QA Gate)

**Skill:** SKILL-018: Pre-Action Guard `✅ Verified`  
**Trigger:** `guard check`, `verify action`  
`guard_check.ps1` - Validates destructive actions against plan.

### 19. Adversarial Reviewer (Red Team)

**Skill:** SKILL-019: Adversarial Reviewer `✅ Verified`  
**Trigger:** `red team this`  
`prepare_review.ps1` - Generates "Attack" prompts for self-review.

### 20. Failure Postmortem (Learning)

**Skill:** SKILL-020: Failure Postmortem `✅ Verified`  
**Trigger:** `log failure`  
`log_failure.ps1` - Structured logging of why things broke.

### 21. Skill Gap Identifier (Evolution)

**Skill:** SKILL-021: Skill Gap Identifier `✅ Verified`  
**Trigger:** `new capability`  
`propose_skill.ps1` - Scaffolds new skills from failure data.

### 22. State Overlay Consistency Checker

**Skill:** SKILL-022: State Overlay Consistency Checker `✅ Verified`  
**Trigger:** `verify state continuity`  
Enforces state-visibility across execution contexts to prevent silent gas under-charging.

### 23. Paste Sanitizer

**Skill:** SKILL-023: Paste Sanitizer `✅ Verified`  
**Trigger:** `sanitize commands`  
Strips prompts/output from mixed snippets to ensure safe copy-pasting.

---

## 🧠 Cognitive Skills (Phase 2 - "Superpowers")

### 1. Auto-Recovery Loop (Self-Healing)

**Skill:** SKILL-006: Error-State Recovery  

### 2. Deterministic Planner (Architecture First)

**Skill:** SKILL-007: Deterministic Planner  

### 3. Context Pruner (Focus)

**Skill:** SKILL-008: Context Window Pruner  

### 4. Agent Swarm (Delegation)

**Skill:** SKILL-009: Agent-Swarm Spawner  

### 5. Async Feedback (Correction)

**Skill:** SKILL-010: Async Feedback Loop  

---

## 📚 Knowledge Skills (Phase 3)

### 11. Doc Parser (LLMs.txt)

**Skill:** SKILL-011: LLMs.txt Doc Parsing  

### 12. Dependency Mapper (Graph)

**Skill:** SKILL-012: Dependency Tree Mapping  

### 13. Environment Master (Context)

**Skill:** SKILL-013: Env Bash Mastery  

---

## 🛠️ Housekeeping Skills

| ID | Name | Description |
|----|------|-------------|
| **000** | Workspace Forensics | Gold Standard Audit. |
| **001** | Run EELS Tests | EVM Compliance. |
| **002** | Project Rename | Safe Rename. |
| **003** | Sync Repos | Multi-repo drift. |
| **004** | Clean Artifacts | Disk cleanup. |
| **005** | Update Breadcrumbs | Intent tracking. |
| **014** | Detect Duplicates | Finds duplicate files. |
| **015** | Generate Gitignore | Creates standard ignores. |

---

## 🔌 Integration

### MCP Connector

**Skill:** SKILL-016: MCP Connector  
`server.py` - Exposes this entire library as an MCP Server.
