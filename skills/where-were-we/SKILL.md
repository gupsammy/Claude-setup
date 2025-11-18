---
name: where-were-we
description: Get back up to speed on a project by analyzing recent chat history, commits, branches, and PRs. Use when returning to a project after time away. Keywords: recap, catch-up, catch up, what did we do, project status, recent activity.
---

# Where Were We? - Project Activity Recap

## Overview

Help users get back up to speed on a project by analyzing recent chat history, git activity, and current state. Default to last 2 days of activity, covering roughly 5-10 recent sessions.

## Parameters

- **Format**: `summary` (default), `timeline`, `topics`, `detailed`
- **Timeframe**: Last 2 days (default), or custom like "last week", "last 3 days", "yesterday"

Examples:
- "where were we" → summary, last 2 days
- "catch up in timeline format" → timeline view, last 2 days
- "recap last week by topics" → topic grouping, last 7 days
- "where were we detailed last 3 days" → detailed view, last 3 days

## What to Gather

### 1. Project Context

- Identify current project directory
- Locate corresponding folder in `~/.claude/projects/` (path with slashes replaced by dashes)
- Find recent `.jsonl` conversation files within the timeframe
- Prioritize substantial conversations, skip very short ones

### 2. Chat History Analysis

From each conversation file (JSONL format, one message per line):

**Extract:**
- User requests and questions
- Actions taken (files modified, commands run)
- Decisions made and rationale
- Problems encountered and solutions
- Explicit TODOs or next steps mentioned

**Identify:**
- File paths worked on
- Tools used (Read, Edit, Write, Bash operations)
- Branch context during conversations
- Conversation topics and themes

**Note:**
- Session timestamps for timeline
- Branch switches and git activity
- Major milestones (commits, PRs created)

### 3. Git Activity

Gather current state:
- Recent commits within timeframe
- Active branches with last commit info
- Current branch and status
- Uncommitted changes
- Open PRs (if gh CLI available)
- Stashed work

### 4. Smart Filtering

- Focus on first and last parts of long conversations (usually most important)
- Weight tool uses heavily (actual work happened)
- Prioritize conversations on current branch
- Skip agent conversations for overview (include in detailed if relevant)
- Ignore thinking blocks unless detailed format requested

## Output Formats

### Summary (Default)

Concise overview structured as:
- Period covered and sessions analyzed
- High-level summary of main activities
- Key topics worked on
- Git activity snapshot (commits, branches, PRs)
- Current state (uncommitted changes, active work)
- Next steps or blockers

### Timeline

Chronological view:
- Group by date
- Each session with time, description, files touched
- Interleave git commits
- Show branch context

### Topics

Group by subject area:
- Identify distinct topics from file patterns and conversation themes
- For each topic: what was done, files involved, status, related commits
- Useful for understanding parallel work streams

### Detailed

Comprehensive view:
- Include conversation excerpts for key decisions
- Show specific code changes discussed
- Full context on problem-solving attempts
- All tool calls and results
- Agent sub-conversations if relevant

## Output Guidelines

- **Be concise**: Actionable insights over exhaustive details
- **Highlight decisions**: Surface key choices made
- **Show momentum**: What's in progress, what's next
- **Context over content**: "Where we are" not just "what we did"
- **Use file paths**: Specific references jog memory
- **Note branches**: Context for parallel work
- **Handle missing data gracefully**: Works for non-git projects, missing history, etc.

## Usage Scenarios

- **Returning after time away**: Quick context on recent work and current state
- **Before meetings**: Summary of progress for reporting
- **Understanding parallel work**: Topic view shows different threads
- **Deep context**: Detailed view when you need to remember exact decisions and attempts
