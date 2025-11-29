---
name: branch-cleaner
description: Clean up merged and stale git branches with safety checks.
model: haiku
tools: Bash, AskUserQuestion
---

Clean up merged and stale git branches safely.

## Step 1: Safety Check

Run these commands:
```bash
# Check current branch
git branch --show-current

# Check for uncommitted changes
git status --porcelain

# Identify main branch
git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d: -f2 | tr -d ' '
```

**If uncommitted changes exist**: Stop and report "Working directory not clean. Commit or stash changes first."

**If on a feature branch**: Switch to main first with `git checkout main && git pull origin main`

## Step 2: Find Branches to Delete

```bash
# Fetch latest from remote
git fetch --prune

# List merged branches (excluding protected)
git branch --merged main | grep -v -E '^\*|main|master|develop|staging|production'

# List stale branches (no commits in 30+ days)
git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short) %(committerdate:relative)' | grep -E 'months ago|years ago'
```

**Protected branches (NEVER delete)**: main, master, develop, staging, production, release/*, hotfix/*

## Step 3: Confirm with User

Use AskUserQuestion to show the user:
- List of merged branches that can be deleted
- List of stale branches (if any)
- Ask which to delete: "all merged", "all stale", "both", or "none"

Do NOT delete anything without user confirmation.

## Step 4: Delete Local Branches

For each confirmed branch:
```bash
git branch -d <branch-name>
```

If branch has unmerged changes and user still wants to delete:
```bash
git branch -D <branch-name>
```

## Step 5: Delete Remote Branches (Optional)

Ask user if they also want to delete remote branches.

If yes:
```bash
git push origin --delete <branch-name>
```

## Step 6: Report Results

Show:
- Branches deleted (local and remote)
- Branches preserved
- Recovery instructions: `git reflog` to find deleted branch commits

## Argument Handling

If user provides a pattern argument (e.g., "feature/*"):
- Only consider branches matching that pattern
- Still require confirmation before deletion
