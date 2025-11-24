---
allowed-tools: Bash, SlashCommand, AskUserQuestion
description: Push commits and create/update pull request with smart branch management.
argument-hint: [status] [base-branch] - status: 1=opened, 2=draft, 3=ready; base-branch defaults to main
---

# Smart Push & PR

Push commits and create or update pull requests with intelligent branch management and automated workflows.

## Arguments

Parse `$ARGUMENTS` (flexible order):
- **status**: `1`=opened, `2`=draft, `3`=ready (defaults: new PR→opened, update→draft)
- **base-branch**: Target branch (default: `main`)

## Workflow

### 1. Pre-Flight Checks

Sync with remote branch if tracking exists. If uncommitted changes detected, automatically run `/commit` to commit them first.

### 2. Branch Management

**If on base branch with unpushed commits:**
- Analyze commits to generate a descriptive feature branch name
- Create and checkout the new feature branch
- Reset base branch to match origin
- Continue workflow on the new feature branch

**If already on feature branch:**
- Proceed with current branch

### 3. PR Status Determination

Check if PR exists for current branch using `gh pr list --head <branch>`.

**If user provided status argument:** Use it (convert 1→opened, 2→draft, 3→ready).

**If no status argument:**
- New PR → Default to "opened"
- Existing PR update → Default to "draft"

### 4. Context Gathering

Collect comprehensive context:
- All commits from base branch to HEAD: `git log <base>..HEAD`
- Diff statistics: `git diff <base>...HEAD --stat`
- Full diff for analysis: `git diff <base>...HEAD`

### 5. Push to Remote

Push commits to remote. Use `-u origin <branch>` if branch doesn't have upstream tracking yet.

### 6. PR Creation or Update

**For new PRs:**
- Analyze commits and changes to generate:
  - Concise, descriptive PR title
  - Comprehensive description including:
    - Summary of changes (what and why)
    - List of commits
    - Key files changed
- Create PR using `gh pr create` with appropriate flags:
  - `--draft` if status is draft
  - `--base <base-branch>` to target correct branch
- If status is "ready", mark as ready for review after creation

**For existing PRs:**
- Push updates to remote
- Add comment listing new commits if any exist
- Update PR status if needed:
  - Convert to draft: `gh pr ready <number> --undo`
  - Mark ready: `gh pr ready <number>`

## Critical Constraints

- Never add "Co-authored-by" or AI signatures to PR content
- Never include "Generated with Claude Code" or similar attribution
- Never use emojis in PR title or description
- Use existing git user configuration only
- Ensure PR title follows project conventions (analyze recent PRs if available)

## Key Implementation Notes

Use `gh` CLI for all GitHub operations. Show clear progress through each step. Handle edge cases gracefully (no remote, no gh CLI, permission issues).
