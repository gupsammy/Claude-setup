---
argument-hint: [category|server-names]
description: Setup MCP servers (optional: category or comma-separated server names)
allowed-tools: Read, Write, Edit, AskUserQuestion, Bash(mkdir:*)
---

# Setup MCP Servers

Add MCP servers from master config to the current project.

Arguments: $ARGUMENTS

## Categories

- **research**: exa, brave-search, reddit-mcp, reddit
- **seo**: dataforseo, firecrawl-mcp
- **frontend**: chrome-devtools, vibe-annotations, shadcn, next-devtools

## Workflow

**Step 1: Load Configurations**

Read `~/.claude/mcp-config.json` (master) and `.mcp.json` (project, may not exist).

Identify MCPs in master that aren't in project config.

If all MCPs already present, report and stop.

**Step 2: Determine Selection**

Parse argument:
- Category name (research/seo/frontend) → select all MCPs in that category that aren't already installed
- Comma-separated names → select those specific MCPs
- No argument → use AskUserQuestion with multiSelect to let user choose from available MCPs

For explicit names not found in master config, warn and skip.
For names already installed, note and skip.

If no valid MCPs to add after filtering, report and stop.

**Step 3: Update Project Files**

Add selected MCP configs to `.mcp.json` (create if needed, preserve existing entries).

Update `.claude/settings.local.json`:
- Set `enableAllProjectMcpServers: false`
- Add selected MCPs to `enabledMcpjsonServers` array
- Preserve existing enabled/disabled lists

**Step 4: Report**

List MCPs added. Remind user to restart Claude Code.
