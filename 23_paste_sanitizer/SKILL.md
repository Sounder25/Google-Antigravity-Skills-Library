---
name: Paste Sanitizer
description: Convert mixed terminal output and instructions into safe, paste-ready command blocks.
---

# SKILL-023: Paste Sanitizer

## Purpose

Convert “chatty” instructions, shell prompts, and terminal output into a safe, paste-ready command block that satisfies the **Pre-Action Guard (Skill-018)**.

This skill ensures that unintended text like `PS C:\`, `Everything up-to-date`, or error dumps are never pasted into a live terminal.

## Goal

Enforce **Command-Only** output for all runnable steps.

## Algorithm

1. **Identify** lines that match "likely command" patterns:
   - Starts with `git`, `dotnet`, `npm`, `python`, `cd`, `mkdir`, `$env:`, etc.
2. **Identify** and **Drop** lines that match "likely output" or "prompt" patterns:
   - Starts with `PS`, Contains `Everything up-to-date`, `At line:`, `CategoryInfo:`, `error:`, `warning:`, etc.
3. **Comment Out** (optional) unknown lines with `#` instead of deleting, to preserve context safely within a script.
4. **Wrap** the cleaned commands in a labeled block: `## COPY/PASTE COMMANDS`.

## Trigger Phrases

- `sanitize commands`
- `clean terminal output`
- `make paste-ready`

## Expected Output Format

```markdown
## COPY/PASTE COMMANDS
```powershell
git add .
git commit -m "fix"
git push
```

```

## Safety Constraints
- Only copy blocks labeled **COPY/PASTE COMMANDS**.
- Never copy blocks labeled **Expected Output**.
- If a line inside the command block does not start with a tool or verb, the sanitizer has failed.

## Implementation
See `scripts/paste_sanitizer.ps1`.
