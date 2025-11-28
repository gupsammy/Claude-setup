---
name: reflect
description: This skill should auto-trigger when the user asks to "reflect on my work", "what have I learned", "where were we", "identify my knowledge gaps", "review my coding habits", "find my antipatterns", "extract decisions for CLAUDE.md", "do a retrospective", "mentor review", "catch up on project", or wants insights from their conversation history. Analyzes past sessions to surface learning patterns, mistakes, growth areas, and actionable insights.
---

# Reflect - Conversation History Analysis

Analyze conversation history and git activity to extract insights. Uses iterative discovery combining comprehensive extraction and semantic search, with each enriching the other.

## Two Core Tools

### 1. Comprehensive Extraction Script

Fetches raw conversation data from `~/.claude/projects/`:

```bash
# Project-specific (activity-based: N days from last activity, not from today)
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --days 3
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --days 7 --project /path/to/project

# Cross-project (calendar-based: N days from today)
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --days 2 --all-projects
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --days 3 --from-today

# By conversation IDs (from episodic-memory search)
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --ids abc123,def456
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --paths /full/path/to/conv.jsonl
```

**Important**: For project-specific queries, `--days` counts back from the most recent activity on that project, not from today. This ensures "where were we" works when returning to older projects. Use `--all-projects` or `--from-today` for calendar-based timeframes.

Returns: session IDs, summaries, user requests, tool uses, files modified, errors, timestamps.

### 2. Episodic-Memory MCP Search (ID Discovery Only)

Use semantic search to find relevant conversation IDs/paths:

```
mcp__plugin_episodic-memory_episodic-memory__search
  query: "pattern to find" or ["term1", "term2"] for AND search
  limit: number of results
  after: "YYYY-MM-DD" date filter
  before: "YYYY-MM-DD" date filter
```

Returns: conversation paths, snippets, relevance scores.

**Critical**: Use MCP search ONLY to discover conversation paths. NEVER use `__read` to read conversations. Always pass discovered paths to the extraction script:

```bash
python3 ~/.claude/skills/reflect/scripts/extract_conversations.py --paths /path/to/conv1.jsonl,/path/to/conv2.jsonl
```

The script is more efficient and provides structured output optimized for analysis.

## Iterative Discovery Process

Do NOT run tools in parallel with fixed queries. Instead, iterate:

```
1. INITIAL EXTRACTION
   ├─ Run script for default timeframe (per lens)
   ├─ Gather git history (depth per lens)
   └─ Review raw data, identify themes

2. FORM HYPOTHESES
   ├─ What patterns are emerging?
   ├─ What topics recur?
   └─ What needs deeper investigation?

3. SEMANTIC ENRICHMENT
   ├─ Use MCP search with hypothesis-driven queries
   ├─ Get conversation paths from results
   ├─ Fetch full conversations via script --paths
   └─ Review new data

4. DEEPER ANALYSIS
   ├─ New patterns from fetched conversations?
   ├─ Form new hypotheses if needed
   └─ Loop back to step 3 if more discovery needed

5. SYNTHESIZE
   ├─ Combine all findings
   ├─ Apply lens-specific format
   └─ Suggest follow-up actions
```

This adaptive approach discovers more than fixed parallel queries.

## Analytical Lenses

Each lens has default timeframe and git depth. Adjust based on user request.

| Lens | Trigger Phrases | Default Time | Time Mode | Git Depth |
|------|-----------------|--------------|-----------|-----------|
| **where-were-we** | "where were we", "catch up", "recap" | 2-3 days | Activity | Full recent |
| **learning** | "what did I learn", "reflect", "insights" | 2 weeks | Calendar | Light |
| **gaps** | "gaps", "struggling with", "what should I study" | 1 month | Calendar | Minimal |
| **mentor** | "mentor", "senior review", "feedback" | 1-2 weeks | Calendar | Moderate |
| **retro** | "retro", "retrospective", "how did it go" | Project scope | Activity | Full |
| **decisions** | "decisions", "document choices", "CLAUDE.md" | Project lifetime | Activity | Architectural |
| **antipatterns** | "antipatterns", "bad habits", "mistakes I keep making" | 1 month | Calendar | Moderate |

**Time Mode**:
- **Activity**: Days counted from last project activity (use default `--days` for project-specific)
- **Calendar**: Days counted from today (use `--all-projects` or `--from-today`)

### where-were-we Lens

Project-focused context restoration. Prioritize:
- Recent conversation activity for current project
- Current git state: branch, uncommitted changes, recent commits
- Active work: what files were touched, what's in progress
- Next steps mentioned in conversations

Output: concise status of where work stands.

### learning Lens

Extract growth indicators:
- Breakthroughs: successful solutions after struggle
- Mistakes: corrections, failed attempts, lessons learned
- New concepts: first encounters with APIs/patterns
- Skills practiced: technologies and domains worked on

Output: what was learned, what's improving, what needs attention.

### gaps Lens

Identify knowledge deficiencies:
- Repeated questions on same topics across sessions
- Extended struggles: long back-and-forth, multiple approaches
- Dependency signals: tasks needing step-by-step guidance

Output: topics needing study, confidence assessment.
Follow-up: suggest `learn-anything` skill for identified gaps.

### mentor Lens

Evaluate process quality:
- Planning: evidence of design before coding
- Debugging: systematic vs. random approaches
- Code quality: patterns used, refactoring discussions
- Missed opportunities: better approaches suggested but not used

Output: strengths, growth areas, specific recommendations.

### retro Lens

Project/feature retrospective:
- Timeline: how the solution evolved, pivots made
- Successes: approaches that worked well
- Struggles: blockers, time sinks
- Debt: shortcuts, deferred work, known issues

Output: what went well, what to improve, lessons for next time.

### decisions Lens

Extract architectural choices:
- Trade-off discussions: alternatives evaluated
- Rationale: why choices were made
- Conventions: patterns that emerged

Output: decisions with context.
Follow-up: suggest `/updateclaudemd` to document decisions.

### antipatterns Lens

Find recurring negative patterns:
- Repeated mistakes: same bugs, misunderstandings
- Inefficient workflows: manual work when automation exists
- Copy-paste patterns: same questions recurring

Output: identified antipatterns with examples, corrections.

## Git Integration

For project-scoped analysis, gather git context:

```bash
# Recent activity
git log --oneline --since="3 days ago"
git status
git branch -v

# For retro/mentor: deeper history
git log --oneline --since="2 weeks ago" --stat
git shortlog -sn --since="1 month ago"

# For decisions: architectural changes
git log --oneline --all --merges
```

Git depth varies by lens — use the table above as guide.

## Project Scoping

Determine scope from user request:

**Project-specific** ("where were we", "retro on invoice project"):
- Filter conversations to that project
- Full git integration
- Use script with `--project` flag

**Cross-project** ("reflect on my week", "what gaps do I have"):
- Use `--all-projects` flag
- Identify which projects were active
- If few projects (1-3): include git for each
- If many: summarize, focus on conversation patterns
- Episodic-memory excels here for cross-project patterns

## Output Guidelines

- Concise and actionable over exhaustive
- Specific: include file paths, dates, project names
- Evidence-based: reference specific conversations/commits
- Actionable: every finding suggests a response
- Adapt format to the lens

## Integration Points

- **episodic-memory MCP search**: ID/path discovery only (never use `__read` for full conversations)
- **extract_conversations.py**: ALL conversation reading (by timeframe, IDs, or paths)
- **learn-anything skill**: Follow-up for identified knowledge gaps
- **updateclaudemd command**: Follow-up for documenting decisions
- **Git tools**: Context for project-scoped analysis

## Additional Resources

- **`scripts/extract_conversations.py`**: Raw conversation extraction
- **`references/synthesis-templates.md`**: Output templates per lens
- **`examples/`**: Sample outputs
