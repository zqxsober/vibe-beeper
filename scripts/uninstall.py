#!/usr/bin/env python3
"""Removes CC-Beeper hooks from Claude Code settings."""

import json
import os
import shutil
import subprocess

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")
HOOKS_DIR = os.path.expanduser("~/.claude/hooks")
IPC_DIR = os.path.expanduser("~/.claude/cc-beeper")
HOOK_SCRIPT = os.path.join(HOOKS_DIR, "cc-beeper-hook.py")

# Match legacy Python-script hooks AND the current HTTP-curl hooks.
# The HTTP hook marker mirrors HookInstaller.swift (`hookMarker = "cc-beeper/port"`).
HOOK_MATCH_FRAGMENTS = ("cc-beeper-hook.py", "cc-beeper/port")

HOOK_EVENTS = [
    "PreToolUse", "PostToolUse", "PermissionRequest",
    "Notification", "Stop", "StopFailure", "UserPromptSubmit",
    "SessionStart", "SessionEnd",
]


def main():
    # Kill running app
    try:
        subprocess.run(["pkill", "-x", "CC-Beeper"],
                       capture_output=True, check=False)
        print("  Stopped CC-Beeper app")
    except Exception:
        pass

    # Remove hook script
    if os.path.exists(HOOK_SCRIPT):
        os.remove(HOOK_SCRIPT)
        print(f"  Removed {HOOK_SCRIPT}")

    # Clean hooks from settings
    if os.path.exists(SETTINGS_PATH):
        try:
            with open(SETTINGS_PATH) as f:
                settings = json.load(f)
        except (json.JSONDecodeError, IOError):
            print(f"  WARNING: Could not parse {SETTINGS_PATH}")
            return

        hooks = settings.get("hooks", {})
        changed = False

        def is_ccbeeper_hook(h):
            cmd = h.get("command", "")
            return any(frag in cmd for frag in HOOK_MATCH_FRAGMENTS)

        for event in HOOK_EVENTS:
            existing = hooks.get(event, [])
            filtered = []
            for rule in existing:
                rule_hooks = rule.get("hooks", [])
                remaining = [h for h in rule_hooks if not is_ccbeeper_hook(h)]
                if not remaining:
                    # Whole rule was a cc-beeper hook — drop it.
                    continue
                if len(remaining) != len(rule_hooks):
                    new_rule = dict(rule)
                    new_rule["hooks"] = remaining
                    filtered.append(new_rule)
                else:
                    filtered.append(rule)
            if len(filtered) != len(existing):
                changed = True
                if filtered:
                    hooks[event] = filtered
                else:
                    del hooks[event]

        if changed:
            settings["hooks"] = hooks
            with open(SETTINGS_PATH, "w") as f:
                json.dump(settings, f, indent=2)
            print(f"  Cleaned hooks from {SETTINGS_PATH}")

    # Clean IPC directory
    if os.path.exists(IPC_DIR):
        shutil.rmtree(IPC_DIR)
        print(f"  Removed {IPC_DIR}")

    print()
    print("  CC-Beeper uninstalled!")
    print("  You can safely delete this folder now.")


if __name__ == "__main__":
    main()
