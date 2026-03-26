# Foundational Agent Skills â€” Verification & Empirical Results
**Generated:** 2026-03-26 01:19:32
**Framework:** Foundational Agent Skills v1.0
**Repository:** https://github.com/Sounder25/Foundational-Agent-Skills
**License:** Apache 2.0

> This document provides deterministic and empirical proof that the QMS-inspired
> execution gates described in the Foundational Agent Skills white paper
> function as specified. Each skill is tested with automated assertions.
> E2E tests use a live local LLM (Ollama + Qwen 2.5 7B) to validate that
> the gates constrain non-deterministic model behavior in real time.

---

# Part 1: Deterministic Script Verification

Each test below runs the skill's PowerShell script with controlled inputs
and asserts that the outputs match the specification. No LLM is involved.

# ðŸ§ª Verification Report: SKILL-001 (Impasse Detector)
**Date:** 03/26/2026 01:19:32
**Quality Gate:** 100% Pass Required

## Test Cases

### 1. Clean Path
**Input:** Simple conversation.
**Expected:** CLEAR
**Actual:** CLEAR
**Pass:** âœ…

### 2. Mild Loop (Below Threshold)
**Input:** 3 apologies.
**Expected:** CLEAR (Score 40)
**Actual:** CLEAR (Score 40)
**Pass:** âœ…

### 3. Severe Impasse (Critical)
**Input:** 5 apologies, 5 retries.
**Expected:** IMPASSE (Score 100)
**Actual:** IMPASSE (Score 100)
**Pass:** âœ…

## Final Verdict
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-002 (Pre-Action Guard)
**Date:** 03/26/2026 01:19:32

## Test Cases

### 1. Safe Read
**Input:** view_file SKILL.md
**Expected:** NONE / Allowed
**Actual:** NONE / True
**Pass:** âœ…

### 2. Config Write
**Input:** write_to_file .env
**Expected:** HIGH / Allowed
**Actual:** HIGH / True
**Pass:** âœ…

### 3. Focused Delete (Allowed with Warning)
**Input:** rm ./temp.txt
**Expected:** CRITICAL / Allowed
**Actual:** CRITICAL / True
**Pass:** âœ…

### 4. Root Delete (Block)
**Input:** rm C:\
**Expected:** CRITICAL / Blocked
**Actual:** CRITICAL / False
**Pass:** âœ…

### 5. rmdir Variant (LLM-generated)
**Input:** rmdir /s /q C:\
**Expected:** CRITICAL / Blocked
**Actual:** CRITICAL / False
**Pass:** âœ…

### 6. JSON-Escaped Backslash Variant
**Input:** del /f /s /q C:\\\\*
**Expected:** CRITICAL / Blocked
**Actual:** CRITICAL / False
**Pass:** âœ…

### 7. System Path (Windows\System32)
**Input:** del C:\Windows\System32\config
**Expected:** CRITICAL / Blocked
**Actual:** CRITICAL / False
**Pass:** âœ…

### 8. Command Chaining Attack
**Input:** echo ok && rm -rf /
**Expected:** CRITICAL / Blocked
**Actual:** CRITICAL / False
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-003 (Adversarial Reviewer)
**Date:** 03/26/2026 01:19:33

## Test Cases

### 1. Security Mode
**Input:** code_stub.cs (Security)
**Expected:** Prompt containing 'Injection/Sanitization'
**Actual:** Found Keywords
**Pass:** âœ…

### 2. Performance Mode
**Input:** code_stub.cs (Performance)
**Expected:** Prompt containing 'Blocking I/O'
**Actual:** Found Keywords
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-004 (Failure Postmortem)
**Date:** 03/26/2026 01:19:33

## Test Cases

### 1. Log Creation & Append
**Input:** Log a simulated error.
**Expected:** File grows, content contains error.
**Actual:** File Exists: True, Status: LOGGED, Appended: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-005 (Output Verifier)
**Date:** 03/26/2026 01:19:33

## Test Cases

### 1. Final Inspection Pass
**Input:** Present file + absent file + content match.
**Expected:** PASS
**Actual:** Status: PASS
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-006 (Assumption Auditor)
**Date:** 03/26/2026 01:19:33

## Test Cases

### 1. Flags Unverified Assumptions
**Input:** 3 assumptions, 1 verified.
**Expected:** WARN with 2 unverified.
**Actual:** Status: WARN, Unverified: 2
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-007 (Scope Guard)
**Date:** 03/26/2026 01:19:33

## Test Cases

### 1. Detects Out-of-Scope Paths
**Input:** One in-scope, one out-of-scope path.
**Expected:** FAIL with 1 out_of_scope.
**Actual:** Status: FAIL, Out: 1
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-008 (Workspace Forensics)
**Date:** 03/26/2026 01:19:33

## Test Cases

### 1. JSON Output Created
**Input:** Audit skills repo with JSON output.
**Expected:** WORKSPACE_PROFILE.json exists.
**Actual:** Exists: True
**Pass:** âœ…

### 2. Forensics Completeness
**Input:** Git repo with full signals.
**Expected:** forensics_completeness == "full"
**Actual:** full
**Pass:** âœ…

### 3. Repo Type Detection
**Input:** Directory with .git folder.
**Expected:** repo_type == "git"
**Actual:** git
**Pass:** âœ…

### 4. No Crash on Profile Generation
**Input:** Full audit run.
**Expected:** Profile object is not null.
**Actual:** Not null: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-009 (Project-Wide Rename)
**Date:** 03/26/2026 01:19:34

## Test Cases

### 1. DryRun Generates Summary
**Input:** -Mode recovery -DryRun in a git repo with matching names.
**Expected:** RENAME_SUMMARY.md exists.
**Actual:** Exists: True
**Pass:** âœ…

### 2. DryRun Flags Recorded
**Input:** Summary content.
**Expected:** "DryRun: True" in report.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-010 (Sync Multi-Repo State)
**Date:** 03/26/2026 01:19:35

## Test Cases

### 1. Report Created
**Input:** Two git repos with commits.
**Expected:** REPO_SYNC_REPORT.md exists.
**Actual:** Exists: True
**Pass:** âœ…

### 2. Repo Names Included
**Input:** Report content.
**Expected:** repo_a and repo_b listed.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-011 (Clean Artifacts)
**Date:** 03/26/2026 01:19:36

## Test Cases

### 1. DryRun Preserves Directories
**Input:** Directory with bin/ and obj/, -DryRun flag.
**Expected:** Directories still exist after DryRun.
**Actual:** Preserved: True
**Pass:** âœ…

### 2. Force Delete
**Input:** Same directory, -Force flag.
**Expected:** bin/ and obj/ removed.
**Actual:** bin gone: True, obj gone: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-012 (Update Intent Breadcrumbs)
**Date:** 03/26/2026 01:19:36

## Test Cases

### 1. STATE.json Created
**Input:** Run with status/objective/steps.
**Expected:** STATE.json exists.
**Actual:** Exists: True
**Pass:** âœ…

### 2. NEXT.md Created
**Input:** Run with template.
**Expected:** NEXT.md exists.
**Actual:** Exists: True
**Pass:** âœ…

### 3. Objective Captured
**Input:** STATE.json content.
**Expected:** Objective string present.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-013 (Error-State Recovery)
**Date:** 03/26/2026 01:19:37

## Test Cases

### 1. Auto-Fix Missing Directory
**Input:** Set-Content to a missing directory.
**Expected:** Directory created and file written.
**Actual:** File exists: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-014 (Deterministic Planner)
**Date:** 03/26/2026 01:19:37

## Test Cases

### 1. Plan File Created
**Input:** init_plan.ps1 -Objective "Automated Test Objective"
**Expected:** PLAN.json exists.
**Actual:** Exists: True
**Pass:** âœ…

### 2. Valid JSON
**Input:** Parse PLAN.json.
**Expected:** No parse errors.
**Actual:** Valid: True
**Pass:** âœ…

### 3. Contains Objective
**Input:** Search for objective string.
**Expected:** "Automated Test Objective" present.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-015 (Context Pruner)
**Date:** 03/26/2026 01:19:37

## Test Cases

### 1. No Crash
**Input:** prune_context.ps1 -Focus "guard"
**Expected:** Exit without error.
**Actual:** Error: False
**Pass:** âœ…

### 2. Output File Created
**Input:** Check for RELEVANT_FILES.txt.
**Expected:** File exists.
**Actual:** Exists: True
**Pass:** âœ…

### 3. Contains Relevant Match
**Input:** Search output for "guard".
**Expected:** guard_check.ps1 or similar found.
**Actual:** Match: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-016 (Agent-Swarm Spawner)
**Date:** 03/26/2026 01:19:37

## Test Cases

### 1. Mission Created
**Input:** Task name + instructions.
**Expected:** MISSION.md exists in swarm dir.
**Actual:** Exists: True
**Pass:** âœ…

### 2. Mission Content
**Input:** MISSION.md content.
**Expected:** Instructions and Skills Manifest present.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-017 (Async Feedback Loop)
**Date:** 03/26/2026 01:19:37

## Test Cases

### 1. Feedback Channel Created
**Input:** Run when FEEDBACK.md missing.
**Expected:** FEEDBACK.md created.
**Actual:** Exists: True
**Pass:** âœ…

### 2. Acknowledge Marks Read
**Input:** FEEDBACK.md with content + -Acknowledge.
**Expected:** ACKNOWLEDGED marker appended.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-018 (llms.txt & Doc Parsing)
**Date:** 03/26/2026 01:19:38

## Test Cases

### 1. Consolidated File Created
**Input:** Local llms.txt server.
**Expected:** CONSOLIDATED_KNOWLEDGE.md exists.
**Actual:** Exists: True
**Pass:** âœ…

### 2. Linked Docs Included
**Input:** Consolidated content.
**Expected:** Doc One and Doc Two included.
**Actual:** Found: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-019 (Dependency Tree Mapping)
**Date:** 03/26/2026 01:19:39

## Test Cases

### 1. No Crash
**Input:** map_dependencies.ps1 on a Node.js project.
**Expected:** Exit without error.
**Actual:** Error: False
**Pass:** âœ…

### 2. Mermaid Graph Created
**Input:** Check for DEPENDENCY_GRAPH.mmd.
**Expected:** File exists.
**Actual:** Exists: True
**Pass:** âœ…

### 3. Graph Contains Dependencies
**Input:** Search graph for "lodash" and "express".
**Expected:** Both present.
**Actual:** lodash: True, express: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-020 (Environment Detection)
**Date:** 03/26/2026 01:19:41

## Test Cases

### 1. No Crash
**Input:** detect_env.ps1
**Expected:** Exit without error.
**Actual:** Error: False
**Pass:** âœ…

### 2. JSON Profile Created
**Input:** Check for SYSTEM_PROFILE.json.
**Expected:** File exists.
**Actual:** Exists: True
**Pass:** âœ…

### 3. Profile Keys Present
**Input:** Parse JSON for cpu, memory, capabilities.
**Expected:** All keys present.
**Actual:** cpu: True, memory: True, capabilities: True
**Pass:** âœ…

### 4. ENV File Created
**Input:** Check for OPTIMIZED_FLAGS.env.
**Expected:** File exists.
**Actual:** Exists: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-021 (Detect Duplicate Files)
**Date:** 03/26/2026 01:19:41

## Test Cases

### 1. No Crash
**Input:** find_duplicates.ps1 on dir with 2 identical files.
**Expected:** Exit without error.
**Actual:** Error: False
**Pass:** âœ…

### 2. Report Created
**Input:** Check for DUPLICATE_REPORT.md.
**Expected:** File exists.
**Actual:** Exists: True
**Pass:** âœ…

### 3. Detects Duplicate Group
**Input:** Two identical files.
**Expected:** Total Groups: 1
**Actual:** Found 1 group
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-022 (Generate .gitignore)
**Date:** 03/26/2026 01:19:41

## Test Cases

### 1. No Crash
**Input:** generate_gitignore.ps1 -Templates "Python"
**Expected:** Exit without error.
**Actual:** Error: False
**Pass:** âœ…

### 2. File Created
**Input:** Check for .gitignore in target dir.
**Expected:** File exists.
**Actual:** Exists: True
**Pass:** âœ…

### 3. Contains Python Patterns
**Input:** Search for __pycache__ or .pyc.
**Expected:** Present in .gitignore.
**Actual:** Match: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-024 (Skill Gap Identifier)
**Date:** 03/26/2026 01:19:41

## Test Cases

### 1. Scaffold Creation
**Input:** Create 'test_skill_scaffold'
**Expected:** Directory created with SKILL.md and scripts/
**Actual:** Exists: True, MD: True, Scripts: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-025 (Paste Sanitizer)
**Date:** 03/26/2026 01:19:41

## Test Cases

### 1. Output Block Created
**Input:** Mixed prompt/output/commands.
**Expected:** COPY/PASTE block present.
**Actual:** Found: True
**Pass:** âœ…

### 2. Output Stripped
**Input:** Contains prompt/output lines.
**Expected:** Commands only, output removed.
**Actual:** Commands kept and output removed: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-027 (Rollback Planner)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. No Rollback Path
**Input:** Action without rollback path.
**Expected:** rollback_level NONE.
**Actual:** Level: NONE
**Pass:** âœ…

### 2. Tested Rollback Path
**Input:** Action with rollback path and -Tested.
**Expected:** rollback_level FULL.
**Actual:** Level: FULL
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-028 (Hallucination Detector)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. Flags Specific Claims
**Input:** Content with version, API path, function signature.
**Expected:** HIGH risk and safe_to_proceed false.
**Actual:** Risk: HIGH
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-029 (Checkpoint Manager)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. Create Verified Checkpoint
**Expected:** status VERIFIED
**Actual:** VERIFIED
**Pass:** âœ…

### 2. List Checkpoints
**Expected:** at least 1 checkpoint
**Actual:** 1
**Pass:** âœ…

### 3. Validate Checkpoints
**Expected:** status OK
**Actual:** OK
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-030 (Handoff Protocol)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. Handoff Document Created
**Expected:** HANDOFF.md exists
**Actual:** Exists: True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-031 (Dependency Validator)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. Dependencies Present
**Expected:** ready_to_execute true
**Actual:** True
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-032 (Token Budget Monitor)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. Critical Threshold
**Expected:** status CRITICAL and CHECKPOINT_NOW
**Actual:** CRITICAL / CHECKPOINT_NOW
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---

# ðŸ§ª Verification Report: SKILL-033 (Semantic Diff)
**Date:** 03/26/2026 01:19:42

## Test Cases

### 1. Intent Fulfilled
**Expected:** verdict COMPLETE
**Actual:** COMPLETE
**Pass:** âœ…

## Summary
**âœ… PASSED (100% Coverage)**


---


# Global Summary

| Metric | Value |
|--------|-------|
| **Skills Verified** | 31 |
| **Tests Passed** | 31 |
| **Tests Failed** | 0 |
| **Success Rate** | 100% |
| **Failed Skills** | None |

---

*Generated by [Publish-Results.ps1](https://github.com/Sounder25/Foundational-Agent-Skills) on 2026-03-26 01:19:42*
