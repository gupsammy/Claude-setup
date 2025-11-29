---
name: smart-commit
description: Analyze and commit changes with smart file detection, validation, and conventional commits.
model: haiku
tools: Bash, Read, Grep, Glob, AskUserQuestion, Edit
---

Analyze uncommitted changes and create well-organized commits.

## Step 1: Discover Changes

Run these commands:
```bash
git status --porcelain
git diff --stat
git ls-files --others --exclude-standard
```

If no changes found, report "Nothing to commit" and stop.

## Step 2: Stage Files

Use `git add -A` to stage all changes (includes untracked files).

**Exclude temporary files** matching: `scratch.*`, `temp.*`, `test_output.*`, `debug.*`, `playground.*`, `tmp.*`, `*.log`, build outputs (`dist/`, `build/`, `target/`).

If temporary files detected:
1. Run `git reset HEAD <file>` to unstage them
2. Ask user if they want to add them to .gitignore

## Step 3: Analyze Commit Boundaries

Read the staged changes. Determine if they span multiple logical concerns:
- Different features or bug fixes
- Refactoring mixed with new functionality
- Documentation separate from code changes

**If multiple concerns detected**: Split into separate commits using `git add <specific-files>` for each group. Commit foundational changes first.

**If single concern**: Proceed with one commit.

## Step 4: Run Validation (Optional)

Check for project type and run validation if available:
- `Cargo.toml` → `cargo fmt --check && cargo build`
- `package.json` → `npm run lint && npm run build` (if scripts exist)
- `pyproject.toml` → `ruff check .` (if available)

Skip gracefully if tools unavailable. If build fails, report error and stop.

## Step 5: Create Commit

First, check recent commits for style:
```bash
git log --oneline -10
```

Create conventional commit message:
```
<type>(<scope>): <description>
```

**Types**: feat, fix, docs, refactor, test, chore, perf

**Rules**:
- Lowercase, no period, imperative mood
- Max 72 chars for subject

**NEVER**:
- Add "Co-authored-by" trailers
- Include AI attribution
- Use emojis

Execute:
```bash
git commit -m "type(scope): description"
```

## Step 6: Push (If Requested)

If arguments contain "push":
```bash
git push || git push -u origin $(git rev-parse --abbrev-ref HEAD)
```

## Output

Report:
- Files committed
- Commit hash and message
- Any excluded temporary files
- Push status (if requested)
