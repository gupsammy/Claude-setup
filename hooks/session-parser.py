#!/usr/bin/env python3
"""
Session Parser - Stop Hook
Incrementally parses session content and updates latest.md.
"""

import json
import sys
import re
from datetime import datetime
from pathlib import Path

CONTEXT_DIR = Path.home() / ".claude" / "session-context"
EXCHANGE_THRESHOLD = 3


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


def count_exchanges(jsonl_path):
    if not jsonl_path.exists():
        return 0
    count = 0
    has_user = False
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
            role = entry.get("message", {}).get("role")
            if etype == "user" and role == "user":
                if has_user:
                    count += 1
                has_user = True
    if has_user:
        count += 1
    return count


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


def main():
    try:
        input_data = json.load(sys.stdin)
    except:
        return

    session_id = input_data.get("session_id")
    if not session_id:
        return

    # Find state file
    state_file = None
    for pdir in CONTEXT_DIR.iterdir() if CONTEXT_DIR.exists() else []:
        if not pdir.is_dir():
            continue
        candidate = pdir / "sessions" / f"{session_id}.state"
        if candidate.exists():
            state_file = candidate
            break

    if not state_file:
        return

    try:
        state = json.loads(state_file.read_text())
    except:
        return

    jsonl_path = Path(state.get("jsonl_path", ""))
    project_hash = state.get("project_hash", "")
    parsing_enabled = state.get("parsing_enabled", False)

    if not jsonl_path.exists() or not project_hash:
        return

    project_dir = CONTEXT_DIR / project_hash

    if parsing_enabled:
        exchanges = parse_exchanges(jsonl_path)
        if len(exchanges) >= 2:
            context = build_context(exchanges)
            if context:
                (project_dir / "latest.md").write_text(context)
        state["exchange_count"] = len(exchanges)
        state_file.write_text(json.dumps(state))
    else:
        exc_count = count_exchanges(jsonl_path)
        if exc_count >= EXCHANGE_THRESHOLD:
            exchanges = parse_exchanges(jsonl_path)
            if len(exchanges) >= 2:
                context = build_context(exchanges)
                if context:
                    (project_dir / "latest.md").write_text(context)
            state["parsing_enabled"] = True
            state["exchange_count"] = len(exchanges)
        else:
            state["exchange_count"] = exc_count
        state_file.write_text(json.dumps(state))


if __name__ == "__main__":
    main()
