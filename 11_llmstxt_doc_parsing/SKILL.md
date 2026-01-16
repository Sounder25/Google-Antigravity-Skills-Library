---
name: llms.txt & Doc Parsing
description: Rapidly ingest documentation via the /llms.txt standard to gain "fast-track" understanding of libraries without scraping entire sites.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-011: llms.txt & Doc Parsing

## Overview

Executes "Rapid Documentation Mastery" by locating and consuming the `llms.txt` file from a documentation site. This file provides a curated map of markdown files optimized for LLM consumption, allowing the agent to instantly master a framework or API.

## Trigger Phrases

- `read docs for <url>`
- `ingest llms.txt`
- `learn <library> fast`
- `parse documentation`

## Inputs

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--url` | string | Yes | - | Base URL of the project documentation (e.g., `https://docs.example.com`) |
| `--output-dir` | string | No | `.docs` | Directory to save ingested documentation |
| `--max-files` | int | No | 10 | Limit number of referenced files to fetch |

## Outputs

### 1. DOCS_INDEX.json

Metdata about what was ingested:
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

### 2. CONSOLIDATED_KNOWLEDGE.md

A single, optimized markdown file containing the "fast-track" documentation content defined in `llms.txt`.

## Preconditions

1. Target site must have an `/llms.txt` file (or user must provide direct link).
2. Internet access required.

## Implementation

### Script: fetch_docs.ps1

1. Checks `url/llms.txt` and `url/llms-full.txt`.
2. Parses the typical `llms.txt` format:
   ```text
   # Project Name
   > Project Description
   
   - [Title](link) - Description
   - [API](link) - Main API docs
   ```
3. Fetches the linked markdown files.
4. Concatenates them into `CONSOLIDATED_KNOWLEDGE.md`.
5. Prompts the agent to read this single file.

## Integration

**Agent Workflow:**
1. User asks: "How do I use this new generic web3 library?"
2. Agent runs: `.\skills\08_llmstxt_doc_parsing\fetch_docs.ps1 -Url "https://generic-web3.io"`
3. Script outputs: `CONSOLIDATED_KNOWLEDGE.md`
4. Agent reads file and answers user instantly.
