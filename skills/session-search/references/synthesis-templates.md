# Synthesis Templates for session-search

Templates and guidance for structuring output from each analytical lens.

## General Principles

1. **Prioritize significance**: Surface the 3-5 most important findings, not exhaustive lists
2. **Be specific**: Include file paths, dates, project names when relevant
3. **Make it actionable**: Every finding should suggest a response
4. **Show evidence**: Brief quotes or references to support observations
5. **Keep it scannable**: Use clear structure, avoid walls of text

## extract-learnings Template

```markdown
## Learning Reflection: [Timeframe]

### Summary
[2-3 sentences capturing the overall learning trajectory]

### Breakthroughs
- **[Topic/Concept]** ([Date/Project])
  [What clicked, why it matters]

- **[Topic/Concept]** ([Date/Project])
  [What clicked, why it matters]

### Mistakes & Lessons
- **[What went wrong]** → **Lesson**: [What to do differently]
  [Brief context of the mistake]

### New Territory Explored
- [Technology/Pattern]: [What was learned]
- [Technology/Pattern]: [What was learned]

### Skills Practiced
[Heat map or frequency of different skill areas]
- Heavy focus: [areas]
- Some practice: [areas]
- Minimal: [areas]

### Suggested Next Steps
- [Specific actionable recommendation]
- [Specific actionable recommendation]
```

## find-gaps Template

```markdown
## Knowledge Gap Analysis: [Timeframe]

### Summary
[2-3 sentences on overall gap landscape]

### Recurring Struggles
| Topic | Frequency | Projects Affected | Severity |
|-------|-----------|-------------------|----------|
| [Topic] | [N times] | [List] | High/Med/Low |

### Deep Dive: [Top Gap]
- **Pattern observed**: [What keeps happening]
- **Root cause hypothesis**: [Why this might be a gap]
- **Evidence**: [Specific examples from conversations]

### Dependency Assessment
| Task Type | Independence Level | Notes |
|-----------|-------------------|-------|
| [Type] | High/Med/Low | [Context] |

### Recommended Learning Path
1. **[Gap #1]**: [Specific resource or approach]
2. **[Gap #2]**: [Specific resource or approach]

### Follow-up
Consider using the `learn-anything` skill to create a structured learning plan for [top gap].
```

## review-process Template

```markdown
## Mentor Review: [Timeframe]

### Summary
[2-3 sentences on overall process quality]

### Strengths Observed
- **[Strength]**: [Evidence and why it matters]
- **[Strength]**: [Evidence and why it matters]

### Growth Opportunities
- **[Area]**: [Current pattern] → [Better pattern]
  [Specific examples and recommendations]

### Process Observations
- **Planning**: [Assessment of planning before coding]
- **Debugging**: [Assessment of debugging methodology]
- **Code Quality**: [Assessment of quality focus]

### Specific Recommendations
1. [Concrete, actionable recommendation]
2. [Concrete, actionable recommendation]
3. [Concrete, actionable recommendation]

### Patterns to Reinforce
[Positive patterns worth consciously continuing]
```

## run-retro Template

```markdown
## Retrospective: [Project/Feature] ([Timeframe])

### Summary
[2-3 sentences on how the work went overall]

### Timeline
- **[Date]**: [Milestone or significant event]
- **[Date]**: [Milestone or significant event]
- **[Date]**: [Milestone or significant event]

### What Went Well
- **[Success]**: [Why it worked, what to repeat]
- **[Success]**: [Why it worked, what to repeat]

### What Could Improve
- **[Challenge]**: [What happened, what to do differently]
- **[Challenge]**: [What happened, what to do differently]

### Technical Debt Created
| Debt Item | Severity | Effort to Fix | Notes |
|-----------|----------|---------------|-------|
| [Item] | High/Med/Low | Small/Med/Large | [Context] |

### Key Decisions Made
- [Decision]: [Rationale]
- [Decision]: [Rationale]

### Recommendations for Next Time
1. [Specific recommendation]
2. [Specific recommendation]
```

## find-antipatterns Template

```markdown
## Antipattern Analysis: [Timeframe]

### Summary
[2-3 sentences on recurring negative patterns]

### Identified Antipatterns

#### [Antipattern Name]
- **What**: [Description of the pattern]
- **Frequency**: [How often it occurs]
- **Examples**:
  - [Specific instance with date/project]
  - [Specific instance with date/project]
- **Better approach**: [What to do instead]
- **Trigger to watch**: [How to notice this happening]

#### [Antipattern Name]
[Same structure]

### Root Causes
[Analysis of why these patterns might be occurring]

### Action Plan
| Antipattern | Intervention | Effort |
|-------------|--------------|--------|
| [Pattern] | [What to do] | Low/Med/High |

### Suggested Safeguards
[Habits, checks, or tools to prevent recurrence]
```

## extract-decisions Template

```markdown
## Decision Extraction: [Timeframe/Project]

### Summary
[2-3 sentences on decisions captured]

### Architectural Decisions

#### [Decision Title]
- **Choice**: [What was decided]
- **Context**: [Why this decision was needed]
- **Alternatives considered**: [What else was evaluated]
- **Rationale**: [Why this choice won]
- **Trade-offs accepted**: [What was given up]
- **Date**: [When decided]

#### [Decision Title]
[Same structure]

### Conventions Established
| Area | Convention | Example |
|------|------------|---------|
| [Naming] | [Pattern] | [Example] |
| [Structure] | [Pattern] | [Example] |

### For CLAUDE.md
```markdown
## Decisions & Conventions

[Ready-to-paste content for CLAUDE.md]
```

### Follow-up
Run `/updateclaudemd` with these decisions to incorporate into project documentation.
```

## Flexible Analysis Template

For extrapolated analyses that don't fit predefined lenses:

```markdown
## [Analysis Type]: [Timeframe/Scope]

### Summary
[2-3 sentences on findings]

### Key Findings
[Organized by whatever structure fits the analysis]

### Patterns Observed
[Cross-cutting observations]

### Evidence
[Specific examples supporting findings]

### Implications
[What this means for the user]

### Recommendations
[Actionable next steps]

### Related Analysis
[Other lenses that might provide additional insight]
```

## Output Length Guidelines

| Lens | Typical Length | When to Expand |
|------|---------------|----------------|
| extract-learnings | 300-500 words | Rich period of growth |
| find-gaps | 250-400 words | Multiple significant gaps |
| review-process | 300-450 words | Complex process patterns |
| run-retro | 400-600 words | Long or complex project |
| find-antipatterns | 300-500 words | Multiple recurring issues |
| extract-decisions | 300-600 words | Many architectural choices |

Err on the side of concise. Users can always ask for more detail on specific findings.
