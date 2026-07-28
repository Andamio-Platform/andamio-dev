#!/usr/bin/env python3
"""Generate reference/api-endpoints-by-use-case.md from the public API contract.

The index is derived, never hand-maintained. Its predecessor was written by hand and
drifted to 0 valid paths out of 49 in ten weeks, so the only durable fix is to stop
keeping a second copy of the contract by hand.

Usage:
    python3 scripts/gen-endpoint-index.py            # regenerate in place
    python3 scripts/gen-endpoint-index.py --check    # exit 1 if out of date

Input is specs/andamio-api.yaml, which is itself synced from the generated public
artifact in andamio-api. Nothing here reads a private repo.
"""

import argparse
import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPEC = ROOT / "specs" / "andamio-api.yaml"
OUT = ROOT / "reference" / "api-endpoints-by-use-case.md"

METHODS = ("get", "post", "put", "delete", "patch")


def auth_label(op, spec):
    sec = op.get("security", spec.get("security", []))
    if not sec:
        return "None"
    names = sorted({k for entry in sec for k in entry})
    pretty = {"ApiKeyAuth": "API key", "BearerAuth": "JWT", "UserJWT": "user JWT"}
    return " + ".join(pretty.get(n, n) for n in names)


def build(spec):
    tags = {t["name"]: t for t in spec.get("tags", [])}
    groups = spec.get("x-tagGroups", [])

    # tag -> [(method, path, summary, auth)]
    by_tag = {}
    for path, item in spec["paths"].items():
        for method, op in item.items():
            if method not in METHODS:
                continue
            row = (
                method.upper(),
                path,
                (op.get("summary") or "").strip(),
                auth_label(op, spec),
            )
            for tag in op.get("tags") or ["Untagged"]:
                by_tag.setdefault(tag, []).append(row)

    total = sum(len(v) for v in by_tag.values())
    base = spec.get("basePath", "")

    out = [
        "<!-- GENERATED FILE — DO NOT EDIT BY HAND.",
        "     Regenerate with: python3 scripts/gen-endpoint-index.py",
        "     Source: specs/andamio-api.yaml (the public API contract). -->",
        "",
        "# Andamio API endpoints by use case",
        "",
        f'> "I want to ___" → endpoint. Generated from the public contract in '
        f"`specs/andamio-api.yaml`, so it cannot drift from it.",
        "",
        f"**{total} operations across {len(spec['paths'])} paths.** All paths are relative to "
        f"`{base}`. This is the public surface only — administrative and internal operations are "
        "not part of the contract and do not appear here.",
        "",
        "For full request and response schemas, read the spec directly or use the "
        "`/explore-api` skill.",
        "",
    ]

    seen = set()
    for group in groups:
        group_tags = [t for t in group.get("tags", []) if t in by_tag]
        if not group_tags:
            continue
        out += [f"## {group['name']}", ""]
        for tag in group_tags:
            seen.add(tag)
            meta = tags.get(tag, {})
            heading = meta.get("x-displayName") or tag
            out += [f"### {heading}", ""]
            if meta.get("description"):
                out += [meta["description"].strip(), ""]
            out += ["| I want to... | Endpoint | Auth |", "|---|---|---|"]
            for method, path, summary, auth in sorted(by_tag[tag], key=lambda r: r[1]):
                out.append(f"| {summary or '—'} | `{method} {path}` | {auth} |")
            out.append("")

    leftover = sorted(set(by_tag) - seen)
    if leftover:
        out += ["## Other", ""]
        for tag in leftover:
            out += [f"### {tag}", "", "| I want to... | Endpoint | Auth |", "|---|---|---|"]
            for method, path, summary, auth in sorted(by_tag[tag], key=lambda r: r[1]):
                out.append(f"| {summary or '—'} | `{method} {path}` | {auth} |")
            out.append("")

    return "\n".join(out).rstrip() + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="exit 1 if the file is out of date")
    args = ap.parse_args()

    spec = yaml.safe_load(SPEC.read_text())
    content = build(spec)

    if args.check:
        current = OUT.read_text() if OUT.exists() else ""
        if current != content:
            print(f"{OUT.relative_to(ROOT)} is out of date — run gen-endpoint-index.py", file=sys.stderr)
            return 1
        print(f"{OUT.relative_to(ROOT)} is current")
        return 0

    OUT.write_text(content)
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
