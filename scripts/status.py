#!/usr/bin/env python3
"""Update a game's pipeline status (shown on the website).

Usage:
  python3 scripts/status.py <slug> stage <research|ideas|approval|branches|manager|checker|signoff|done>
  python3 scripts/status.py <slug> branch <gameplay|graphics|ui> <waiting|working|blocked|done>
  python3 scripts/status.py <slug> log <from> <to> "<message>"

Roles: charlie, ideas, gameplay, graphics, ui, manager, checker, all
"""
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STAGES = ["research", "ideas", "approval", "branches", "manager", "checker", "signoff", "done"]
BRANCHES = ["gameplay", "graphics", "ui", "audio", "animation"]
BRANCH_STATES = ["waiting", "working", "blocked", "done"]
ROLES = ["charlie", "rnd", "ideas", "gameplay", "graphics", "ui", "audio", "animation", "manager", "checker", "all"]


def die(msg: str):
    print("error:", msg, file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) < 3:
        die(__doc__)
    slug, cmd, args = sys.argv[1], sys.argv[2], sys.argv[3:]
    path = ROOT / "games" / slug / "status.json"
    if not path.exists():
        die(f"{path} not found")
    data = json.loads(path.read_text())
    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

    if cmd == "stage":
        if not args or args[0] not in STAGES:
            die(f"stage must be one of {STAGES}")
        data["stage"] = args[0]
        data["log"].append({"time": now, "from": "system", "to": "all", "text": f"Stage → {args[0]}"})
    elif cmd == "branch":
        if len(args) < 2 or args[0] not in BRANCHES or args[1] not in BRANCH_STATES:
            die(f"usage: branch <{'|'.join(BRANCHES)}> <{'|'.join(BRANCH_STATES)}>")
        data["branches"][args[0]] = args[1]
    elif cmd == "log":
        if len(args) < 3 or args[0] not in ROLES or args[1] not in ROLES:
            die(f"usage: log <from> <to> <message>; roles: {ROLES}")
        data["log"].append({"time": now, "from": args[0], "to": args[1], "text": " ".join(args[2:])})
    else:
        die(f"unknown command {cmd}")

    data["updated"] = now
    path.write_text(json.dumps(data, indent=2) + "\n")
    print("ok")


if __name__ == "__main__":
    main()
