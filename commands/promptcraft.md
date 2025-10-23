---
description: Interactive prompt generator for Claude Code features and general AI prompts with intelligent tool selection and self-evaluation
argument-hint: [feature-type] [feature-name] - Optional: agent, command, output-style, or leave empty to investigate
---

# Prompt Generator

Generate optimized prompts for Claude Code features or general AI tasks. Follow modern prompt engineering principles: explicit instructions on WHAT to achieve, minimal prescription of HOW.

## Execution Flow

### Phase 1: Context Discovery

**If argument provided ($ARGUMENTS):**
Parse for feature type (agent/command/output-style/mcp) and optional name.

**If no argument:**
Determine from user's request whether this is:
- Claude Code feature (agent, command, output-style, hook, setting)
- Generic AI prompt

**For Claude Code features:**
Execute `/docs <feature-type>` to load current documentation and best practices.

**Always ask 3-5 targeted questions** to understand:
- Primary objective and success criteria
- Target use cases and constraints
- Expected inputs/outputs
- Complexity level and scope
- Tool requirements (if applicable)

### Phase 2: Prompt Architecture

**Analyze requirements:**
- Identify core objective
- Determine complexity (simple/moderate/complex)
- Map required capabilities to available tools
- Structure appropriate format

**Tool Intelligence** (for Claude Code features):
Based on prompt requirements, suggest tools:
- **Bash**: If system commands, testing, or git operations needed
- **Read/Write/Edit**: For file operations
- **Grep/Glob**: For code search and navigation
- **WebSearch/WebFetch**: For research or documentation lookup
- **Task**: For delegating to subagents

Present tool selection with rationale:
"Selected tools: Read, Grep, Bash(git:*), Bash(pytest:*)
Rationale: Code analysis requires file reading and search; testing requires git and pytest commands.
Modify this selection? [show what was excluded and why]"

**Format Adaptation:**
- **Simple prompts**: Direct instructions, minimal structure, no sections
- **Moderate prompts**: Light organization with ## headers where clarity benefits
- **Complex prompts**: Structured sections, clear hierarchy, process steps

### Phase 3: Prompt Generation

**Structure by feature type:**

**For Commands (frontmatter + body):**
```markdown
---
allowed-tools: <intelligently selected>
description: <concise single-line description>
argument-hint: [arg1] [arg2] - description
model: claude-sonnet-4-5-20250929
---

<prompt body - format based on complexity>
```

**For Agents (frontmatter + body):**
```markdown
---
name: <agent-name>
description: <when to use, what it does>
tools: <tool names without parameters>
model: sonnet
---

<prompt body - format based on complexity>
```

**For Generic Prompts:**
No frontmatter. Pure instruction body optimized for the objective.

**Prompt Construction Principles:**
- State objective and constraints explicitly
- Provide context only when necessary for task understanding
- Use imperative voice ("Analyze", "Generate", "Identify")
- Avoid first-person narrative ("I will", "I am")
- Minimize prescriptive process unless critical to outcome
- Include success criteria when ambiguity exists
- Use XML tags for complex structured sections only when beneficial
- Examples only when they clarify expectations

### Phase 4: Meta-Evaluation

**Evaluate the generated prompt on these dimensions:**

**Clarity (0-10):** Instructions unambiguous, objective clear
**Precision (0-10):** Appropriate specificity without over-constraint
**Efficiency (0-10):** Token economy - maximum instruction value per token
**Completeness (0-10):** Covers requirements without gaps or excess
**Usability (0-10):** Practical, actionable, appropriate for target use

**Calculate overall score** (target: 9.0/10.0)

**Present evaluation:**
```
Prompt Quality Assessment:
Clarity: X/10 - [brief rationale]
Precision: X/10 - [brief rationale]
Efficiency: X/10 - [brief rationale]
Completeness: X/10 - [brief rationale]
Usability: X/10 - [brief rationale]

Overall: X.X/10

[If < 9.0: Identify specific improvement needed]
[If >= 9.0: Confirm prompt meets quality threshold]
```

**If score < 9.0:** Refine prompt addressing identified weakness. Re-evaluate once.

### Phase 5: Delivery

**Determine output location:**
- Commands → `~/.claude/commands/<name>.md`
- Agents → `~/.claude/agents/<name>.md`
- Output styles → `~/.claude/output-styles/<name>.md`
- Hooks → `~/.claude/hooks/<name>.md`
- Settings → `~/.claude/settings/<name>.json`
- Generic/unspecified → `./<name>_prompt.md` (project root)
- User-specified path → as provided

**Before writing:**
"Writing prompt to: [path]
This will [create new/overwrite existing] file.
Proceed?"

**After writing:**
Confirm creation and provide usage instructions if applicable (e.g., invoke with `/command-name` for commands).

## Quality Standards

**Modern Best Practices:**
- Explicit about desired outcome, not process
- Context included only when it improves understanding
- Instructions over explanations
- Constraints stated clearly
- No unnecessary verbosity

**Format Economy:**
- Simple task = direct instruction
- Complex task = organized structure
- No formatting for formatting's sake

**Token Efficiency:**
Every word must contribute to instruction clarity or constraint specification. Remove:
- Filler phrases
- Obvious implications
- Redundant framing
- Excessive politeness

**Flexibility with Precision:**
Strike balance between:
- Loose enough for creative exploration
- Tight enough to avoid ambiguity

## Error Handling

**Missing context:** Ask user for clarification rather than assume.
**Unclear requirements:** Request specific examples or constraints.
**Tool conflicts:** Explain limitation and suggest alternatives.
**Path issues:** Verify directory exists before writing, create if needed with user confirmation.

## Success Criteria

Generated prompt should:
- Achieve intended objective when used
- Be maintainable and understandable
- Follow Claude 4 prompting best practices
- Score >= 9.0/10 on meta-evaluation
- Deliver to correct location
- Be immediately usable without modification

Execute this workflow systematically. Each phase completion before next phase begins.
