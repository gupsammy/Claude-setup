---
name: session-search
description: Search past conversations by keywords, timeframe, or ID. Triggers on "search sessions", "find that conversation", "what did we work on", "look up past discussion about X", "where were we", "what did I learn", "knowledge gaps", "retrospective". Extracts clean conversation data and applies analytical lenses for structured insights.
---

# session-search - Search & Extract Past Conversations

## Primary Tool

`extract_conversations.py` - curated parser that filters noise and extracts high-value content.

```bash
# Basic usage
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 3

# Key options
--days N              # Days to look back
--all-projects        # Cross-project (calendar-based from today)
--project /path       # Filter to specific project
--compact             # Only user/assistant text, no tool details
--min-exchanges N     # Skip sessions with < N user messages
--ids abc,def         # Fetch specific conversations
--paths /path/to.jsonl
```

**Filtering**: Removes tool_result noise, empty assistant turns, meta messages. Shortens paths (`~/`) and timestamps (`HH:MM on Mon DD`).

**Modes**: Default shows files modified, tool counts, errors, user requests. `--compact` shows actual conversation flow (better for learning/pattern analysis).

## Search Workflow

1. **Grep for keywords** (generate semantic synonyms):
   ```bash
   grep -l -E "auth|login|session|JWT" ~/.claude/projects/*/*.jsonl
   ```

2. **Extract with script**:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --paths /found/conv.jsonl --compact
   ```

3. **Apply lens** for structured analysis (see below).

## Keyword → Lens Routing

| User Says | Lens |
|-----------|------|
| "where were we", "catch up", "recap" | restore-context |
| "what I learned", "growth", "reflect" | extract-learnings |
| "gaps", "struggling", "don't understand" | find-gaps |
| "mentor", "review process", "feedback" | review-process |
| "retro", "how did it go", "project review" | run-retro |
| "decisions", "choices", "CLAUDE.md" | extract-decisions |
| "bad habits", "mistakes", "antipatterns" | find-antipatterns |

## Lenses

### restore-context
Context restoration when returning to a project.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 3 --min-exchanges 2
```
Also gather: `git status`, `git log --oneline -5`, `git branch -v`

### extract-learnings
Surface breakthroughs, mistakes corrected, new concepts, skills practiced.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 14 --all-projects --compact --min-exchanges 2
```

### find-gaps
Identify repeated questions, extended struggles, areas needing guidance.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 30 --all-projects --compact --min-exchanges 3
```
Follow-up: suggest `learn-anything` skill for identified gaps.

### review-process
Evaluate planning habits, debugging methodology, code quality patterns.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 14 --all-projects --compact --min-exchanges 2
```

### run-retro
Project retrospective: timeline, what worked, what struggled, tech debt.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 30 --project /path/to/project --min-exchanges 2
```

### extract-decisions
Extract architectural choices, trade-offs, conventions.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 90 --project /path/to/project
```
Follow-up: suggest `/updateclaudemd` to document.

### find-antipatterns
Surface recurring mistakes, inefficient workflows, repeated issues.
```bash
python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 30 --all-projects --compact --min-exchanges 3
```

## References

- `references/lens-workflows.md` - Detailed workflows per lens
- `references/synthesis-templates.md` - Output templates
- `examples/` - Sample outputs
