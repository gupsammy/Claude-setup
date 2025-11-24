---
name: learn-anything
description: Metalearning skill that helps master any topic efficiently by identifying critical 20% material, building expert vocabulary, and creating research-backed learning roadmaps. Use when user says "learn [topic]", "help me learn [topic]", "I want to learn [topic]", or asks for guidance on understanding a new subject. Supports comprehensive plans, interactive guidance, or minimalist just-in-time delivery.
allowed-tools: WebSearch,Read,Write,AskUserQuestion
---

# Learn Anything

Transform "I want to learn X" into actionable learning roadmaps using metalearning principles: identify the critical 20%, build expert vocabulary, sequence logically (why before how), prioritize current best practices.

## When to Use

Activate when user:
- Says "learn [topic]" or "help me learn [topic]"
- Asks "how do I get started with [subject]?"
- Requests structured approach to mastering something new

Do NOT use when:
- User has content and wants action plans (use ship-learn-next)
- Request is for implementation help, not learning

## Core Principles

1. **Pareto Focus**: Identify 20% of material delivering 80% of practical value
2. **Logical Sequencing**: Foundations before details, why before how
3. **Vocabulary First**: Build expert lexicon for better understanding and prompting
4. **Practical Bias**: Optimize for applicable knowledge over comprehensive coverage

## State Management - .learn Directory

All learning artifacts are saved in `.learn/[topic-slug]/`:

```
.learn/
├── react/
│   ├── plan.md              # Learning plan (all modes)
│   ├── progress.json        # State tracking (interactive/minimalist)
│   ├── vocabulary.md        # Dependency-sequenced vocab
│   └── notes.md            # User's learning notes (optional)
```

Create `.learn/` directory on first use if it doesn't exist. Use topic slug (lowercase, hyphens) for subdirectory.

## Three Output Modes

**Mode Selection**: Ask preference BEFORE research (affects how material is structured). Default to comprehensive if unclear.

### Comprehensive Plan (Default)
- **Delivery**: Save complete `plan.md` with detailed 20% starter pack and full roadmap
- **State**: No progress tracking needed
- **Best for**: Self-directed learners who want complete picture upfront
- **Artifacts**: `.learn/[topic]/plan.md` only

### Interactive Guide
- **Delivery**: Present one concept at a time, validate understanding before progressing
- **State**: Track progress in `progress.json`, update as user completes concepts
- **Best for**: Learners wanting accountability and validation
- **Artifacts**: `plan.md` + `progress.json` + `vocabulary.md`
- **Flexibility**: Allow rollback, concept reordering, adding concepts mid-journey

### Minimalist Just-In-Time
- **Delivery**: Only immediate next resource and key terms
- **State**: Track progress in `progress.json`, user returns for next step
- **Best for**: Action-oriented learners avoiding analysis paralysis
- **Artifacts**: `plan.md` (minimal) + `progress.json` + `vocabulary.md`
- **Flexibility**: Allow rollback, concept reordering, adding concepts mid-journey

## Resuming Existing Learning

Before starting new learning plan, check if `.learn/[topic-slug]/` exists:

**If exists**:
1. Read `progress.json` to check mode and current state
2. Ask: "I found an existing learning plan for [topic]. Would you like to: A) Continue where you left off, B) Start fresh, C) Review your progress?"

**If continuing**:
- Load current concept from progress.json
- Present next step based on mode (Interactive/Minimalist) or remind them of plan (Comprehensive)
- Reference what they've already learned when presenting new material

**If starting fresh**:
- Archive old directory to `.learn/[topic]-archive-[timestamp]/`
- Proceed with new learning plan

**If reviewing progress**:
- Display concepts completed, current concept, vocabulary learned
- Allow modifications: "Want to go back to any concept? Add new concepts? Continue forward?"

## Workflow

### Step 1: Understand Intent

Extract topic from user request, then ask 2-3 questions to understand context:

**Focus on intent and application:**
- "What's driving you to learn [topic]?" (Work project / Career shift / Building something specific / Pure curiosity)
- "Where will you apply this knowledge?" (Specific project / General skill / Professional requirement / Personal exploration)
- "What's your current experience with [topic] or related areas?" (Complete beginner / Some exposure / Familiar with adjacent topics)

Use AskUserQuestion with conversational multiple choice options. Keep brief - gather just enough to tailor the plan.

### Step 2: Intelligent Research

Conduct adaptive web searches based on topic maturity and ecosystem:

**Search Strategy (adapt per topic):**

For established technologies/fields:
- "[topic] official documentation"
- "[topic] reddit" (find community discussions, real practitioner opinions)
- "[topic] learning path" or "[topic] roadmap"
- "getting started [topic]" (beginner resources)
- "[topic] vs [alternative]" (understand positioning and use cases)

For emerging/niche topics:
- "[topic] github" (find projects, examples, real usage)
- "[topic] tutorial"
- "what is [topic]" (understand current state)
- "[topic] use cases" (practical applications)

For academic/theoretical topics:
- "[topic] course"
- "[topic] textbook recommendation"
- "[topic] explained" (accessible introductions)

**Research Goals:**
1. Current state and recent developments (what's modern vs outdated)
2. Highest-impact resources (official docs, respected courses, definitive guides)
3. Expert vocabulary (terms, jargon, acronyms used casually)
4. Learning dependencies (prerequisites, logical sequencing)
5. Common pitfalls and confusing concepts

**Resource Quality Signals:**
- Official/maintained documentation
- Community consensus (upvotes, recommendations)
- Recent publication (relevance to current practices)
- Beginner-friendly vs advanced (match user level)
- Free and accessible

Run 4-6 searches adapting to what you discover. Don't follow template blindly.

### Step 3: Identify Critical 20%

Analyze research to extract 3-7 core topics providing maximum foundation.

**Selection Criteria:**
- Unlocks understanding of other concepts
- Used frequently in practice
- Foundational vs nice-to-know
- Current best practices (skip legacy/deprecated)

For each core topic:
- Why it matters (conceptual foundation)
- 1-2 highest-impact resources
- 5-10 key vocabulary terms
- Time estimate
- Concrete capability gained

**Example (React):**
- 20%: Components, JSX, Props/State, Hooks, Event Handling
- NOT 20%: Class components (outdated), advanced patterns, SSR (later), testing (later)

### Step 4: Build Full Roadmap

Sequence remaining topics into Foundation → Intermediate → Advanced.

For each topic beyond 20%:
- Brief description
- Why it matters
- One highest-impact resource
- Mark optional vs essential

Keep lean. This is a map, not detailed instructions.

### Step 5: Compile Vocabulary

Build **dependency-based vocabulary sequence** - order terms by conceptual dependencies, not arbitrary tiers.

**Sequencing Principle**: Learn foundational terms before terms that depend on them.

Example (React):
1. **Component** (foundation - needed for everything)
2. **JSX** (syntax - needed to write components)
3. **Props** (component inputs - builds on component understanding)
4. **State** (component data - parallel to props)
5. **Hook** (function for state/effects - builds on state concept)
6. **useState** (specific hook - builds on hook concept)
7. **useEffect** (specific hook - builds on hook + component lifecycle)

**Coverage**: Identify 10-30 terms covering the 20% material. If dependencies require more terms, include them. Always start from first principles.

**Format for each term**:
```
**Term**: Definition (1 sentence) + why it matters/when you'll use it
Dependencies: [terms you need to know first, if any]
```

**For Interactive/Minimalist modes**: Pre-sequence vocabulary to match concept order. As each concept is introduced, present only its terms and dependencies (building on previously learned terms).

**For Comprehensive mode**: Present full sequenced vocabulary list in plan.md.

**Save to**: `.learn/[topic]/vocabulary.md` with dependency indicators.

### Step 6: Generate Output

#### Mode 1: Comprehensive Plan

Save to `.learn/[topic]/plan.md` with structure:

```markdown
# Learning Plan: [Topic]

**Context**: [Current level] | [Goal/Application] | Generated: [date]

## First 20% - Starter Pack

### 1. [Core Topic]
**Why**: [Conceptual explanation]
**Vocabulary**: [Terms with dependencies]
**Resource**: [URL] - [Why valuable] - Time: [Estimate]
**After this**: [Capability gained]

[Repeat for 3-7 core topics]

## Full Roadmap
### Intermediate: [Topics with brief descriptions + resources]
### Advanced: [Topics with brief descriptions + resources]
### Optional: [When needed]

## Vocabulary Reference
[Dependency-sequenced terms with definitions - from vocabulary.md]

## Learning Tips
[3-5 tips: pitfalls, best practices, communities]

## Next Steps
Start with topic 1, learn vocabulary as you go, complete resource, assess next direction.
```

After saving: Confirm location, summarize 20%, encourage action.

#### Mode 2: Interactive Guide

**Initial Setup**:
1. Create `.learn/[topic]/` directory
2. Save `plan.md` with full learning plan (for reference)
3. Save `vocabulary.md` with dependency-sequenced terms
4. Initialize `progress.json`:

```json
{
  "mode": "interactive",
  "topic": "React",
  "current_concept": 1,
  "concepts": [
    {"id": 1, "name": "Components", "status": "in_progress", "started_at": "2025-01-15"},
    {"id": 2, "name": "JSX", "status": "pending"},
    {"id": 3, "name": "Props & State", "status": "pending"}
  ],
  "vocabulary_progress": {
    "learned": [],
    "current": ["component", "render"],
    "upcoming": ["jsx", "props", "state"]
  },
  "history": []
}
```

**Delivery Flow**:

**First interaction** - Present current concept:
```
📚 Learning React - Concept 1/5: Components

**Why this matters**: [Conceptual explanation]

**Vocabulary for this concept**:
- **Component**: [Definition + usage]
  Dependencies: None (foundational)
- **Render**: [Definition + usage]
  Dependencies: Component

**Resource**: [Name + URL]
Why this resource: [What makes it valuable]
Time: [Estimate]

**After completing**: Return and I'll check your understanding before moving to JSX.

Progress saved to: .learn/react/progress.json
```

**When user returns** - Check understanding:
```
Welcome back! Let's validate your understanding of Components.

Quick check:
- What is a component in your own words?
- How does rendering work?

[Based on response:]
✓ Great understanding → Update progress.json, move to concept 2
⚠ Some gaps → Clarify misconceptions, offer supplementary resource
✗ Struggling → Suggest re-doing resource or different approach, keep on concept 1
```

**State Updates**:
- Mark concept completed, update `vocabulary_progress.learned`
- Set next concept to "in_progress"
- Add to `history` array
- Save progress.json

**Flexibility Commands** (user can say these anytime):
- "Go back to [concept]" → Rollback, set that concept to "in_progress", add to history
- "I want to review [concept]" → Allow re-learning, build on what was taught before
- "Add a concept about [topic]" → Insert into concepts array, update sequence
- "Skip to [concept]" → Mark current as completed, jump ahead (allow but discourage)
- "Show my progress" → Display current state from progress.json

**Conversation Style**: One concept at a time, validate before progressing, adaptive pacing, encouraging tone. Build on previously learned vocabulary when introducing new terms.

#### Mode 3: Minimalist Just-In-Time

**Initial Setup**:
1. Create `.learn/[topic]/` directory
2. Save minimal `plan.md` (just concept list + brief descriptions)
3. Save `vocabulary.md` with dependency-sequenced terms
4. Initialize `progress.json` (same structure as Interactive mode)

**Delivery Flow**:

**First interaction** - Minimal, actionable:
```
🎯 Learning React - Step 1/5: Components

Start here: [Resource name + URL]
Time: ~2 hours

Key terms to understand:
- **Component**: [Definition]
  Dependencies: None
- **Render**: [Definition]
  Dependencies: Component

Return when done for the next step.

Progress: .learn/react/progress.json
```

**When user returns** - Brief check + next step:
```
Welcome back!

Quick: What's one key thing you learned about components?

[Based on response - acknowledge briefly]

Next step: JSX (Step 2/5)
Resource: [URL]
Time: ~1 hour

New vocabulary (builds on what you know):
- **JSX**: [Definition]
  Dependencies: Component, Render
- **Element**: [Definition]
  Dependencies: JSX

Return when done.
```

**State Updates**: Same as Interactive mode - mark completed, update vocabulary progress, save to progress.json.

**Flexibility Commands**: Same as Interactive mode - allow rollback, review, add concepts, show progress.

**Key Difference from Interactive**: No understanding validation checks. Trust user to self-assess. Focus on momentum and just-in-time information delivery.

## Quality Standards

Regardless of mode:

✅ Research is current (prioritize recent resources when topic evolves rapidly)
✅ Resources are accessible (prefer free, high-quality, maintained)
✅ Vocabulary is practical (actual usage, not exhaustive lists)
✅ Sequencing is logical (foundation → advanced, why → how)
✅ 20% is truly impactful (each topic unlocks significant understanding)
✅ Resources are vetted (recommend best, not first search results)
✅ Explanations are clear (intelligent but unfamiliar audience)

## Edge Cases & Guidelines

**Broad topic**: Narrow via AskUserQuestion before research. "AI covers ML, NLP, computer vision - which interests you?"

**Niche topic**: Deeper research needed. If resources limited, start with fundamentals before specialization.

**User has resource**: Research quality. Build around if good, suggest alternatives if outdated. Provide vocabulary/sequencing regardless.

**Mode switch**: Adapt from current state using progress.json. No re-interview needed.

**What NOT to do**: Passive study plans, exhaustive vocabulary (50+ terms), skip research, broad 20% (10+ topics), mechanical interview questions.

**Success criteria**: Clear 20%, current research-backed resources, dependency-sequenced vocabulary, logical sequencing, realistic estimates, applicable knowledge focus. After 20%, can user engage independently?
