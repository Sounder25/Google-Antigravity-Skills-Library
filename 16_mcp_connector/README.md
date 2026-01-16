# Antigravity Skills MCP Server

This directory contains a Model Context Protocol (MCP) server that exposes the Antigravity Skills Library to any MCP-compliant agent (Claude Desktop, etc.).

## Features

1. **List Skills:** Returns list of available `.ps1` skills in the library.
2. **Run Skill:** Executes a skill script with arguments and returns the output.
3. **Read Artifacts:** Allows reading `PLAN.json`, `RENAME_SUMMARY.md` etc.

## Setup

1. Install dependencies:

    ```
    pip install "mcp[cli]"
    ```

2. Run server:

    ```
    python server.py
    ```

## Logic

The server dynamically scans the parent `skills` directory for `SKILL.md` files to register tools.
