---
allowedTools: Read, Write, Edit, Glob, Grep, WebFetch, TodoWrite, WebSearch, Task, Skill, SlashCommand, AskUserQuestion
description: Intelligent prompt generator with specialized routing. Creates general prompts directly; routes Claude Code features (plugins, agents, skills, hooks, MCP, commands) to specialized tools.
argument-hint: [feature-type] [feature-name] - Optional: plugin, agent, skill, hook, mcp, command, or leave empty to investigate
---

# Prompt Generator

Intelligent prompt generator with specialized tool routing. Routes Claude Code features (plugins, agents, skills, hooks, MCP, commands) to specialized tools with deep domain knowledge. Handles general AI prompts directly with meta-evaluation.

## Context Engineering Principles

Context engineering is curating the optimal set of tokens during LLM inference. Every generated prompt must embody these principles:

**Context is Finite**
- LLMs have limited attention budget; performance degrades as context grows
- Every token depletes capacity—treat context as precious
- Goal: smallest possible set of high-signal tokens that maximize outcomes

**Optimize Signal-to-Noise**
- Clear, direct language over verbose explanations
- Remove redundant information ruthlessly
- Focus on high-value tokens that drive behavior

**Progressive Discovery**
- Use lightweight identifiers vs full data dumps
- Load detailed info dynamically when needed
- Just-in-time information > front-loaded context

**Writing Style**

| Pattern | ✅ Good | ❌ Bad |
|---------|---------|--------|
| Clarity over completeness | "Validate input before processing" | "You should always make sure to validate..." |
| Be direct | "Use calculate_tax tool with amount and jurisdiction" | "You might want to consider using..." |
| Imperative voice | "Analyze the response" | "I will analyze the response" |
| Structured constraints | Bulleted list of requirements | Paragraph of buried requirements |

## Execution Flow

### Phase 1: Context Discovery

**If argument provided ($ARGUMENTS):**
Parse for feature type and optional name. Recognized types:
- **Routed**: plugin, agent, skill, hook, mcp, command (redirected to specialized tools)
- **Direct**: general AI prompts (handled by promptcraft)

**If no argument:**
Determine from user's request whether this is:
- Claude Code feature (plugin, agent, skill, hook, mcp, command)
- Generic AI prompt

**For Claude Code features:**
first always fetch claude /docs <feature-type> to load current documentation and best practices.

**Always ask 3-5 targeted questions using AskUserQuestion tool** to understand:
- Primary objective and success criteria
- Target use cases and constraints
- Expected inputs/outputs
- Complexity level and scope
- Tool requirements (if applicable)

### Phase 1.5: Specialized Tool Routing

After identifying feature type, check if specialized tooling provides better results. Route to specialized tools for complex features; continue with promptcraft for simpler ones.

**Routing Decision Table:**

| Feature Type | Route To | Method | Reason |
|--------------|----------|--------|--------|
| **Plugin** | `/plugin-dev:create-plugin` | SlashCommand | Complete 8-phase workflow with validation |
| **Agent** | `plugin-dev:agent-creator` agent | Task | Claude Code's generation pattern with `<example>` blocks |
| **Skill** | `plugin-dev:skill-development` skill | Skill | Progressive disclosure, third-person descriptions |
| **Command** | `plugin-dev:command-development` skill | Skill | Frontmatter, arguments, bash execution patterns |
| **Complex Hook** | `plugin-dev:hook-development` skill | Skill | Deep API knowledge, 9 events, security patterns |
| **Simple Hook** | `/hookify:hookify` | SlashCommand | Quick behavioral rules, no coding |
| **MCP Server** | `plugin-dev:mcp-integration` skill | Skill | Server types, authentication, .mcp.json config |
| **General Prompt** | Continue here | — | Promptcraft core use case |

**Routing Logic:**

| Feature | Action | Tool Call |
|---------|--------|-----------|
| Plugin | Always redirect | `SlashCommand: /plugin-dev:create-plugin [description]` |
| Agent | Always redirect | `Task: subagent_type=plugin-dev:agent-creator` |
| Skill | Always redirect | `Skill: plugin-dev:skill-development` |
| Command | Always redirect | `Skill: plugin-dev:command-development` |
| MCP Server | Always redirect | `Skill: plugin-dev:mcp-integration` |
| Hook | Ask complexity first | See below |
| General Prompt | Continue to Phase 2 | — |

**For Hooks**: Use AskUserQuestion to determine complexity:
- "Simple warning/block rule" → `SlashCommand: /hookify:hookify [description]`
- "Complex hook with validation" → `Skill: plugin-dev:hook-development`
- "I don't know" → Suggest `/hookify:hookify` (analyzes conversation for patterns)

**After routing:**
- If redirected: Let specialized tool complete the task, then proceed to **Phase 4** for optimization review
- If continuing (general prompts): Proceed to Phase 2

### Phase 2: Prompt Architecture (General Prompts Only)

**Skip if routed in Phase 1.5.** For general AI prompts, analyze requirements:
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
- SlashCommand, AskUserQuestion, and others.
- be generous with tool access for the feature, no need to be conservative

Present tool selection with rationale:
"Selected tools: Read, Grep, Bash(git:*), Bash(pytest:*), AskUserQuestion
Rationale: Code analysis requires file reading and search; testing requires git and pytest commands.
Modify this selection? [show what was excluded and why]"

**Format Adaptation:**
- **Simple prompts**: Direct instructions, minimal structure, no sections
- **Moderate prompts**: Light organization with ## headers where clarity benefits
- **Complex prompts**: Structured sections, clear hierarchy, process steps

### Phase 3: Prompt Generation (General Prompts Only)

**Skip if routed in Phase 1.5.** For general AI prompts:

**Semantic Section Structure**

Organize prompt bodies using these semantic sections (include only what's needed):

| Section | Purpose | When to Include |
|---------|---------|-----------------|
| **Background** | Minimal essential context | Only when task requires domain knowledge |
| **Instructions** | Core directives, imperative voice | Always |
| **Examples** | Show don't tell, concise, representative | When behavior needs demonstration |
| **Constraints** | Boundaries, limitations, success criteria | When ambiguity exists |

**Format Templates:**

**Commands** (frontmatter + body):
```markdown
---
allowedTools: <intelligently selected per Phase 4.5>
description: <concise—user-triggered, no auto-trigger needed>
argument-hint: [arg] - description
---

<semantic sections as needed>
```

**Agents** (frontmatter + body):
```markdown
---
name: <agent-name>
description: <trigger conditions with varied phrases + capability>
tools: <tool names per Phase 4.5>
model: sonnet
---

<semantic sections as needed>
```

**Skills** (SKILL.md + optional references/):
```markdown
---
description: <trigger-rich with varied examples—"use when user asks to X", "Y", "Z", or mentions "A", "B">
---

<progressive disclosure: core instructions first, details later>
```

**Generic Prompts**: No frontmatter. Pure instruction body.

**Construction Rules:**
- State objective explicitly in first sentence
- Use imperative voice ("Analyze", "Generate", "Identify")
- No first-person narrative ("I will", "I am")
- Context only when necessary for understanding
- XML tags only for complex structured data
- Examples only when they clarify expectations
- Every word must earn its place

### Phase 4: Feature Optimization (All Claude Code Features)

**Apply after routed workflow completes OR after Phase 3 for general prompts.** This phase ensures progressive disclosure and frontmatter optimization.

#### Frontmatter Priority

Frontmatter is **first in model attention**—optimize ruthlessly. Different features need different strategies:

| Feature | Description Strategy | Trigger Design |
|---------|---------------------|----------------|
| **Command** | Concise, action-focused | User-triggered (no auto-trigger) |
| **Skill** | Trigger-rich with varied phrases | High auto-trigger desired |
| **Agent** | Clear conditions + capability | Moderate auto-trigger |
| **Hook** | Event-specific clarity | Event-driven |

**Command Frontmatter:**
- `description`: Concise action summary (under 60 chars)—users see this in `/help`
- `allowedTools`: Scope appropriately (see below)
- `argument-hint`: Document expected arguments clearly
- Commands are instructions FOR Claude, not messages TO user

**Skill/Agent Trigger Optimization:**
- Include varied trigger phrases, not exact keywords
  - Good: "create an agent", "build a new agent", "make me an agent that...", "agent for..."
  - Bad: Only "create agent"
- Balance token cost vs. trigger accuracy
- More examples = higher auto-trigger probability
- Use AskUserQuestion: "How often should this trigger automatically vs. explicitly?"

#### allowedTools Strategy

**Default lenient, restrict only high-risk operations.**

| Tool | Default | Restrict When |
|------|---------|---------------|
| Read, Glob, Grep | Always allow | Never |
| Edit, Write | Allow | Writing to system paths |
| WebSearch, WebFetch | Allow | Offline-only features |
| Task | Allow | Sandboxed features |
| **Bash** | Use patterns | Always scope: `Bash(git:*)`, `Bash(npm:*)`, `Bash(pytest:*)` |
| **KillShell** | Omit | Only include if explicitly needed |
| AskUserQuestion | **Required** | Never omit when interviewing/confirming |
| SlashCommand | **Required** | Never omit when delegating to workflows |
| Skill | Allow | When delegation opportunities exist |

**Mandatory inclusions:**
- If prompt has ANY user interaction/confirmation → include `AskUserQuestion`
- If prompt delegates to other features → include `SlashCommand` and/or `Skill`
- Explicitly instruct when to use: "Use AskUserQuestion tool to confirm..." or "Use SlashCommand: /commit"

#### Delegation & Modularization

Before finalizing, scan for delegation opportunities:

```
Review available: skills, commands, agents, MCPs
For each workflow step, ask: "Do we already have this?"
```

**Common delegation patterns:**
- Git commits → `SlashCommand: /commit`
- Code review → `SlashCommand: /code-review`
- Plugin creation → `SlashCommand: /plugin-dev:create-plugin`
- Hook creation → `Skill: plugin-dev:hook-development`
- Command creation → `Skill: plugin-dev:command-development`
- Documentation lookup → `SlashCommand: /docs [topic]`

**Always use fully qualified names:**
- `Skill: plugin-dev:hook-development` (not just "hook-development")
- `SlashCommand: /plugin-dev:create-plugin` (not just "create-plugin")
- `Task: subagent_type=plugin-dev:agent-creator`

#### Body Review Checklist

| Issue | Fix |
|-------|-----|
| Verbose code blocks | Pattern out, provide general instructions that adapt to edge cases |
| Exact keyword matching | Replace with intent-based language (Claude extrapolates) |
| Hardcoded paths/values | Use variables or let Claude infer |
| Redundant examples | Keep 2-3 representative cases, remove similar ones |
| Over-specified process | Trust Claude's intelligence—provide direction not dictation |

**Key principle:** Claude is smart and extrapolates well—nudge precisely, don't over-specify.

### Phase 5: Meta-Evaluation

**Evaluate the generated/optimized prompt:**

| Dimension | Criteria |
|-----------|----------|
| **Clarity (0-10)** | Instructions unambiguous, objective clear |
| **Precision (0-10)** | Appropriate specificity without over-constraint |
| **Efficiency (0-10)** | Token economy—maximum value per token |
| **Completeness (0-10)** | Covers requirements without gaps or excess |
| **Usability (0-10)** | Practical, actionable, appropriate for target use |

**Target: 9.0/10.0**

Present evaluation, then:
- If < 9.0: Refine addressing weakness, re-evaluate once
- If ≥ 9.0: Proceed to delivery

### Phase 6: Delivery

**Determine output location:**
- Commands → `~/.claude/commands/<name>.md`
- Agents → `~/.claude/agents/<name>.md`
- Skills → `~/.claude/skills/<name>/SKILL.md`
- Hooks → `~/.claude/hooks/<name>.md`
- Generic/unspecified → `./<name>_prompt.md` (project root)
- User-specified path → as provided

**Before writing:**
"Writing prompt to: [path]
This will [create new/overwrite existing] file.
Proceed?"

**After writing:**
Confirm creation and provide usage instructions if applicable (e.g., invoke with `/command-name` for commands).

## Quality Standards

Apply Context Engineering Principles (see above). Additionally:

**Format Economy:**
- Simple task → direct instruction, no sections
- Moderate task → light organization with headers
- Complex task → full semantic structure

**Balance Flexibility with Precision:**
- Loose enough for creative exploration
- Tight enough to prevent ambiguity

**Remove ruthlessly:** Filler phrases, obvious implications, redundant framing, excessive politeness

## Error Handling

| Issue | Action |
|-------|--------|
| Missing context | Ask for clarification |
| Unclear requirements | Request examples or constraints |
| Tool conflicts | Explain limitation, suggest alternatives |
| Path issues | Verify directory, create with confirmation |

## Success Criteria

Generated prompt must: achieve objective when used, score ≥9.0/10 on meta-evaluation, be immediately usable without modification.

Execute phases sequentially. Complete each before proceeding.
