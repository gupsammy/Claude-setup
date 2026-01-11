---
allowedTools: Read, Glob, Grep, Edit, Write, Bash(npm:*), Bash(npx:*), AskUserQuestion, mcp__chrome__*
description: Polish UI/UX to world-class standards with visual analysis
---

# UI/UX Polish Command

Transform interfaces to Stripe-level polish through visual analysis and targeted refinement.

## Phase 1: Visual Discovery

Check Chrome MCP availability. If unavailable, prompt: "Enable Chrome MCP for visual analysis: /setup mcp chrome"

With Chrome available:
1. Identify the target component/page from user or infer from recent context
2. Launch the app if not running
3. Capture screenshots at key breakpoints:
   - Desktop: 1440px, 1024px
   - Mobile: 390px, 320px
4. Analyze visuals against these criteria:
   - Typography: hierarchy, weight contrast, spacing rhythm
   - Color: palette cohesion, contrast ratios, accent usage
   - Layout: alignment grid, whitespace balance, visual flow
   - Motion: transitions, hover states, loading states
   - Touch targets: mobile tap sizing, thumb zones
   - Micro-details: borders, shadows, radii consistency

Explore the code to understand current implementation patterns and constraints.

## Phase 2: Recommendations

Present findings organized by impact:

**Quick wins** - High visual impact, minimal code change
**Structural improvements** - Layout/component architecture changes
**Polish details** - Micro-interactions, refinements

For each recommendation, note whether it applies to desktop, mobile, or both.

Use AskUserQuestion to confirm direction before proceeding.

## Phase 3: Implementation

Execute approved changes. After each significant change, re-screenshot to verify visual improvement.

Reference standards: Stripe, Linear, Vercel, Raycast for modern UI patterns. Prioritize:
- Distinctive typography over generic fonts
- Purposeful color with sharp accents
- Generous whitespace
- Subtle motion that aids comprehension
- Platform-appropriate interactions (hover for desktop, gestures for mobile)
