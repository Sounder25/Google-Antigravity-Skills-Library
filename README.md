![Foundational Agent Skills](Images/antigravity-banner.png)

![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)
![CI](https://github.com/Sounder25/Foundational-Agent-Skills/actions/workflows/powershell-ci.yml/badge.svg)
![Gold Standard](https://img.shields.io/badge/Gold%20Standard-11-success)
![Skills](https://img.shields.io/badge/Skills-33-blue)

# Foundational Agent Skills

**Operational capabilities for high-leverage AI coding agents.**

A modular, **.md-first** library of 33 foundational skills designed to make AI agents reliable, observable, deterministic, and self-improving. 

Born from real-world friction in a complex production project, this collection prioritizes **safety gates**, **state visibility**, **impasse detection**, **adversarial review**, and **structured learning from failure** — *before* layering on higher-order capabilities.

It provides **capabilities**, not full autonomy, policy enforcement, or agent orchestration.

**Gold Standard (11):** A core reliability gate set verified across deterministic tests and live LLM runs.

Read the white paper: `ENGINEERING_WHITE_PAPER.md`

## Quick Start

```powershell
# Run deterministic verification
powershell -NoProfile -ExecutionPolicy Bypass -File "Publish-Results.ps1"

# Run a live LLM gate scenario (requires Ollama + qwen2.5:7b)
powershell -NoProfile -ExecutionPolicy Bypass -File "E2E_Evaluations\Live_Harness.ps1" -ScenarioPath "E2E_Evaluations\Live_Scenarios\03_output_verifier.json" -Model "qwen2.5:7b"
```

## Verification

- Publishable proof: `PUBLISHABLE_PROOF.md`
- Phase 2 evidence: `PHASE2_PROOF.md`
- Gold Standard set: `GOLD_STANDARD.md`
- Deterministic summary: `VERIFICATION_SUMMARY.md`

## Why Foundational Agent Skills?

In the rush to build powerful agents, most skill collections jump straight to flashy features. This library does the opposite: it enforces a **proper foundation** first — exactly as rigorous process evaluation (Lean, Six Sigma, fault-tree analysis) demands in traditional engineering.

Every skill lives in its own self-contained folder with a clear `SKILL.md` (natural-language instructions and triggers) plus supporting scripts. This design makes the library transparent, auditable, and easy to extend or port to other agent frameworks via the MCP connector.

---

## 📦 Installation

1. **Create or navigate to the skills directory:**
   ```bash
   mkdir -p ~/.gemini/antigravity/skills
   cd ~/.gemini/antigravity/skills

---

## 🔌 Integration

### MCP Connector

**Skill:** SKILL-023: MCP Connector  
`server.py` - Exposes this entire library as an MCP Server.



