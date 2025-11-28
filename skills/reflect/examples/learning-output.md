# Example: Learning Lens Output

This is a sample output from the Learning lens analysis.

---

## Learning Reflection: Nov 12-26, 2025

### Summary
Significant growth in async patterns and React hooks over the past two weeks, with a notable breakthrough in understanding useEffect cleanup. Some struggles with TypeScript generics remain, but debugging skills have noticeably improved.

### Breakthroughs
- **React useEffect cleanup** (Nov 18, invoice-extraction-saas)
  Finally understood why stale closures were causing race conditions. The key insight was that cleanup functions capture the values from their render cycle, not the latest values. This clicked after debugging the same issue three times.

- **SQLite concurrent writes** (Nov 15, PortKiller)
  Discovered SQLite's single-writer limitation the hard way with a race condition. Now understand why WAL mode helps and when to use it vs. switching to PostgreSQL.

### Mistakes & Lessons
- **Forgot async cleanup in useEffect** → **Lesson**: Always check if component unmounted before setting state in async callbacks. Added this to my mental checklist.

- **Hardcoded API URLs in multiple places** → **Lesson**: Environment variables from the start, even for "quick prototypes." The refactor took longer than doing it right initially.

### New Territory Explored
- Zod schema validation: First time using for API response validation
- React Query: Explored for caching, didn't fully adopt yet
- GitHub Actions matrix builds: Set up for multiple Node versions

### Skills Practiced
- Heavy focus: React hooks, async/await patterns, debugging
- Some practice: TypeScript, API design, testing
- Minimal: CSS, database design, deployment

### Suggested Next Steps
- Create a useEffect patterns cheat sheet to reinforce the cleanup patterns
- Consider deeper dive into TypeScript generics (recurring struggle area)
- The React Query exploration was cut short; worth revisiting for the invoice project
