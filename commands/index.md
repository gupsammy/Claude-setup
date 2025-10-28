---
allowed-tools: Bash
description: Create or update PROJECT_INDEX.json for current project
argument-hint: (no arguments)
---

Execute the PROJECT_INDEX helper script at ~/.claude-code-project-index/scripts/project-index-helper.sh

Usage:
- /index - Create or update PROJECT_INDEX.json for current project

This analyzes your codebase and creates PROJECT_INDEX.json with:
- Directory tree structure
- Function/method signatures  
- Class inheritance relationships
- Import dependencies
- Documentation structure
- Language-specific parsing for Python, JavaScript/TypeScript, and Shell scripts

The index is automatically updated when you edit files through PostToolUse hooks.
