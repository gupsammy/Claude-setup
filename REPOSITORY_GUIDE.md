# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is your **personal Claude Code configuration directory** located at `~/.claude`. It contains global settings, custom commands, hooks, agents, and integrations that apply across all your projects.

**Tech Stack:** Shell scripts, JSON configuration, Markdown documentation, Python hooks

## Directory Structure

```
~/.claude/
├── CLAUDE.md                  # Global user preferences (applies to all sessions)
├── settings.json              # Core Claude Code settings
├── settings.local.json        # Local overrides
├── mcp-config.json           # Model Context Protocol server configurations
├── commands/                 # Custom slash commands (*.md files)
├── hooks/                    # Event hooks (Python scripts)
├── agents/                   # Custom agent definitions
├── output-styles/            # Custom output style configurations
├── plugins/                  # Installed plugins and marketplaces
├── projects/                 # Project-specific configurations
├── statusline-script.sh      # Custom statusline implementation
└── todos/                    # Persistent todo storage
```

## Key Configuration Files

### settings.json
- **Enabled plugins:** pr-review-toolkit, feature-dev, security-guidance
- **Hooks:** PreToolUse (Read), PostToolUse (Write/Edit), Stop
- **StatusLine:** Custom script at `~/.claude/statusline-script.sh`
- **Always Thinking:** Disabled

### mcp-config.json
Configured MCP servers:
- `playwright` - Browser automation
- `brave-search` - Web search
- `github` - GitHub API integration
- `exa` - Advanced web search
- `chrome-devtools` - Chrome debugging
- `XcodeBuildMCP` - Xcode integration
- `Context7` - Upstash context management
- `octocode` - GitHub code operations

**Important:** Contains API keys and tokens that should remain private.

## Custom Slash Commands

All commands are in `/commands/*.md` with YAML frontmatter.

### Development Workflow
- `/next [task-id]` - Load project context and plan next task from development_plan.md
- `/push-pr [status] [base-branch]` - Run tests/build, push commits, create/update PR
- `/commit` - Smart git commit with context-aware messages
- `/clean-gone` - Remove local branches marked as [gone] in git

### Documentation & Planning
- `/sprint-plan [team-size] [timeline]` - Generate phased development plan from PRD
- `/updateclaudemd` - Analyze codebase and update CLAUDE.md
- `/docs` - Generate or update documentation
- `/explain-like-senior` - Senior engineer explanation of code

### Code Quality
- `/make-it-pretty` - Apply design principles and polish UI
- `/predict-issues` - Proactive issue detection
- `/understand` - Deep code analysis

### Feature Development
- `/create-prd` - Generate Product Requirements Document
- `/generate-tasks` - Break down features into tasks
- `/process-tasks` - Process task lists systematically

## Hooks System

### PreToolUse Hooks
- **Read tool:** Checks if reading Claude Code docs (runs claude-docs-helper.sh)

### PostToolUse Hooks
- **Write/Edit tools:** Updates project index after file modifications

### Stop Hooks
- **All sessions:** Plays system sound (Funk.aiff)
- **All sessions:** Reindexes project if needed

## Custom Agents

Located in `/agents/*.md`:
- `security-auditor.md` - Comprehensive security analysis
- `test-engineer.md` - Test coverage and quality analysis

## Coding Principles from Global CLAUDE.md

### Problem Solving
- Reflect on tool results before proceeding
- Execute independent operations in parallel
- Clean up temporary files after iteration

### Code Quality
- Write general-purpose solutions, not test-case-specific
- Focus on correct algorithms and best practices
- Tell user if tasks are unreasonable or tests are incorrect

### Frontend Development
- Apply design principles: hierarchy, contrast, balance, movement
- Add hover states, transitions, micro-interactions
- Create impressive demonstrations

### Development Workflow
- Use terminal/bash for versatility (tests, builds, file scanning)
- Prefer terminal commands for quick exploration

### Task Approach
- Minimal, elegant solutions
- Change as little code as possible

## External Integrations

### Cave Timer (`~/.claude-cave/`)
Deep work focus tool installed globally:
- `cave start [minutes]` - Start focus session (default 90 min)
- `cave stop` - End session
- `cave status` - Check remaining time

### AI Dev Tasks (`~/Documents/Github/fork_exp/ai-dev-tasks/`)
Structured feature development files:
- `create-prd.md` - PRD generation workflow
- `generate-tasks.md` - Task breakdown workflow
- `process-task-list.md` - Task processing workflow

## Statusline Script

Custom statusline at `~/.claude/statusline-script.sh` displays:
- Git branch and status
- Project context
- Current time
- Custom indicators

**Padding:** 1 space

## Maintenance Guidelines

### When Modifying Commands
1. Keep YAML frontmatter with `allowed-tools`, `description`, `argument-hint`
2. Test command with various argument combinations
3. Document argument parsing logic clearly
4. Handle edge cases (missing files, wrong branch, etc.)

### When Adding Hooks
1. Place in `/hooks/` directory
2. Ensure hook is idempotent (safe to run multiple times)
3. Add timeout for long-running operations
4. Update `settings.json` to register the hook

### When Updating Settings
1. Backup current settings: `cp settings.json settings.json.backup`
2. Validate JSON syntax after changes
3. Test in a sample project before applying globally
4. Keep `settings.local.json` for machine-specific overrides

### When Managing MCP Servers
- Test server connectivity: `npx @modelcontextprotocol/inspector`
- Keep API keys in environment variables when possible
- Document required permissions for each server

## Security Considerations

This directory contains sensitive information:
- GitHub personal access tokens
- API keys (Brave, Exa, HuggingFace)
- Never commit this directory to version control
- Regularly rotate API tokens
- Use environment variables for sensitive data when possible

## Common Tasks

### Add a new slash command
```bash
cd ~/.claude/commands
# Create new command file
touch my-command.md
# Edit with frontmatter and implementation
```

### Backup your configuration
```bash
tar -czf ~/claude-config-backup-$(date +%Y%m%d).tar.gz ~/.claude/
```

### Test a hook script
```bash
cd ~/.claude/hooks
python type_check.py
```

### Reload configuration
Changes to `settings.json` and commands are picked up automatically in new sessions.

## Development Notes

- This directory is **NOT a git repository** (intentionally)
- File history is maintained in `/file-history/`
- Debug information is stored in `/debug/`
- Shell snapshots are saved in `/shell-snapshots/`
- Todos are persisted in `/todos/`

## Related Resources

- Claude Code Documentation: https://docs.claude.com/en/docs/claude-code
- MCP Documentation: https://modelcontextprotocol.io
- Slash Command Guide: `~/.claude/commands/` (examples in each .md file)
