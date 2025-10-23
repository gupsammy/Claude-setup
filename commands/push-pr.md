---
allowed-tools: Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(yarn:*), Bash(pnpm:*), Bash(python:*), Bash(pytest:*), Bash(cargo:*), Bash(swift:*), Bash(go:*), Bash(make:*), Bash(gradle:*), Bash(mvn:*), SlashCommand
argument-hint: [status] [base-branch]
description: Push commits and create/update pull request (status: 1=opened, 2=draft, 3=ready)
---

# Smart Push & PR Creation

Push commits and create or update a pull request with proper validation.

## Arguments

- **status** (optional): PR status when creating/updating
  - `1` = opened (default for NEW PRs)
  - `2` = draft (default for UPDATES)
  - `3` = ready_for_review
- **base-branch** (optional): Target branch (default: main)

## Step 0: Parse Arguments & Setup

```bash
# Parse arguments
STATUS_ARG="$1"
BASE_BRANCH_ARG="$2"

# Determine if first arg is status (1, 2, or 3) or base branch
if [[ "$STATUS_ARG" =~ ^[123]$ ]]; then
    PR_STATUS="$STATUS_ARG"
    BASE_BRANCH="${BASE_BRANCH_ARG:-main}"
else
    # First arg is base branch, use default status
    PR_STATUS=""  # Will be determined later
    BASE_BRANCH="${STATUS_ARG:-main}"
fi

# Verify base branch exists, fallback to main if needed
if ! git show-ref --verify --quiet refs/heads/$BASE_BRANCH; then
    if git show-ref --verify --quiet refs/heads/main; then
        BASE_BRANCH="main"
        echo "Using 'main' as base branch"
    else
        echo "Warning: Base branch '$BASE_BRANCH' not found"
    fi
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Sync with remote branch first
if git rev-parse --abbrev-ref --symbolic-full-name @{u} > /dev/null 2>&1; then
    echo "📥 Syncing with remote branch..."
    git pull || echo "⚠️  Pull failed, continuing with local state"
else
    echo "ℹ️  No remote tracking branch configured, skipping pull"
fi
```

## Step 1: Check for Uncommitted Changes

```bash
# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  Found uncommitted changes. Running /commit to commit them first..."
    # Run /commit command to commit changes
    # After /commit completes, continue with the push-pr flow
else
    echo "✅ No uncommitted changes"
fi
```

## Step 2: Move Commits from Base Branch (if applicable)

```bash
# Check if we're on the base branch
if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "⚠️  You're on the base branch '$BASE_BRANCH'"

    # Check for unpushed commits
    UNPUSHED=$(git log @{u}.. --oneline 2>/dev/null | wc -l | tr -d ' ')

    if [ "$UNPUSHED" -gt 0 ]; then
        echo "Found $UNPUSHED unpushed commit(s) on $BASE_BRANCH"
        echo "Moving these commits to a new feature branch..."
    fi
else
    echo "On feature branch: $CURRENT_BRANCH"
fi
```

If on the base branch with unpushed commits:
1. **Analyze ALL local commits** to generate a meaningful branch name based on their content
2. **Create and checkout new feature branch**: `git checkout -b <branch-name>`
3. **Force reset base branch to origin**: `git branch -f $BASE_BRANCH origin/$BASE_BRANCH`
4. Update `CURRENT_BRANCH` variable to the new branch name

## Step 3: Determine PR Status

```bash
# Check if PR already exists for this branch
PR_EXISTS=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number' 2>/dev/null)

# Determine final PR status
if [ -n "$PR_STATUS" ]; then
    # User explicitly provided status
    case "$PR_STATUS" in
        1) FINAL_STATUS="opened" ;;
        2) FINAL_STATUS="draft" ;;
        3) FINAL_STATUS="ready" ;;
    esac
else
    # Auto-determine based on whether it's new or update
    if [ -n "$PR_EXISTS" ]; then
        FINAL_STATUS="draft"
        echo "📝 Updating existing PR #$PR_EXISTS as: draft"
    else
        FINAL_STATUS="opened"
        echo "📝 New PR will be created as: opened"
    fi
fi
```

## Step 4: Pre-Push Validation

```bash
# Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not a git repository"
    exit 1
fi

# Check for unpushed commits (after potential commit in Step 1)
UNPUSHED_COUNT=$(git log @{u}.. --oneline 2>/dev/null | wc -l | tr -d ' ')

if [ "$UNPUSHED_COUNT" -eq 0 ]; then
    echo "Checking if branch exists on remote..."

    # Check if we need to push the branch for the first time
    if ! git ls-remote --heads origin "$CURRENT_BRANCH" | grep -q "$CURRENT_BRANCH"; then
        echo "Branch doesn't exist on remote. Will push and create PR."
    else
        echo "Branch exists on remote. Checking for existing PR..."
        if [ -n "$PR_EXISTS" ]; then
            echo "✅ PR #$PR_EXISTS exists. Will update status if needed."
        else
            echo "❌ No new commits to push and no existing PR"
            exit 0
        fi
    fi
else
    echo "✅ Found $UNPUSHED_COUNT unpushed commit(s)"
fi
```

## Step 5: Quality Checks (Tech-Agnostic)

```bash
# Check if package.json exists and has test/build scripts
if [ -f "package.json" ]; then
    echo "📦 Detected Node.js project"

    # Check for test script
    if grep -q '"test"' package.json && ! grep -q '"test": "echo \\"Error: no test specified\\" && exit 1"' package.json; then
        echo "Running tests..."
        if command -v npm &> /dev/null; then
            npm test || { echo "❌ Tests failed"; exit 1; }
        elif command -v yarn &> /dev/null; then
            yarn test || { echo "❌ Tests failed"; exit 1; }
        elif command -v pnpm &> /dev/null; then
            pnpm test || { echo "❌ Tests failed"; exit 1; }
        fi
    else
        echo "ℹ️  No test script found, skipping tests"
    fi

    # Check for build script
    if grep -q '"build"' package.json; then
        echo "Running build..."
        if command -v npm &> /dev/null; then
            npm run build || { echo "❌ Build failed"; exit 1; }
        elif command -v yarn &> /dev/null; then
            yarn build || { echo "❌ Build failed"; exit 1; }
        elif command -v pnpm &> /dev/null; then
            pnpm build || { echo "❌ Build failed"; exit 1; }
        fi
    else
        echo "ℹ️  No build script found, skipping build"
    fi
fi

# Check for Python project
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    echo "🐍 Detected Python project"

    # Try to run pytest if it exists
    if command -v pytest &> /dev/null; then
        echo "Running pytest..."
        pytest || { echo "❌ Tests failed"; exit 1; }
    elif [ -f "manage.py" ]; then
        echo "Detected Django project, running tests..."
        python manage.py test || { echo "❌ Tests failed"; exit 1; }
    else
        echo "ℹ️  No pytest found, skipping tests"
    fi
fi

# Check for Rust project
if [ -f "Cargo.toml" ]; then
    echo "🦀 Detected Rust project"

    if command -v cargo &> /dev/null; then
        echo "Running cargo test..."
        cargo test || { echo "❌ Tests failed"; exit 1; }

        echo "Running cargo build..."
        cargo build || { echo "❌ Build failed"; exit 1; }
    fi
fi

# Check for Go project
if [ -f "go.mod" ]; then
    echo "🔵 Detected Go project"

    if command -v go &> /dev/null; then
        echo "Running go test..."
        go test ./... || { echo "❌ Tests failed"; exit 1; }

        echo "Running go build..."
        go build ./... || { echo "❌ Build failed"; exit 1; }
    fi
fi

# Check for Swift project
if [ -f "Package.swift" ] || find . -name "*.xcodeproj" -o -name "*.xcworkspace" | grep -q .; then
    echo "🍎 Detected Swift project"

    if [ -f "Package.swift" ] && command -v swift &> /dev/null; then
        echo "Running swift test..."
        swift test || { echo "❌ Tests failed"; exit 1; }

        echo "Running swift build..."
        swift build || { echo "❌ Build failed"; exit 1; }
    else
        echo "ℹ️  Xcode project detected, skipping automated tests"
    fi
fi

# Check for Makefile
if [ -f "Makefile" ]; then
    echo "🔧 Detected Makefile"

    # Check if make test exists
    if grep -q "^test:" Makefile; then
        echo "Running make test..."
        make test || { echo "❌ Tests failed"; exit 1; }
    fi

    # Check if make build exists
    if grep -q "^build:" Makefile; then
        echo "Running make build..."
        make build || { echo "❌ Build failed"; exit 1; }
    fi
fi

echo "✅ All quality checks passed"
```

## Step 6: Gather Context

```bash
echo "Base branch: $BASE_BRANCH"
echo "Feature branch: $(git branch --show-current)"
echo ""

# Get all commits in this branch
echo "=== Commits to be included ==="
git log $BASE_BRANCH..HEAD --oneline
echo ""

# Get full diff stats
echo "=== Changes summary ==="
git diff $BASE_BRANCH...HEAD --stat
echo ""

# Get detailed diff
echo "=== Detailed changes ==="
git diff $BASE_BRANCH...HEAD
```

## Step 7: Push & Create/Update PR

Execute the following:

1. **Handle branch creation if needed** (if on base branch)
2. **Push commits to remote** - Use `-u` flag if needed
3. **Check if PR exists**
4. **Generate PR title and description** - Based on commits and changes

### For NEW PRs:

```bash
# Push to remote
git push -u origin "$CURRENT_BRANCH"

# Create PR based on status
case "$FINAL_STATUS" in
    "draft")
        gh pr create --title "TITLE" --body "BODY" --draft --base "$BASE_BRANCH"
        ;;
    "ready")
        gh pr create --title "TITLE" --body "BODY" --base "$BASE_BRANCH"
        # After creation, mark as ready for review
        gh pr ready
        ;;
    "opened"|*)
        gh pr create --title "TITLE" --body "BODY" --base "$BASE_BRANCH"
        ;;
esac
```

### For EXISTING PRs:

```bash
# Push updates
git push

# Get PR number
PR_NUM=$(gh pr list --head "$CURRENT_BRANCH" --json number --jq '.[0].number')

# Update PR status if needed
case "$FINAL_STATUS" in
    "draft")
        # Mark PR as draft (convert from ready to draft)
        gh pr ready "$PR_NUM" --undo 2>/dev/null || echo "PR already in draft mode"
        ;;
    "ready")
        # Mark PR as ready for review
        gh pr ready "$PR_NUM"
        ;;
esac

# Add comment about the update
COMMIT_LIST=$(git log origin/$CURRENT_BRANCH..HEAD --oneline 2>/dev/null || echo "No new commits")
if [ "$COMMIT_LIST" != "No new commits" ]; then
    gh pr comment "$PR_NUM" --body "Updated with latest changes:

$COMMIT_LIST

Status: $FINAL_STATUS"
fi
```

### Important Notes:
- PR description should include:
  - Summary of changes
  - List of commits
  - Files changed
  - Test status
- Target the base branch specified (default: main)

**Never:**
- Add "Co-authored-by" or any Claude signatures
- Include "Generated with Claude Code" or similar messages
- Add any AI/assistant attribution to the PR
- Use emojis in PR title or description
- Modify git config

Create/update the PR entirely in the user's name using existing git configuration.

Proceed with pushing and creating/updating the PR.
