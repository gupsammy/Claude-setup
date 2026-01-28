---
name: commit
description: >
  Analyze and commit changes with intelligent file grouping and conventional commits.
  Use when user says "commit my changes", "commit this", "git commit", "save my work",
  "stage and commit", or mentions committing code. Also triggers on "create a commit"
  or "commit what I've done".
model: claude-sonnet-4-5 
context: fork
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Skill
  - AskUserQuestion
---

# Commit

Analyze uncommitted changes and create well-organized commits using conventional commit format.

## Workflow

### 1. Discover Changes

```bash
git status --porcelain
git diff --stat
```

If no changes, report "Nothing to commit" and stop.

### 2. Stage Files

Run `git add -A` to stage all changes.

**Exclude temporary files** matching: `scratch.*`, `temp.*`, `debug.*`, `playground.*`, `*.log`, `dist/`, `build/`, `target/`, `node_modules/`.

If temporary files detected:
1. Unstage with `git reset HEAD <file>`
2. Ask user if they want to add to .gitignore

### 3. Analyze Commit Boundaries

For each changed file, write a one-line PURPOSE description (not file location).

**Group by PURPOSE, not directory:**
- Same goal = one commit
- Different goals = separate commits

Ask yourself: "Would I explain these as one thing or multiple things?"

**Signs of separate concerns:**
- "Added X" AND "Fixed Y" (feature + bugfix)
- Changes that could be reverted independently

If multiple concerns: Use `git reset HEAD` then `git add <specific-files>` for each group. Commit foundational changes first.

**Handle renames (R status):** When splitting, add BOTH old and new paths to preserve rename detection.

### 4. Validate (if available)

Check for project type and run validation:
- `Cargo.toml` → `cargo fmt --check && cargo build`
- `package.json` → `npm run lint && npm run build` (if scripts exist)
- `pyproject.toml` → `ruff check .` (if available)

Skip gracefully if tools unavailable. If validation fails, report error and stop.

### 5. Create Commit

Check recent commit style:
```bash
git log --oneline -10
```

Use conventional commit format:
```
<type>(<scope>): <description>
```

**Types:** feat, fix, docs, refactor, test, chore, perf

**Rules:**
- Lowercase, no period, imperative mood
- Max 72 chars for subject
- NO Co-authored-by trailers
- NO AI attribution
- NO emojis

### 6. Push (if requested)

If user mentions "push" or arguments contain "push", then push using git push.

## Output

Report: files committed, commit hash and message, excluded temporary files.
