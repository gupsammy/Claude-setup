#!/bin/bash
# Session Context Loader - SessionStart Hook
# 1. Maps current session to its JSONL file (for Stop hook to use)
# 2. Loads previous session's parsed context (for startup/clear)
# 3. Injects git state (always)

set -euo pipefail

CONTEXT_DIR="$HOME/.claude/session-context"

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

if [ -z "$CWD" ] || [ -z "$SESSION_ID" ]; then
    echo '{}'
    exit 0
fi

# Project hash for directory structure
PROJECT_HASH=$(echo -n "$CWD" | md5 | head -c 16)
PROJECT_DIR="$CONTEXT_DIR/$PROJECT_HASH"
SESSIONS_DIR="$PROJECT_DIR/sessions"

mkdir -p "$SESSIONS_DIR"
echo "$CWD" > "$PROJECT_DIR/.project-path"

# Map session to JSONL file
CLAUDE_PROJECT_PATH=$(echo "$CWD" | sed 's/[\/.]/-/g')
JSONL_PATH="$HOME/.claude/projects/$CLAUDE_PROJECT_PATH/$SESSION_ID.jsonl"

cat > "$SESSIONS_DIR/$SESSION_ID.state" << EOF
{"jsonl_path":"$JSONL_PATH","project_hash":"$PROJECT_HASH","exchange_count":0,"parsing_enabled":false,"last_parsed_line":0}
EOF

# Build context
CONTEXT=""

if [ "$SOURCE" = "startup" ] || [ "$SOURCE" = "clear" ]; then
    LATEST_MD="$PROJECT_DIR/latest.md"
    if [ -f "$LATEST_MD" ]; then
        LATEST_CONTENT=$(cat "$LATEST_MD")
        CONTEXT+="## Previous Session Context\n\n$LATEST_CONTENT\n\n"
    fi
fi

if git -C "$CWD" rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "detached")
    UNCOMMITTED=$(git -C "$CWD" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    LAST_COMMITS=$(git -C "$CWD" log --oneline -3 2>/dev/null || echo "No commits")

    CONTEXT+="## Current Git State\n\n"
    CONTEXT+="- **Branch**: $BRANCH\n"
    CONTEXT+="- **Uncommitted files**: $UNCOMMITTED\n"
    CONTEXT+="- **Recent commits**:\n"

    while IFS= read -r commit; do
        [ -n "$commit" ] && CONTEXT+="  - $commit\n"
    done <<< "$LAST_COMMITS"
fi

if [ -z "$CONTEXT" ]; then
    echo '{}'
    exit 0
fi

ESCAPED_CONTEXT=$(echo -e "$CONTEXT" | jq -Rs '.')
cat << EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ESCAPED_CONTEXT}}
EOF
