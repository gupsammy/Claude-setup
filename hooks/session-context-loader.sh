#!/bin/bash
# Session Context Loader - SessionStart Hook
# Parses previous session(s) at startup to provide continuity.
#
# Selection Algorithm:
# 1. Iterate through recent JSONL sessions (excluding current and agent sessions)
# 2. For each session, check exchange count:
#    - 1 exchange: skip (noise - PR commits, quick queries)
#    - 2 exchanges: load it, keep looking for another (up to MAX_SESSIONS total)
#    - >2 exchanges: load it and stop (sufficient context)
# 3. Result: either one >2-exchange session OR up to two 2-exchange sessions
#
# No state files, no latest.md - just reads Claude's existing session files.

set -euo pipefail

HOOKS_DIR="$HOME/.claude/hooks"
MAX_SESSIONS=2

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

# Only inject context on fresh sessions
if [ "$SOURCE" != "startup" ] && [ "$SOURCE" != "clear" ]; then
    echo '{}'
    exit 0
fi

if [ -z "$CWD" ] || [ -z "$SESSION_ID" ]; then
    echo '{}'
    exit 0
fi

# Find project's session directory
CLAUDE_PROJECT_PATH=$(echo "$CWD" | sed 's/[\/.]/-/g')
SESSIONS_DIR="$HOME/.claude/projects/$CLAUDE_PROJECT_PATH"

if [ ! -d "$SESSIONS_DIR" ]; then
    echo '{}'
    exit 0
fi

# Find candidate sessions: sorted by mtime (newest first), excluding current and agent sessions
# Optimized: uses find+stat in batch instead of per-file stat calls
find_candidates() {
    # Get all jsonl files with their mtime in one efficient find call
    find "$SESSIONS_DIR" -maxdepth 1 -name "*.jsonl" -type f -exec stat -f '%m %N' {} + 2>/dev/null | \
        sort -rn | \
        while read -r mtime filepath; do
            basename=$(basename "$filepath" .jsonl)
            # Skip current session and agent sessions
            [ "$basename" = "$SESSION_ID" ] && continue
            [[ "$basename" == agent-* ]] && continue
            echo "$filepath"
        done
}

# Select sessions based on exchange count algorithm
SESSIONS_TO_LOAD=()
while IFS= read -r candidate; do
    [ -z "$candidate" ] && continue
    count=$(python3 "$HOOKS_DIR/parse-session.py" --count-only "$candidate" 2>/dev/null || echo "0")

    # Skip 1-exchange sessions (noise - PR commits, quick queries)
    [ "$count" -eq 1 ] && continue

    # 2-exchange: load it, keep looking unless we've hit the limit
    if [ "$count" -eq 2 ]; then
        SESSIONS_TO_LOAD+=("$candidate")
        [ ${#SESSIONS_TO_LOAD[@]} -ge "$MAX_SESSIONS" ] && break
        continue
    fi

    # >2 exchanges: load it and stop (sufficient context)
    if [ "$count" -gt 2 ]; then
        SESSIONS_TO_LOAD+=("$candidate")
        break
    fi
done < <(find_candidates)

if [ ${#SESSIONS_TO_LOAD[@]} -eq 0 ]; then
    echo '{}'
    exit 0
fi

# Parse and concatenate context from selected sessions
CONTEXT=""
for session in "${SESSIONS_TO_LOAD[@]}"; do
    part=$(python3 "$HOOKS_DIR/parse-session.py" "$session" 2>/dev/null || echo "")
    if [ -n "$part" ]; then
        [ -n "$CONTEXT" ] && CONTEXT="${CONTEXT}

---

"
        CONTEXT="${CONTEXT}${part}"
    fi
done

if [ -z "$CONTEXT" ]; then
    echo '{}'
    exit 0
fi

# Wrap in section header
FULL_CONTEXT="## Previous Session Context

$CONTEXT"

# Escape for JSON and output
ESCAPED_CONTEXT=$(echo "$FULL_CONTEXT" | jq -Rs '.')
cat << EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ESCAPED_CONTEXT}}
EOF
