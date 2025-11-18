---
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion, Edit
description: Intelligently analyze and commit changes with smart file detection and validation. Use automatically when user asks to "commit".
argument-hint: [push] - optionally push after committing
---

# Smart Git Commit

Analyze all uncommitted changes (including untracked files) and create meaningful, well-organized commits.

## Process

### 1. Change Discovery
Detect all uncommitted changes including untracked files. Use `git add -A` to include untracked files, not `git add -u`.

### 2. File Classification
Classify files as production code (commit) or temporary artifacts (exclude). Temporary indicators: `scratch.*`, `temp.*`, `test_output.*`, `debug.*`, `playground.*`, exploratory docs, build outputs, logs, experiments.

**For temporary files:** Auto-exclude, suggest `.gitignore` additions, show exclusions with rationale.

### 3. Logical Commit Boundaries
Analyze production files to detect if changes span multiple logical concerns:
- Different features or bug fixes
- Multiple unrelated refactorings
- Mix of feature code and documentation updates
- Changes to different subsystems or modules

**If multiple concerns detected:**
- Automatically split into separate commits
- Group related changes together
- Create commits in logical order (e.g., refactors before features that depend on them)

**If single logical concern:**
- Create one well-crafted commit

### 4. Tech Stack Validation
Detect project type (Cargo.toml=Rust, package.json=JS/TS, pyproject.toml=Python, *.swift=Swift, go.mod=Go) and run appropriate checks:
- **Rust**: fmt, clippy, test, build
- **JS/TS**: lint, test, build (via bun/pnpm)
- **Python**: black, ruff, pytest
- **Swift**: swiftformat, test, build
- **Go**: fmt, vet, test, build

Skip checks gracefully if tools unavailable. If checks fail, report clearly and abort commit.

### 5. Commit Message Creation
For each commit, create a conventional commit message:
- **Type**: feat, fix, docs, style, refactor, test, chore, perf
- **Scope**: Component or area affected (optional but encouraged)
- **Subject**: Clear, present-tense description
- **Body**: Additional context if needed (why the change was made)

Analyze recent commits (`git log --oneline -10`) to match the project's style and conventions.

**Critical constraints:**
- Never add "Co-authored-by" or any Claude/AI signatures
- Never include "Generated with Claude Code" or similar attribution
- Never use emojis in commit messages
- Use only the existing git user configuration

### 6. Push Handling
**If ARGUMENTS contains "push":**
- After all commits succeed, push to remote with `git push`

**Otherwise:**
- Commit locally only, do not push

## Key Implementation Details

**Use `git add -A`** to stage both modified and untracked files (not `git add -u` which ignores untracked files).

When creating commits, ensure they are atomic and focused. Each commit should represent one logical change that could be reverted independently.

Show clear progress as you work through classification, validation, and commit creation.
