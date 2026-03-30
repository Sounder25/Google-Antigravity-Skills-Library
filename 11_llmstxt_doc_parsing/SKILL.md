---
name: llmstxt-doc-parsing
description: "Rapidly ingest documentation via the /llms.txt standard to gain fast-track understanding of libraries and APIs without scraping entire sites. Fetches curated markdown files and consolidates them into a single knowledge file. Use when onboarding to a new library, answering questions about an unfamiliar API, or an agent needs instant documentation context."
metadata:
  version: 1.0.0
  author: Antigravity Skills Library
  created: 2026-01-16
  leverage_score: 5/5
---

# llms.txt Doc Parsing

Locates and consumes the `/llms.txt` file from a documentation site, fetches the referenced markdown files, and consolidates them into a single `CONSOLIDATED_KNOWLEDGE.md` for instant library mastery.

## Trigger Phrases

- `read docs for <url>`
- `ingest llms.txt`
- `learn <library> fast`
- `parse documentation`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--url` | string | Yes | — | Base URL of the project docs (e.g., `https://docs.example.com`) |
| `--output-dir` | string | No | `.docs` | Directory to save ingested documentation |
| `--max-files` | int | No | 10 | Limit number of referenced files to fetch |

## Workflow

1. **Fetch** `<url>/llms.txt`. If 404, try `<url>/llms-full.txt`. If both fail, **HALT** with error — site does not support the llms.txt standard.
2. **Parse** the llms.txt format to extract linked markdown paths (lines matching `- [Title](link)`).
3. **Download** up to `--max-files` referenced markdown files. Skip files that return non-200 status and log them as warnings.
4. **Validate** at least one file was successfully fetched. If zero files downloaded, **HALT** with error.
5. **Write** `DOCS_INDEX.json` with metadata (file paths, token counts per file).
6. **Concatenate** all fetched content into `CONSOLIDATED_KNOWLEDGE.md`.
7. **Prompt** the agent to read the consolidated file for instant context.

## Outputs

### DOCS_INDEX.json

```json
{
  "source_url": "https://docs.example.com/llms.txt",
  "project_name": "Example Lib",
  "ingested_files": [
    { "path": "overview.md", "tokens": 1200 },
    { "path": "api-reference.md", "tokens": 4500 }
  ],
  "total_tokens": 5700
}
```

### CONSOLIDATED_KNOWLEDGE.md

Single optimized markdown file containing all fast-track documentation content.

## Preconditions

1. Target site must have an `/llms.txt` file (or user provides a direct link).
2. Internet access required.

## Safety/QA Checks

- **Read-only** — only fetches and writes to `--output-dir`; never modifies the target site.
- **Token-aware** — tracks token counts per file in `DOCS_INDEX.json` to prevent context window overflow.

## Implementation

Core fetch-and-parse logic (see `fetch_docs.ps1` for full implementation):

```powershell
# Fetch llms.txt (with fallback)
$response = Invoke-WebRequest "$Url/llms.txt" -ErrorAction SilentlyContinue
if (-not $response -or $response.StatusCode -ne 200) {
    $response = Invoke-WebRequest "$Url/llms-full.txt"
}

# Parse links: extract markdown paths from "- [Title](link)" lines
$links = [regex]::Matches($response.Content, '\[.*?\]\((.+?\.md)\)') | ForEach-Object { $_.Groups[1].Value }

# Download each referenced file (up to --max-files), skip failures
$fetched = @()
foreach ($link in $links | Select-Object -First $MaxFiles) {
    $fullUrl = if ($link -match '^http') { $link } else { "$Url/$link" }
    try { $content = (Invoke-WebRequest $fullUrl).Content; $fetched += @{ path=$link; content=$content } }
    catch { Write-Warning "Skipped $link (fetch failed)" }
}
```

## Integration

```powershell
.\skills\11_llmstxt_doc_parsing\fetch_docs.ps1 -Url "https://docs.example.com"
# Agent reads CONSOLIDATED_KNOWLEDGE.md and answers user questions instantly.
```
