---
description: Push commits and create/update pull request with smart branch management.
argument-hint: [status] [base-branch] - status: 1=opened, 2=draft, 3=ready; base-branch defaults to main
---
Arguments: $ARGUMENTS
## Arguments

Parse arguments (flexible order):
- **status**: `1`=opened, `2`=draft, `3`=ready (defaults: new PR=opened, update=draft)
- **base-branch**: Target branch (default: `main`)

## Workflow

### 1. Pre-Flight Checks

```bash
# Check for uncommitted changes
git status --porcelain

# Check remote tracking
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null

# Sync with remote if tracking exists
git fetch origin
```

If uncommitted changes detected, use the Task tool with subagent_type="smart-commit" to commit changes first.

### 2. Branch Management (CRITICAL)

**Step 1: Detect current situation**
```bash
# Get current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"

# Check if on main/master
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "ON BASE BRANCH"
fi

# Count unpushed commits
UNPUSHED=$(git rev-list origin/$CURRENT_BRANCH..HEAD --count 2>/dev/null || echo "0")
echo "Unpushed commits: $UNPUSHED"
```

**Step 2: If on main/master with unpushed commits → CUT A FEATURE BRANCH**

This is critical. If you detect:
- Current branch is `main` or `master`
- There are unpushed commits (UNPUSHED > 0)

Then you MUST:
1. Analyze the commits to generate a descriptive feature branch name (e.g., `feat/add-smart-commit-agents`)
2. Create the feature branch from current HEAD
3. Switch back to main and reset it to origin
4. Switch to the new feature branch

```bash
# 1. Get commits for naming
git log origin/main..HEAD --oneline

# 2. Create feature branch (YOU generate the name based on commits)
git checkout -b feat/descriptive-name-here

# 3. Reset main to match origin (IMPORTANT: keeps main clean)
git checkout main
git reset --hard origin/main

# 4. Return to feature branch
git checkout feat/descriptive-name-here
```

**Step 3: If already on feature branch** → Skip branch management, proceed to PR status.

### 3. PR Status Determination

```bash
# Check if PR exists for current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
gh pr list --head "$BRANCH" --json number,state
```

- If user provided status argument: Use it (1=opened, 2=draft, 3=ready)
- If no status: New PR defaults to "opened", existing PR update defaults to "draft"

### 4. Context Gathering

```bash
# Get base branch (default: main)
BASE=${BASE_BRANCH:-main}

# All commits from base to HEAD
git log $BASE..HEAD --oneline

# Diff statistics
git diff $BASE...HEAD --stat

# Full diff for analysis
git diff $BASE...HEAD
```

### 5. Push to Remote

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if upstream exists
if git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null; then
    git push
else
    git push -u origin "$BRANCH"
fi
```

### 6. PR Creation or Update

**For new PRs:**

Analyze commits and changes to generate:
- Concise, descriptive PR title
- Comprehensive description with summary, commits list, key files changed

```bash
# Create PR (add --draft if status is draft)
gh pr create --title "title" --body "description" --base main

# If status is "ready", mark as ready after creation
gh pr ready
```

**For existing PRs:**

```bash
# Get PR number
PR_NUM=$(gh pr list --head "$BRANCH" --json number -q '.[0].number')

# Add comment listing new commits
gh pr comment $PR_NUM --body "New commits..."

# Update PR status if needed
gh pr ready $PR_NUM --undo  # Convert to draft
gh pr ready $PR_NUM         # Mark ready
```

## Critical Constraints

- Never add "Co-authored-by" or AI signatures to PR content
- Never include "Generated with Claude Code" or similar
- Never use emojis in PR title or description
- Use existing git user configuration only
- Ensure PR title follows project conventions (analyze recent PRs if available)

## PR Description Format

```markdown
## Summary

[2-3 bullet points describing what and why]

## Changes

- [Key change 1]
- [Key change 2]

## Commits

- `abc1234` - commit message 1
- `def5678` - commit message 2

## Files Changed

[List significant files with brief notes]
```

## Edge Cases

1. **No remote configured**: Report error, suggest `git remote add origin <url>`
2. **No gh CLI**: Report that GitHub CLI is required for PR operations
3. **Permission issues**: Report and suggest checking repository access
4. **Branch behind remote**: Pull and rebase before pushing
5. **No commits to push**: Report that there are no new commits

## Output

Report clearly:
- Branch pushed: `<branch-name>`
- PR created/updated: `<PR-URL>`
- Status: opened/draft/ready
