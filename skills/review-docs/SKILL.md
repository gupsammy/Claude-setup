---
name: review-docs
description: Open the Document Reviewer for collaborative editing and feedback. Use when the user wants to review a skill, code folder, or any documents with you. Triggers on "review this", "let's review", "open reviewer", "review skill", "review folder".
---

# Document Reviewer Skill

Opens an interactive Document Reviewer in the browser for collaborative feedback sessions.

## What It Does

1. Opens the Document Reviewer playground (`~/.claude/skills/review-docs/document-reviewer.html`)
2. User loads a folder via the **📂 Open Folder** button
3. User switches to **Review** mode and clicks lines to add comments
4. User copies feedback and pastes it back to continue the conversation

## When to Use

- Reviewing skill files before committing
- Providing feedback on code or documentation
- Collaborative editing sessions
- Any time structured line-by-line feedback is needed

## Instructions

When this skill is triggered:

1. Open the Document Reviewer:
   ```bash
   open ~/.claude/skills/review-docs/document-reviewer.html
   ```

2. Tell the user:
   ```
   I've opened the Document Reviewer. Here's how to use it:

   1. Click **📂 Open Folder** and select the folder you want to review
   2. Switch to **Review** mode (top right)
   3. Click any line to add a comment
   4. When done, click **Copy Markdown** and paste it here

   The viewer auto-detects your system theme (light/dark).

   What folder would you like to review?
   ```

3. Wait for the user to paste their feedback

4. When feedback is received, parse it and apply the requested changes

## Feedback Format

The user will paste feedback in this format:

```markdown
## Feedback on [folder-name]

### [filename]

**Line X:** `context snippet`
→ User's comment here
```

Parse each comment and apply the changes to the referenced files.

## Notes

- The viewer uses the File System Access API, so it works best in Chrome/Edge
- Theme follows system preference (Tokyo Night dark/light)
- Git diffs are not available through the folder picker (browser limitation)
- For git-aware reviews, user should ask you to read the files and provide diff data
