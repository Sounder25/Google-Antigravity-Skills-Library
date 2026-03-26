---
title: Foundational Agent Skills
subtitle: The AI Agent Reliability Problem Was Solved in Manufacturing 40 Years Ago. We Just Haven’t Translated It Yet.
author: Erick (Sounder25 / Glock40ET)
date: March 2026
version: 1.0
keywords: [agent skills, trustworthy agents, meta-skills, deterministic execution, agent reliability, QMS, manufacturing process control]
abstract: |
  AI agents fail in production in predictable, preventable ways. The root causes are not insufficient model capability — they are the absence of a reliability architecture around the model. This white paper shows how the same reliability mechanisms that transformed high-consequence manufacturing 40 years ago directly map to AI agent execution. Foundational Agent Skills is the completed translation: a modular, .md-first library of 33 skills that enforce safety gates, state visibility, impasse detection, adversarial review, and structured learning from failure — before any higher-order capabilities are added.
---

# Foundational Agent Skills  
**The AI Agent Reliability Problem Was Solved in Manufacturing 40 Years Ago. We Just Haven’t Translated It Yet.**

**Subject:** AI Agent Reliability  
**Framework:** Foundational Agent Skills  
**License:** Apache 2.0  
**Repository:** https://github.com/Sounder25/Foundational-Agent-Skills  
**Skills:** 33 | **Gold Standard Verified:** 11

## I. The Problem with AI Agents in Production

AI agents fail in production in highly predictable ways. They enter unproductive loops. They retry failed actions indefinitely. They execute destructive commands without validating preconditions. They lose or corrupt context mid-task and continue from a corrupted state. They generate plausible but incorrect output and then build subsequent steps on top of that error.

These are not rare edge cases. They are systemic failure modes observed across codebases, frameworks, and model families. The core issue is not that today’s models lack capability. The core issue is that the **execution environment** surrounding the model has no reliability architecture.

Most agent implementations still lack even basic equivalents of:

- A deterministic gate that verifies preconditions before any destructive or irreversible action
- A mechanism that detects when the agent is stuck in an unproductive loop
- A structured process for capturing and learning from every failure event
- An adversarial review step that proactively stress-tests the agent’s own plan

This is not a model problem. It is an **architecture problem**. And the architecture already exists — it was perfected decades ago in manufacturing.

## II. What Manufacturing Already Solved

High-consequence manufacturing environments faced an identical challenge: defects that reach the end of the line are orders of magnitude more expensive than defects caught at the source. The solution was the modern Quality Management System (QMS) built around a small set of rigorous, repeatable mechanisms:

- **Non-Conformance Reports (NCRs)** — Immediate, structured documentation of every failure event, including downstream impact and containment actions.
- **Root Cause Analysis (RCA)** — Mandatory investigation that continues until the true root cause is identified (using 5 Whys, Fishbone, etc.), never stopping at the first plausible explanation.
- **Pre-Process Inspection Gates** — Mandatory verification that all preconditions are met before any irreversible or destructive step proceeds.
- **Impasse / Escalation Detection** — Recognition that repeating a failing process is itself a failure mode, triggering escalation rather than continued cycling.
- **Structured Postmortem & Corrective Action** — Not just “what broke,” but “why the existing system failed to prevent it,” followed by specific, trackable improvements.

These mechanisms turned chaotic production lines into reliable, scalable systems. They are not theoretical — they are operational standards that run daily in aerospace, automotive, pharmaceuticals, and semiconductor manufacturing.

## III. The Translation: QMS → AI Agent Reliability

**Foundational Agent Skills** is the direct, practical translation of these proven manufacturing mechanisms into the AI agent execution layer.

Each skill maps one-to-one with a documented agent failure mode:

| QMS Concept                        | AI Agent Failure Mode                              | Foundational Agent Skill                          |
|------------------------------------|----------------------------------------------------|---------------------------------------------------|
| Non-Conformance Report             | Agent fails silently with no structured record     | SKILL-004: Failure Postmortem                     |
| Root Cause Analysis                | Agent stops at first plausible answer              | SKILL-003: Adversarial Reviewer                   |
| Pre-Process Inspection Gate        | Destructive action executed without validation     | SKILL-002: Pre-Action Guard                       |
| Impasse / Escalation Detection     | Agent loops indefinitely on a failing approach     | SKILL-001: Impasse Detector                       |
| Skill / Capability Gap             | Team lacks tool to prevent a known failure class   | SKILL-024: Skill Gap Identifier                   |
| State Audit / Workspace Forensics  | Agent operates on corrupted or stale state         | SKILL-008: Workspace Forensics                    |
| Process Standardization            | Inconsistent execution across agents or sessions   | SKILL-014: Deterministic Planner                  |
| Context Management                 | Agent loses critical context mid-task              | SKILL-015: Context Window Pruner                  |

The mapping is not metaphorical.  
The **Pre-Action Guard** performs exactly the same function as a machining setup verification: it blocks the irreversible step until preconditions are confirmed.  
The **Impasse Detector** performs exactly the same function as an escalation threshold on a production line: it recognizes repeated failure and interrupts the loop.

## IV. Framework Design Principles

Three deliberate design decisions set this library apart from typical ad-hoc prompt collections:

1. **Deterministic Over Probabilistic**  
   Safety rules are not suggestions left to model judgment. Each Gold Standard skill defines explicit triggers and required outputs. If an action is destructive, the Pre-Action Guard runs — no exceptions. This mirrors how manufacturing gates are non-optional.

2. **Framework-Agnostic by Design (.md-first)**  
   Every skill is a self-contained folder centered on a clear, human-readable `SKILL.md` file. Any agent that can read Markdown from a directory can use the library without modification (Gemini/Antigravity, Claude, Cursor, custom agents, etc.). The MCP connector further exposes the entire library as a deterministic service.

3. **Failure as Structured Data**  
   Every failure event is captured by the Failure Postmortem and fed into the Skill Gap Identifier. The output is not just a log — it is a candidate for a new skill. The library evolves through documented failure history, exactly as QMS drives continuous improvement.

The library does not attempt to make agents “smarter.” It makes the environment around them **more disciplined**.

## Gold Standard Skills (v1)

The Gold Standard set is the minimum reliability core modeled after QMS gates. These eleven skills are deterministic, test-backed, and non-optional when applicable:

1. **SKILL-001: Impasse Detector** — loop detection / escalation threshold
2. **SKILL-002: Pre-Action Guard** — destructive action inspection gate
3. **SKILL-003: Adversarial Reviewer** — plan stress-testing / RCA trigger
4. **SKILL-004: Failure Postmortem** — failure memory (NCR)
5. **SKILL-005: Output Verifier** — final inspection / postcondition check
6. **SKILL-006: Assumption Auditor** — FMEA-style pre-execution checklist
7. **SKILL-007: Scope Guard** — containment action / scope drift prevention
8. **SKILL-027: Rollback Planner** — reversible execution gate
9. **SKILL-028: Hallucination Detector** — claim validity gate
10. **SKILL-031: Dependency Validator** — pre-run readiness gate
11. **SKILL-033: Semantic Diff** — intent completeness gate

## V. Getting Started

The library is open source under Apache 2.0 and designed for immediate drop-in use.

### Installation
```bash
mkdir -p ~/.gemini/antigravity/skills
cd ~/.gemini/antigravity/skills
git clone https://github.com/Sounder25/Foundational-Agent-Skills.git .    



