#!/usr/bin/env python3
"""Report references to Andamio CLI commands that a release retires.

Why this exists: this repo documents the platform, and the CLI is one client of
it. When the CLI drops a command, every illustration using that command goes
stale — but the endpoints, loops and roles behind it do not change. Finding those
illustrations by hand is an audit; finding them with this is a command.

Retirements are recorded in reference/cli-retirements.yaml.

Usage:
    python3 scripts/check-cli-refs.py              # report hits, always exit 0
    python3 scripts/check-cli-refs.py --check      # exit 1 if any RELEASED
                                                   # retirement still has hits

While a release is still `unreleased`, hits are expected and correct — the docs
describe the shipped tool. Flip its status to `released` in the YAML when the tag
goes out, and --check turns the same list into the worklist.
"""

import argparse
import pathlib
import re
import subprocess
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / "reference" / "cli-retirements.yaml"
SKIP_PREFIXES = ("docs/plans/", "docs/brainstorms/")


def tracked_files():
    out = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files"], capture_output=True, text=True, check=True
    ).stdout.split()
    return [
        f
        for f in out
        if not f.startswith(SKIP_PREFIXES) and f != "reference/cli-retirements.yaml"
    ]


def scan(commands):
    """Return {command: {file: count}} for `andamio <command> ...` references."""
    patterns = {c: re.compile(r"andamio\s+" + r"\s+".join(map(re.escape, c.split())) + r"\b") for c in commands}
    found = {c: {} for c in commands}
    for rel in tracked_files():
        path = ROOT / rel
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except (OSError, UnicodeDecodeError):
            continue
        for cmd, rx in patterns.items():
            n = len(rx.findall(text))
            if n:
                found[cmd][rel] = n
    return found


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--check",
        action="store_true",
        help="exit 1 if a released retirement still has references",
    )
    args = ap.parse_args()

    cfg = yaml.safe_load(CONFIG.read_text())
    failed = False

    for entry in cfg.get("releases", []):
        rel = entry["release"]
        status = entry.get("status", "unreleased")
        cmds = entry.get("retired_commands", [])
        found = scan(cmds)
        total = sum(sum(v.values()) for v in found.values())

        print(f"CLI {rel} ({status}) — retires: {', '.join(cmds)}")
        if entry.get("tracking"):
            print(f"  tracking: {entry['tracking']}")

        if total == 0:
            print("  no references remain\n")
            continue

        print(f"  {total} reference(s) across "
              f"{len({f for v in found.values() for f in v})} file(s):")
        for cmd in cmds:
            for f, n in sorted(found[cmd].items(), key=lambda kv: -kv[1]):
                print(f"    {n:3}  {f}   (andamio {cmd} ...)")

        if status == "released":
            print(f"  FAIL: {rel} has shipped; these references are stale.\n")
            failed = True
        else:
            print(f"  OK: {rel} has not shipped — these describe the current tool.\n")

    if args.check and failed:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
