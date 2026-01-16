---
name: MCP Connector
description: Provides a Model Context Protocol (MCP) server interface to the skills library, allowing any MCP-compliant agent (e.g. Claude Desktop) to invoke Antigravity skills as native tools.
version: 1.0.0
author: Antigravity Skills Library
created: 2026-01-16
leverage_score: 5/5
---

# SKILL-016: MCP Connector

## Overview

This skill is a **Meta-Skill**. It wraps the entire library in an MCP Server. This enables external agents to "plug in" to Antigravity capabilities without knowing the underlying PowerShell scripts.

## Trigger Phrases

- `start mcp server`
- `connect skills to claude`

## Inputs

None (Service).

## Outputs

- Exposes Tools via stdio:
  - `list_skills()`
  - `run_skill(id, args)`
  - `read_skill_spec(id)`

## Preconditions

- Python 3.10+
- `mcp` package installed

## Implementation

See `server.py`.

## Configuration

Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "antigravity-skills": {
      "command": "python",
      "args": [
        "full/path/to/server.py"
      ]
    }
  }
}
```
