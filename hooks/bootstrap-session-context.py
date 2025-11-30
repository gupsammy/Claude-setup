#!/usr/bin/env python3
"""
Bootstrap Session Context - One-time Setup Script

Scans all existing projects and generates latest.md for each,
so session context is available immediately after installation.

Usage: python3 bootstrap-session-context.py
"""

import json
import re
import hashlib
from datetime import datetime
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"
CONTEXT_DIR = Path.home() / ".claude" / "session-context"
EXCHANGE_THRESHOLD = 2


def parse_timestamp(ts_str):
    if not ts_str:
        return None
    try:
        return datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
    except:
        return None


def format_time(dt):
    return dt.strftime("%H:%M") if dt else "??:??"


def extract_text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "thinking":
                    continue
                if item.get("type") == "text" and item.get("text"):
                    texts.append(item["text"])
            elif isinstance(item, str):
                texts.append(item)
        return "\n".join(texts)
    return ""


def extract_files(content):
    files = []
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "tool_use":
                name = item.get("name", "")
                inp = item.get("input", {})
                if name in ("Edit", "Write", "MultiEdit") and "file_path" in inp:
                    files.append(inp["file_path"])
    return files


def extract_commits(content):
    commits = []
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict) and item.get("type") == "tool_use":
                if item.get("name") == "Bash":
                    cmd = item.get("input", {}).get("command", "")
                    if "git commit" in cmd:
                        m = re.search(r'-m\s+["\']([^"\']+)["\']', cmd)
                        commits.append(m.group(1)[:100] if m else "(commit)")
    return commits


def is_noise(entry):
    if entry.get("type") == "file-history-snapshot" or entry.get("isMeta"):
        return True
    content = entry.get("message", {}).get("content", "")
    if isinstance(content, str) and ("<command-name>" in content or "<local-command-stdout>" in content):
        return True
    return False


def is_tool_result(entry):
    content = entry.get("message", {}).get("content", [])
    if isinstance(content, list) and content:
        first = content[0]
        if isinstance(first, dict) and first.get("type") == "tool_result":
            return True
    return False


def parse_exchanges(jsonl_path):
    if not jsonl_path.exists():
        return []
    exchanges = []
    user_msg, user_ts, asst_msg, files, commits = None, None, "", [], []

    with open(jsonl_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except:
                continue
            if is_noise(entry) or is_tool_result(entry):
                continue

            etype = entry.get("type")
            msg = entry.get("message", {})
            role = msg.get("role")
            content = msg.get("content", "")
            ts = parse_timestamp(entry.get("timestamp"))

            if etype == "user" and role == "user":
                if user_msg:
                    exchanges.append({
                        "ts": user_ts, "user": user_msg, "asst": asst_msg.strip(),
                        "files": files, "commits": commits
                    })
                text = extract_text(content).strip()
                if text and len(text) > 5:
                    user_msg, user_ts, asst_msg, files, commits = text, ts, "", [], []
                else:
                    user_msg = None

            elif etype == "assistant" and role == "assistant" and user_msg:
                text = extract_text(content).strip()
                if text:
                    asst_msg = f"{asst_msg}\n\n{text}" if asst_msg else text
                if isinstance(content, list):
                    files.extend(extract_files(content))
                    commits.extend(extract_commits(content))

    if user_msg:
        exchanges.append({
            "ts": user_ts, "user": user_msg, "asst": asst_msg.strip(),
            "files": files, "commits": commits
        })
    return exchanges


def build_context(exchanges):
    if len(exchanges) < 2:
        return ""

    total = len(exchanges)
    lines = []

    timestamps = [e["ts"] for e in exchanges if e["ts"]]
    start = format_time(min(timestamps)) if timestamps else "??:??"
    end = format_time(max(timestamps)) if timestamps else "??:??"
    lines.append(f"### Session: {start} → {end}\n")

    all_files = [f for e in exchanges for f in e["files"]]
    seen = list(dict.fromkeys(all_files))
    if seen:
        lines.append("### Files Modified")
        for f in seen[-10:]:
            lines.append(f"- `{f}`")
        if len(seen) > 10:
            lines.append(f"- ...and {len(seen) - 10} more")
        lines.append("")

    all_commits = [c for e in exchanges for c in e["commits"]]
    if all_commits:
        lines.append("### Git Commits")
        for c in all_commits:
            lines.append(f"- {c}")
        lines.append("")

    last3_start = max(0, total - 3)
    last3_idx = set(range(last3_start, total))

    if 0 not in last3_idx:
        lines.append("### Session Goal")
        lines.append(exchanges[0]["user"])
        lines.append("")

    other_idx = [i for i in range(1, last3_start)] if total > 4 else []
    if other_idx:
        lines.append("### Other Requests")
        for i in other_idx:
            msg = exchanges[i]["user"]
            lines.append(f"- {msg[:300]}..." if len(msg) > 300 else f"- {msg}")
        lines.append("")

    lines.append("### Where We Left Off (Last Exchanges)\n")
    for i in range(last3_start, total):
        e = exchanges[i]
        t = format_time(e["ts"])
        lines.append(f"**[{t}] User:**")
        lines.append(e["user"])
        lines.append("")
        if e["asst"]:
            lines.append(f"**[{t}] Assistant:**")
            lines.append(e["asst"])
            lines.append("")

    return "\n".join(lines)


def get_project_path_from_dir(project_dir_name):
    """Reverse the path encoding: -Users-foo--bar -> /Users/foo/.bar"""
    # This is approximate - we store the actual path in .project-path
    path = project_dir_name.replace("--", "/.").replace("-", "/")
    if not path.startswith("/"):
        path = "/" + path
    return path


def main():
    print("Bootstrap Session Context")
    print("=" * 50)

    if not PROJECTS_DIR.exists():
        print(f"No projects directory found at {PROJECTS_DIR}")
        return

    CONTEXT_DIR.mkdir(parents=True, exist_ok=True)

    stats = {"projects": 0, "generated": 0, "skipped": 0}

    for project_dir in sorted(PROJECTS_DIR.iterdir()):
        if not project_dir.is_dir():
            continue

        stats["projects"] += 1
        project_name = project_dir.name

        # Find all jsonl files, sorted by mtime (newest first)
        jsonl_files = []
        for f in project_dir.glob("*.jsonl"):
            # Skip agent sessions
            if f.name.startswith("agent-"):
                continue
            jsonl_files.append((f.stat().st_mtime, f))

        jsonl_files.sort(reverse=True)

        # Find first session with enough exchanges
        best_session = None
        for mtime, jsonl_path in jsonl_files:
            exchanges = parse_exchanges(jsonl_path)
            if len(exchanges) >= EXCHANGE_THRESHOLD:
                best_session = (jsonl_path, exchanges)
                break

        if not best_session:
            stats["skipped"] += 1
            continue

        jsonl_path, exchanges = best_session
        context = build_context(exchanges)

        if not context:
            stats["skipped"] += 1
            continue

        # Create project hash and directory
        # Try to get actual project path from first entry
        actual_path = get_project_path_from_dir(project_name)
        try:
            with open(jsonl_path) as f:
                first_line = f.readline().strip()
                if first_line:
                    entry = json.loads(first_line)
                    actual_path = entry.get("cwd", actual_path)
        except:
            pass

        project_hash = hashlib.md5(actual_path.encode()).hexdigest()[:16]
        project_context_dir = CONTEXT_DIR / project_hash
        project_context_dir.mkdir(parents=True, exist_ok=True)

        # Write latest.md
        (project_context_dir / "latest.md").write_text(context)
        (project_context_dir / ".project-path").write_text(actual_path)

        stats["generated"] += 1
        print(f"  ✓ {actual_path[:50]}...")

    print()
    print("=" * 50)
    print(f"Projects scanned: {stats['projects']}")
    print(f"Context generated: {stats['generated']}")
    print(f"Skipped (no valid sessions): {stats['skipped']}")
    print()
    print(f"Context stored in: {CONTEXT_DIR}")


if __name__ == "__main__":
    main()
