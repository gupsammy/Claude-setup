# Lens Workflows

Detailed workflows for each analytical lens. Each lens has specific extraction parameters, analysis focus, and output structure.

## Lens Parameters

| Lens | Default Timeframe | Time Mode | Git Depth |
|------|-------------------|-----------|-----------|
| restore-context | 2-3 days | Activity | Full recent |
| extract-learnings | 2 weeks | Calendar | Light |
| find-gaps | 1 month | Calendar | Minimal |
| review-process | 1-2 weeks | Calendar | Moderate |
| run-retro | Project scope | Activity | Full |
| extract-decisions | Project lifetime | Activity | Architectural |
| find-antipatterns | 1 month | Calendar | Moderate |

**Time Mode**:
- **Activity**: Days counted from last project activity (use default `--days`)
- **Calendar**: Days counted from today (use `--all-projects` or `--from-today`)

---

## restore-context

**Purpose**: Context restoration when returning to a project.

### Workflow

1. Extract recent conversations for current project:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 3
   ```

2. Gather git state:
   ```bash
   git status
   git branch -v
   git log --oneline -10
   git diff --stat
   ```

3. Identify from conversations:
   - What files were being worked on
   - What tasks were in progress
   - Any blockers or issues mentioned
   - Next steps discussed

### Analysis Focus

- Recent conversation activity for current project
- Current git state: branch, uncommitted changes, recent commits
- Active work: what files were touched, what's in progress
- Next steps mentioned in conversations

### Output

Concise status of where work stands:
- Current branch and state
- Work in progress
- Last completed tasks
- Immediate next steps

---

## extract-learnings

**Purpose**: Surface growth indicators over time.

### Workflow

1. Extract conversations across projects:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 14 --all-projects
   ```

2. Search for learning signals:
   ```bash
   grep -l -E "learned|realized|understand now|got it|clicked" ~/.claude/projects/*/*.jsonl
   ```

3. Analyze for:
   - Breakthroughs: successful solutions after struggle
   - Mistakes: corrections, failed attempts, lessons learned
   - New concepts: first encounters with APIs/patterns
   - Skills practiced: technologies and domains worked on

### Analysis Focus

- Moments of understanding ("ah, that's how it works")
- Corrections made after errors
- New technologies or patterns encountered
- Repeated practice in specific areas

### Output

See `synthesis-templates.md` for the extract-learnings template.

---

## find-gaps

**Purpose**: Identify knowledge deficiencies.

### Workflow

1. Extract longer timeframe:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 30 --all-projects
   ```

2. Search for struggle signals:
   ```bash
   grep -l -E "confused|don't understand|struggling|help with" ~/.claude/projects/*/*.jsonl
   ```

3. Analyze for:
   - Repeated questions on same topics across sessions
   - Extended struggles: long back-and-forth, multiple approaches
   - Dependency signals: tasks needing step-by-step guidance

### Analysis Focus

- Topics that come up repeatedly
- Areas requiring extensive guidance
- Concepts that remain unclear
- Skills that need development

### Output

See `synthesis-templates.md` for the find-gaps template.

**Follow-up**: Suggest `learn-anything` skill for identified gaps.

---

## review-process

**Purpose**: Evaluate process quality like a senior engineer.

### Workflow

1. Extract recent work:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 14 --all-projects
   ```

2. Gather git context:
   ```bash
   git log --oneline --since="2 weeks ago" --stat
   ```

3. Analyze for:
   - Planning: evidence of design before coding
   - Debugging: systematic vs. random approaches
   - Code quality: patterns used, refactoring discussions
   - Missed opportunities: better approaches suggested but not used

### Analysis Focus

- Planning habits before implementation
- Debugging methodology (systematic vs. trial-and-error)
- Code quality focus (refactoring, patterns)
- Missed opportunities for improvement

### Output

See `synthesis-templates.md` for the review-process template.

---

## run-retro

**Purpose**: Project or feature retrospective.

### Workflow

1. Extract project conversations:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 30 --project /path/to/project
   ```

2. Gather full git history:
   ```bash
   git log --oneline --stat
   git log --oneline --all --merges
   ```

3. Analyze for:
   - Timeline: how the solution evolved, pivots made
   - Successes: approaches that worked well
   - Struggles: blockers, time sinks
   - Debt: shortcuts, deferred work, known issues

### Analysis Focus

- Evolution of the solution over time
- What worked and why
- What was difficult and why
- Technical debt accumulated

### Output

See `synthesis-templates.md` for the run-retro template.

---

## extract-decisions

**Purpose**: Extract architectural choices for documentation.

### Workflow

1. Extract project lifetime:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 90 --project /path/to/project
   ```

2. Search for decision signals:
   ```bash
   grep -l -E "decided|chose|instead of|trade-off|because" ~/.claude/projects/*/*.jsonl
   ```

3. Gather architectural git history:
   ```bash
   git log --oneline --all --merges
   git log --oneline --grep="refactor\|migrate\|change"
   ```

4. Analyze for:
   - Trade-off discussions: alternatives evaluated
   - Rationale: why choices were made
   - Conventions: patterns that emerged

### Analysis Focus

- Major architectural decisions
- Technology choices and rationale
- Conventions established
- Trade-offs accepted

### Output

See `synthesis-templates.md` for the extract-decisions template.

**Follow-up**: Suggest `/updateclaudemd` to document decisions.

---

## find-antipatterns

**Purpose**: Surface recurring negative patterns.

### Workflow

1. Extract longer timeframe:
   ```bash
   python3 ~/.claude/skills/session-search/scripts/extract_conversations.py --days 30 --all-projects
   ```

2. Search for pattern signals:
   ```bash
   grep -l -E "again|same|repeated|forgot|mistake" ~/.claude/projects/*/*.jsonl
   ```

3. Analyze for:
   - Repeated mistakes: same bugs, misunderstandings
   - Inefficient workflows: manual work when automation exists
   - Copy-paste patterns: same questions recurring

### Analysis Focus

- Mistakes that repeat
- Inefficient patterns
- Recurring confusion
- Habits that slow progress

### Output

See `synthesis-templates.md` for the find-antipatterns template.
