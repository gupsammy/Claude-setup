# Smart Git Commit

Analyze the changes and create a meaningful commit message.

**Pre-Commit Quality Checks:**
Before committing, verify:
- Build passes (if build command exists)
- Tests pass (if test command exists)
- Linter passes (if lint command exists)
- No obvious errors in changed files

First, check if this is a git repository

```bash
# Verify we're in a git repository or initialize one
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Not a git repository. Initializing..."
    git init
fi

# Sync with remote branch if it exists
if git rev-parse --abbrev-ref --symbolic-full-name @{u} > /dev/null 2>&1; then
    echo "Syncing with remote branch..."
    git pull || echo "⚠️  Pull failed, continuing with local changes"
else
    echo "No remote tracking branch configured, skipping pull"
fi

# Check if we have changes to commit
if ! git diff --cached --quiet || ! git diff --quiet; then
    echo "Changes detected:"
    git status --short
else
    echo "No changes to commit"
    exit 0
fi

# Show detailed changes
git diff --cached --stat
git diff --stat
```

Analyze the changes to determine:
1. What files were modified
2. The nature of changes (feature, fix, refactor, etc.)
3. The scope/component affected

If the analysis or commit encounters errors:
- Explain what went wrong
- Suggest how to resolve it
- Ensure no partial commits occur

```bash
# If nothing is staged, stage modified files (not untracked)
if git diff --cached --quiet; then
    echo "No files staged. Staging modified files..."
    git add -u
fi

# Show what will be committed
git diff --cached --name-status
```

Based on the analysis, create a conventional commit message:
- **Type**: feat|fix|docs|style|refactor|test|chore
- **Scope**: component or area affected (optional)
- **Subject**: clear description in present tense
- **Body**: why the change was made (if needed)

```bash
# Create the commit with the analyzed message
# Example: git commit -m "fix(auth): resolve login timeout issue"
```

The commit message should be concise, meaningful, and follow the project's conventions detected from recent commits.

**Important**: Never:
- Add "Co-authored-by" or any Claude signatures
- Include "Generated with Claude Code" or similar messages
- Modify git config or user credentials
- Add any AI/assistant attribution to the commit
- Use emojis in commits, PRs, or git-related content

Use only the existing git user configuration, maintaining full ownership and authenticity of commits.