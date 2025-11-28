# Example: Gaps Lens Output

This is a sample output from the Gaps lens analysis.

---

## Knowledge Gap Analysis: Nov 12-26, 2025

### Summary
Two significant knowledge gaps emerged: TypeScript generics (recurring across 4 projects) and CSS Grid layouts (consistently avoided in favor of Flexbox). Both are limiting the quality and efficiency of work.

### Recurring Struggles

| Topic | Frequency | Projects Affected | Severity |
|-------|-----------|-------------------|----------|
| TypeScript generics | 8 questions | invoice-saas, PortKiller, bitbybitweb | High |
| CSS Grid | 5 avoidances | bitbybitweb, invoice-saas | Medium |
| Error boundaries | 4 questions | invoice-saas, bitbybitweb | Medium |
| Git rebase | 3 avoidances | multiple | Low |

### Deep Dive: TypeScript Generics

- **Pattern observed**: Questions about generic syntax, constraints, and inference appear across multiple projects. Often resort to `any` or overly specific types when generics would be cleaner.

- **Root cause hypothesis**: Conceptual gap in understanding how type parameters flow through functions. The constraint syntax (`extends`, `keyof`) is particularly confusing.

- **Evidence**:
  - Nov 14: "How do I type this function that works with any array?"
  - Nov 18: "Why isn't TypeScript inferring this generic?"
  - Nov 22: "What does `T extends keyof` mean?"

### Dependency Assessment

| Task Type | Independence Level | Notes |
|-----------|-------------------|-------|
| React components | High | Confident, minimal guidance needed |
| API integration | High | Solid async patterns |
| TypeScript complex types | Low | Needs step-by-step help |
| CSS layouts | Medium | Flexbox good, Grid avoided |
| Database queries | Medium | Basic good, optimization uncertain |

### Recommended Learning Path

1. **TypeScript Generics**: Work through the TypeScript handbook generics section, then practice with utility types (`Partial<T>`, `Pick<T, K>`). Target: Comfortable writing generic functions.

2. **CSS Grid**: Build one layout purely with Grid (no Flexbox fallback). MDN's Grid guide is excellent. Target: Know when Grid is better than Flexbox.

3. **Error Boundaries**: Lower priority, but worth a focused 30-min session on the React docs section.

### Follow-up
Consider using the `learn-anything` skill to create a structured learning plan for TypeScript generics. Command: "learn typescript generics in interactive mode"
