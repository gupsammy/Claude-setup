#!/bin/bash
# Fast file suggestion for Claude Code using fd + fzf
# Benchmarked at ~150ms vs ~1000ms+ for find+grep

QUERY=$(jq -r '.query // ""')
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 1

fd --type f --hidden --follow --exclude .git . 2>/dev/null | fzf --filter "$QUERY" | head -15
