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

For each changed file, write a one-line description of what the change accomplishes (focus on PURPOSE, not file location).

Example analysis:
```
hooks/session-context-loader.sh → "loads session context on startup"
hooks/parse-session.py → "parses JSONL session files"
skills/session-search/SKILL.md → "defines session search skill"
plugins/installed_plugins.json → "removes deprecated plugin"
```

**Group changes by PURPOSE, not directory:**
- Changes serving the same goal = one commit
- Changes serving different goals = separate commits

Ask: "If I explained these changes to a teammate, would I describe them as one thing or multiple things?"

**Signs of separate concerns:**
- "Added X" AND "Fixed Y" (feature + bugfix)
- "Renamed/migrated A" AND "Improved B" (migration + enhancement)
- Changes that could be reverted independently without breaking each other

**Output your proposed groupings** before committing:
```
Group 1 (refactor: session context loading): file1, file2, file3
Group 2 (refactor: migrate reflect to session-search): file4, file5
```

**Handle renames carefully (R status in git status --porcelain):**
When splitting commits, `git reset HEAD` breaks rename detection. The old file deletion stays staged, but the new file becomes untracked.

Before resetting, note all renames:
```bash
git status --porcelain | grep "^R"
# Output: R  old/path.py -> new/path.py
```

When adding files for a group that includes a rename, add BOTH paths:
```bash
git add old/path.py new/path.py  # Adds deletion + new file together
```

**If multiple concerns detected**: Use `git reset HEAD` then `git add <specific-files>` for each group. For renames, add both old and new paths. Commit foundational changes first.

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
