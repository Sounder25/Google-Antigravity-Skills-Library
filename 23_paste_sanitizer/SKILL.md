---
name: paste-sanitizer
description: "Convert mixed terminal output, shell prompts, and chatty instructions into safe, paste-ready command blocks by stripping prompt prefixes, error dumps, and non-command lines. Use when preparing commands for copy-paste execution, cleaning up terminal output for documentation, or ensuring Pre-Action Guard (Skill-018) compliance."
metadata:
  version: 1.0.0
  author: Antigravity Skills Library
  created: 2026-01-16
  leverage_score: 5/5
---

# Paste Sanitizer

Strips prompt prefixes, output lines, and error dumps from mixed terminal content to produce clean, paste-ready command blocks that satisfy the Pre-Action Guard (Skill-018).

## Trigger Phrases

- `sanitize commands`
- `clean terminal output`
- `make paste-ready`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--input` | string | Yes | — | Raw terminal content (multiline string or file path) |
| `--comment-unknown` | switch | No | false | Comment out unrecognized lines with `#` instead of dropping them |

## Workflow

1. **Split** input into individual lines.
2. **Classify** each line using regex patterns:
   - **Command** — matches `^(git|dotnet|npm|python|cd|mkdir|cp|mv|rm|curl|wget|\$env:)\b`.
   - **Output/Prompt** — matches `^PS\s|Everything up-to-date|At line:|CategoryInfo:|FullyQualifiedErrorId|^\s*error:|^\s*warning:`.
   - **Unknown** — does not match either pattern.
3. **Keep** command lines, **drop** output/prompt lines.
4. **Handle unknown** lines: drop by default, or prefix with `#` if `--comment-unknown` is set.
5. **Validate** result: if any line in the cleaned output does not start with a recognized tool/verb, flag the block for manual review.
6. **Wrap** cleaned commands in a `## COPY/PASTE COMMANDS` block.

## Outputs

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
- If a line inside the command block does not start with a recognized tool or verb, the sanitizer has failed — flag for manual review.

## Preconditions

1. PowerShell 5.1+ or Core 7+.

## Implementation

Core classification logic (see `scripts/paste_sanitizer.ps1` for full implementation):

```powershell
$commandPattern = '^(git|dotnet|npm|python|cd|mkdir|cp|mv|rm|curl|wget|\$env:)\b'
$outputPattern  = '^PS\s|Everything up-to-date|At line:|CategoryInfo:|FullyQualifiedErrorId|^\s*(error|warning):'

$cleaned = foreach ($line in $Input -split "`n") {
    if ($line -match $commandPattern) { $line }          # keep commands
    elseif ($line -match $outputPattern) { continue }    # drop output/prompts
    elseif ($CommentUnknown) { "# $line" }               # comment unknowns
    # else: silently drop
}

# Validate: flag if any cleaned line doesn't start with a known verb
$cleaned | ForEach-Object { if ($_ -notmatch $commandPattern -and $_ -notmatch '^#') {
    Write-Warning "Unrecognized line in output — manual review needed: $_"
}}
```

## Integration

```powershell
.\skills\23_paste_sanitizer\paste_sanitizer.ps1 -Input $rawTerminalOutput
# Returns cleaned command block ready for paste execution.
```
