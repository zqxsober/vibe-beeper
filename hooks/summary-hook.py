#!/usr/bin/env python3
"""
Claude Code hook: fires on 'stop' event.
Reads the current session's JSONL, extracts the last assistant text message,
writes it to ~/.claude/claumagotchi/last_summary.txt
"""
import json
import os
import sys
import glob

SUMMARY_DIR = os.path.expanduser("~/.claude/claumagotchi")
SUMMARY_FILE = os.path.join(SUMMARY_DIR, "last_summary.txt")
CLAUDE_DIR = os.path.expanduser("~/.claude/projects")


def get_session_jsonl(session_id):
    """Find the JSONL file for a given session ID."""
    for root, dirs, files in os.walk(CLAUDE_DIR):
        for f in files:
            if f == f"{session_id}.jsonl":
                return os.path.join(root, f)
    return None


def get_most_recent_jsonl():
    """Fallback: find the most recently modified JSONL."""
    newest = None
    newest_time = 0
    for root, dirs, files in os.walk(CLAUDE_DIR):
        for f in files:
            if f.endswith(".jsonl"):
                path = os.path.join(root, f)
                mtime = os.path.getmtime(path)
                if mtime > newest_time:
                    newest_time = mtime
                    newest = path
    return newest


def extract_last_assistant_text(jsonl_path):
    """Read JSONL backwards, find last assistant message with text content."""
    if not jsonl_path or not os.path.exists(jsonl_path):
        return ""

    last_text = ""
    with open(jsonl_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                if obj.get("type") != "assistant":
                    continue
                message = obj.get("message", {})
                content = message.get("content", [])
                texts = []
                for block in content:
                    if block.get("type") == "text":
                        t = block.get("text", "").strip()
                        if t:
                            texts.append(t)
                if texts:
                    last_text = "\n\n".join(texts)
            except (json.JSONDecodeError, KeyError, TypeError):
                continue

    return last_text


def main():
    # Read hook input from stdin
    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        hook_input = {}

    session_id = hook_input.get("session_id", "")

    # Try session-specific JSONL first, fallback to most recent
    jsonl_path = None
    if session_id:
        jsonl_path = get_session_jsonl(session_id)
    if not jsonl_path:
        jsonl_path = get_most_recent_jsonl()

    last_text = extract_last_assistant_text(jsonl_path)

    if not last_text:
        return

    # Write summary
    os.makedirs(SUMMARY_DIR, exist_ok=True)
    with open(SUMMARY_FILE, "w") as f:
        f.write(last_text)


if __name__ == "__main__":
    main()
