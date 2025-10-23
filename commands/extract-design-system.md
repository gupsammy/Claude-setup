**CREATE DESIGN SYSTEM JSON**

UI TO ANALYZE: $ARGUMENTS

**GOAL**
Your goal is to extract a generalized and reusable design system from the screenshots provided in `$ARGUMENTS`, **without including specific image content**, so that frontend developers or AI agents can reference the JSON as a style foundation for building consistent UIs.

**Task**

1. Analyze the screenshots provided in `$ARGUMENTS` to infer:
   - Color palette
   - Typography rules
   - Spacing guidelines
   - Layout structure (grids, cards, containers, etc.)
   - UI components (buttons, inputs, tables, etc.)
   - Border radius, shadows, and other visual styling patterns
2. Create a `design-system.json` file that clearly defines these rules and can be used to replicate the visual language in a consistent way.
3. Output the JSON to the `prd` folder with the name: `design-system.json`

**Constraints**

- Do **not** extract specific content from the screenshots (no text, logos, icons).
- Focus purely on _design principles_, _structure_, and _styles_.
