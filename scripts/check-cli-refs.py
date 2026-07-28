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
    # -z / NUL split: paths containing spaces (this repo has one) must survive.
    out = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "-z"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split("\0")
    return [
        f
        for f in out
        if f
        and not f.startswith(SKIP_PREFIXES)
        and f != "reference/cli-retirements.yaml"
    ]


def load_files():
    """Read every tracked file once. Returns [(relpath, text)]."""
    loaded = []
    for rel in tracked_files():
        try:
            loaded.append((rel, (ROOT / rel).read_text(encoding="utf-8", errors="ignore")))
        except (OSError, UnicodeDecodeError):
            continue
    return loaded


def scan(commands, files):
    """Return {command: {file: (prefixed, bare)}}.

    `prefixed` counts full `andamio <command> ...` invocations. `bare` counts
    mentions of the command path without the binary name — the shape used by the
    command tables in reference/andamio-cli-context.md and skills/cli-guide, which
    go just as stale on retirement but are invisible to a prefix-anchored match.
    """
    patterns = {}
    for c in commands:
        tail = r"\s+".join(map(re.escape, c.split()))
        patterns[c] = (
            re.compile(r"andamio\s+" + tail + r"\b"),
            re.compile(r"(?:andamio\s+)?\b" + tail + r"\b"),
        )
    found = {c: {} for c in commands}
    for rel, text in files:
        for cmd, (rx_prefixed, rx_any) in patterns.items():
            prefixed = len(rx_prefixed.findall(text))
            bare = len(rx_any.findall(text)) - prefixed
            if prefixed or bare:
                found[cmd][rel] = (prefixed, bare)
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
    files = load_files()

    for entry in cfg.get("releases", []):
        rel = entry["release"]
        status = entry.get("status", "unreleased")
        cmds = entry.get("retired_commands", [])
        found = scan(cmds, files)
        total_prefixed = sum(p for v in found.values() for p, _ in v.values())
        total_bare = sum(b for v in found.values() for _, b in v.values())
        total = total_prefixed + total_bare

        print(f"CLI {rel} ({status}) — retires: {', '.join(cmds)}")
        if entry.get("tracking"):
            print(f"  tracking: {entry['tracking']}")

        if total == 0:
            print("  no references remain\n")
            continue

        print(f"  {total} reference(s) "
              f"({total_prefixed} invocation, {total_bare} bare mention) across "
              f"{len({f for v in found.values() for f in v})} file(s):")
        for cmd in cmds:
            for f, (p, b) in sorted(found[cmd].items(), key=lambda kv: -sum(kv[1])):
                shape = f"{p:3} inv"
                if b:
                    shape += f" + {b:3} bare"
                else:
                    shape += " " * 10
                print(f"    {shape}  {f}   ({cmd})")

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
