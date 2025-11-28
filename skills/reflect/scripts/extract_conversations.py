#!/usr/bin/env python3
"""
Extract Claude Code conversations for analysis.

A pure extraction tool - fetches raw conversation data without pre-filtering.
Claude applies the analytical lens based on the reflect skill.

Usage:
    # By timeframe (activity-based for project-specific queries)
    python extract_conversations.py --days 3                    # Last 3 days of activity on current project
    python extract_conversations.py --days 7 --project /path    # Last 7 days of activity on that project
    python extract_conversations.py --days 2 --all-projects     # Last 2 calendar days across all projects
    python extract_conversations.py --days 3 --from-today       # Last 3 calendar days (not activity-based)

    # By conversation IDs (from episodic-memory search results)
    python extract_conversations.py --ids abc123,def456,ghi789
    python extract_conversations.py --id abc123

    # Output formats
    python extract_conversations.py --days 2 --output json
    python extract_conversations.py --days 2 --output markdown

Note: For project-specific queries, --days counts back from the most recent activity,
not from today. This is useful when returning to older projects. Use --from-today
or --all-projects for calendar-based timeframes.
"""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional
import argparse


def get_project_key(project_path: str) -> str:
    """Convert a project path to the Claude projects folder key format.

    Claude Code converts paths by replacing / and . with -
    e.g., /Users/sam/.claude -> -Users-sam--claude
    """
    return project_path.replace("/", "-").replace(".", "-")


def find_conversation_files(
    projects_dir: Path,
    project_filter: Optional[str] = None,
    days: int = 2,
    activity_based: bool = False
) -> list[Path]:
    """Find conversation files within the date range.

    Args:
        projects_dir: Path to ~/.claude/projects
        project_filter: Filter to specific project
        days: Number of days to look back
        activity_based: If True, look back N days from most recent activity
                       (useful for returning to old projects).
                       If False, look back N days from today.
    """
    # First, collect all matching files
    all_files = []

    for project_dir in projects_dir.iterdir():
        if not project_dir.is_dir():
            continue

        # Filter by project if specified
        if project_filter and project_filter not in project_dir.name:
            continue

        for jsonl_file in project_dir.glob("*.jsonl"):
            mtime = datetime.fromtimestamp(jsonl_file.stat().st_mtime)
            all_files.append((jsonl_file, mtime))

    if not all_files:
        return []

    # Sort by modification time (most recent first)
    all_files.sort(key=lambda x: x[1], reverse=True)

    # Determine cutoff based on mode
    if activity_based and project_filter:
        # Use most recent file's time as reference point
        most_recent_time = all_files[0][1]
        cutoff = most_recent_time - timedelta(days=days)
    else:
        # Use current time as reference point
        cutoff = datetime.now() - timedelta(days=days)

    # Filter by cutoff
    files = [f for f, mtime in all_files if mtime >= cutoff]

    return files


def find_conversations_by_ids(
    projects_dir: Path,
    conversation_ids: list[str]
) -> list[Path]:
    """Find conversation files by their session IDs."""
    files = []
    id_set = set(conversation_ids)

    for project_dir in projects_dir.iterdir():
        if not project_dir.is_dir():
            continue

        for jsonl_file in project_dir.glob("*.jsonl"):
            if jsonl_file.stem in id_set:
                files.append(jsonl_file)

    return files


def find_conversations_by_paths(conversation_paths: list[str]) -> list[Path]:
    """Find conversation files by their full paths."""
    files = []
    for path_str in conversation_paths:
        path = Path(path_str)
        if path.exists():
            files.append(path)
    return files


def parse_conversation(file_path: Path) -> dict:
    """Parse a single conversation file and extract all information."""
    conversation = {
        "file": str(file_path),
        "project": file_path.parent.name,
        "session_id": file_path.stem,
        "summary": None,
        "exchanges": [],
        "tool_uses": [],
        "errors": [],
        "files_modified": [],
        "timestamps": {"start": None, "end": None}
    }

    with open(file_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            entry_type = entry.get("type")
            timestamp = entry.get("timestamp")

            # Track timestamps
            if timestamp:
                if not conversation["timestamps"]["start"]:
                    conversation["timestamps"]["start"] = timestamp
                conversation["timestamps"]["end"] = timestamp

            # Extract summary
            if entry_type == "summary":
                conversation["summary"] = entry.get("summary")

            # Extract user messages
            elif entry_type == "user":
                message = entry.get("message", {})
                content = message.get("content", "")

                # Skip meta messages
                if entry.get("isMeta"):
                    continue

                # Include command invocations but mark them
                is_command = "<command-name>" in content

                conversation["exchanges"].append({
                    "role": "user",
                    "content": content[:3000],  # Slightly longer truncation
                    "timestamp": timestamp,
                    "is_command": is_command
                })

            # Extract assistant messages
            elif entry_type == "assistant":
                message = entry.get("message", {})
                content_parts = message.get("content", [])

                text_content = []
                tools_used = []

                for part in content_parts:
                    if isinstance(part, dict):
                        part_type = part.get("type")

                        if part_type == "text":
                            text_content.append(part.get("text", ""))

                        elif part_type == "tool_use":
                            tool_name = part.get("name")
                            tool_input = part.get("input", {})

                            tool_info = {
                                "tool": tool_name,
                                "input_summary": summarize_tool_input(tool_input),
                                "raw_input": tool_input
                            }
                            tools_used.append(tool_info)

                            # Track file modifications
                            if tool_name in ["Write", "Edit", "MultiEdit"]:
                                file_path_modified = tool_input.get("file_path")
                                if file_path_modified:
                                    conversation["files_modified"].append({
                                        "file": file_path_modified,
                                        "tool": tool_name,
                                        "timestamp": timestamp
                                    })

                            conversation["tool_uses"].append({
                                **tool_info,
                                "timestamp": timestamp
                            })

                if text_content or tools_used:
                    conversation["exchanges"].append({
                        "role": "assistant",
                        "content": "\n".join(text_content)[:3000],
                        "tools": tools_used,
                        "timestamp": timestamp
                    })

            # Extract tool results
            elif entry_type == "tool_result":
                content = entry.get("content", "")
                tool_use_id = entry.get("tool_use_id", "")

                # Track errors
                if isinstance(content, str):
                    content_lower = content.lower()
                    if "error" in content_lower or "failed" in content_lower or "exception" in content_lower:
                        conversation["errors"].append({
                            "content": content[:1000],
                            "tool_use_id": tool_use_id,
                            "timestamp": timestamp
                        })

    # Deduplicate files_modified
    seen_files = set()
    unique_files = []
    for f in conversation["files_modified"]:
        if f["file"] not in seen_files:
            seen_files.add(f["file"])
            unique_files.append(f)
    conversation["files_modified"] = unique_files

    return conversation


def summarize_tool_input(input_data: dict) -> str:
    """Create a brief summary of tool input."""
    if not input_data:
        return ""

    # For common tools, extract key info
    if "file_path" in input_data:
        return f"file: {input_data['file_path']}"
    if "command" in input_data:
        cmd = input_data["command"]
        return f"cmd: {cmd[:150]}" if len(cmd) > 150 else f"cmd: {cmd}"
    if "pattern" in input_data:
        return f"pattern: {input_data['pattern']}"
    if "query" in input_data:
        q = input_data["query"]
        if isinstance(q, list):
            return f"query: {q}"
        return f"query: {q[:100]}" if len(str(q)) > 100 else f"query: {q}"
    if "prompt" in input_data:
        return f"prompt: {input_data['prompt'][:150]}..."
    if "content" in input_data:
        return f"content: {len(input_data['content'])} chars"

    # Fallback: list keys
    return f"keys: {', '.join(input_data.keys())}"


def format_markdown(conversations: list[dict]) -> str:
    """Format extracted conversations as markdown."""
    output = []
    output.append("# Extracted Conversations")
    output.append(f"**Count**: {len(conversations)}")
    output.append(f"**Generated**: {datetime.now().isoformat()}")

    # Summary of projects
    projects = {}
    for conv in conversations:
        proj = conv["project"]
        projects[proj] = projects.get(proj, 0) + 1

    output.append(f"**Projects**: {len(projects)}")
    for proj, count in sorted(projects.items(), key=lambda x: -x[1]):
        output.append(f"  - {proj}: {count} conversations")
    output.append("")

    for conv in conversations:
        if not conv["exchanges"]:
            continue

        output.append(f"---")
        output.append(f"## Session: {conv['session_id'][:8]}")
        output.append(f"**Project**: `{conv['project']}`")
        output.append(f"**File**: `{conv['file']}`")
        if conv["summary"]:
            output.append(f"**Summary**: {conv['summary']}")
        output.append(f"**Time**: {conv['timestamps']['start']} → {conv['timestamps']['end']}")
        output.append("")

        # Files modified
        if conv["files_modified"]:
            output.append("### Files Modified")
            for f in conv["files_modified"][:15]:
                output.append(f"- `{f['file']}` ({f['tool']})")
            if len(conv["files_modified"]) > 15:
                output.append(f"- ... and {len(conv['files_modified']) - 15} more")
            output.append("")

        # Tool usage summary
        if conv["tool_uses"]:
            tool_counts = {}
            for t in conv["tool_uses"]:
                tool = t["tool"]
                tool_counts[tool] = tool_counts.get(tool, 0) + 1

            output.append("### Tools Used")
            for tool, count in sorted(tool_counts.items(), key=lambda x: -x[1]):
                output.append(f"- {tool}: {count}")
            output.append("")

        # Errors
        if conv["errors"]:
            output.append("### Errors Encountered")
            for e in conv["errors"][:5]:
                error_preview = e['content'][:200].replace('\n', ' ')
                output.append(f"- {error_preview}...")
            output.append("")

        # Conversation exchanges (user messages only for brevity)
        user_messages = [e for e in conv["exchanges"] if e["role"] == "user" and not e.get("is_command")]
        if user_messages:
            output.append("### User Requests")
            for msg in user_messages[:10]:
                content = msg["content"]
                if isinstance(content, list):
                    content = " ".join(str(c) for c in content)
                content = str(content)[:300].replace('\n', ' ')
                output.append(f"- {content}")
            if len(user_messages) > 10:
                output.append(f"- ... and {len(user_messages) - 10} more messages")
            output.append("")

    return "\n".join(output)


def format_json(conversations: list[dict]) -> str:
    """Format extracted conversations as JSON."""
    return json.dumps(conversations, indent=2, default=str)


def main():
    parser = argparse.ArgumentParser(
        description="Extract Claude Code conversations for analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Recent conversations from current project
  python extract_conversations.py --days 3

  # All projects, last week
  python extract_conversations.py --days 7 --all-projects

  # Specific conversations by ID (from episodic-memory search)
  python extract_conversations.py --ids abc123,def456

  # By file paths
  python extract_conversations.py --paths /path/to/conv1.jsonl,/path/to/conv2.jsonl
"""
    )
    parser.add_argument("--days", type=int, default=2, help="Days to look back (default: 2)")
    parser.add_argument("--project", type=str, help="Project path filter")
    parser.add_argument("--all-projects", action="store_true", help="Include all projects")
    parser.add_argument("--from-today", action="store_true",
                       help="Count days from today instead of from last activity (default for --all-projects)")
    parser.add_argument("--id", type=str, help="Single conversation ID to fetch")
    parser.add_argument("--ids", type=str, help="Comma-separated conversation IDs to fetch")
    parser.add_argument("--paths", type=str, help="Comma-separated conversation file paths")
    parser.add_argument("--output", choices=["json", "markdown"], default="markdown",
                       help="Output format (default: markdown)")

    args = parser.parse_args()

    projects_dir = Path.home() / ".claude" / "projects"

    if not projects_dir.exists():
        print("Error: Claude projects directory not found", file=sys.stderr)
        sys.exit(1)

    # Determine which conversations to fetch
    files = []

    if args.paths:
        # Fetch by file paths
        paths = [p.strip() for p in args.paths.split(",")]
        files = find_conversations_by_paths(paths)
    elif args.id or args.ids:
        # Fetch by conversation IDs
        ids = []
        if args.id:
            ids.append(args.id)
        if args.ids:
            ids.extend([i.strip() for i in args.ids.split(",")])
        files = find_conversations_by_ids(projects_dir, ids)
    else:
        # Fetch by timeframe
        project_filter = None
        if not args.all_projects:
            if args.project:
                project_filter = get_project_key(args.project)
            else:
                cwd = os.getcwd()
                project_filter = get_project_key(cwd)

        # Activity-based is default for project-specific queries
        # (look back N days from last activity, not from today)
        # Use --from-today or --all-projects to use calendar days
        activity_based = not args.from_today and not args.all_projects

        files = find_conversation_files(projects_dir, project_filter, args.days, activity_based)

    if not files:
        print("No conversations found matching criteria", file=sys.stderr)
        sys.exit(0)

    # Parse conversations
    conversations = []
    for f in files:
        conv = parse_conversation(f)
        if conv["exchanges"]:
            conversations.append(conv)

    # Output
    if args.output == "json":
        print(format_json(conversations))
    else:
        print(format_markdown(conversations))


if __name__ == "__main__":
    main()
