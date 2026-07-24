---
title: Keep internal coordination out of public-shipped skill and reference files
date: 2026-07-24
category: docs/solutions/conventions
module: contribute skill / public-face front door
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Authoring or editing files that ship in the public package (skills/**, reference/**, or root docs listed in package.json `files`)"
  - "Building a skill that reflects public state or enforces a public/private boundary"
  - "Referencing internal coordination, tickets, or policy IDs in agent-facing prose"
tags: [external-only-content, public-private-boundary, agent-skills, shipped-artifacts, code-review]
---

# Keep internal coordination out of public-shipped skill and reference files

## Context

andamio-dev is a **public** repo and ships as a public package (npm + marketplace). AGENTS.md states the rule plainly: *"External-only content: No internal API details. Everything in this plugin should be derivable from public specs, docs, and the CLI."*

While building the public "contribution front door" (`/contribute`) — a feature whose entire job is to reflect only public state and keep private coordination out of a public repo — the first draft of the shipped skill and its reference registry named the private coordination mechanisms directly: internal board/circle names appeared inside the skill's own boundary rules, and an internal policy ID was used as a section heading. A five-persona plan review did not catch it. The code review (project-standards + maintainability personas) did, flagging it against the repo's own external-only rule.

The irony is the tell: the artifact most likely to leak internal names is the one whose purpose is to keep them private — the private terms sneak in as the "rules" that describe what to exclude.

## Guidance

Everything that ships must be **self-contained and derivable from public sources**. That includes skill instructions (`skills/**`), reference data *and its comments* (`reference/**`), and any root docs listed in `package.json` `files`.

In shipped prose, never name internal-only artifacts:

- Internal board / circle / coordination-process names
- Internal ticket, requirement, or policy IDs
- Private repo names

Describe the concept generically instead — say *what the boundary is*, not *what's on the other side of it*. "How work is prioritized is coordinated privately and lives elsewhere" carries the rule without naming the private machinery.

Two operational habits:

1. **Treat boundary-enforcing files as the first place to check.** A skill that exists to keep private things out is exactly where private names appear as exclusion rules.
2. **Grep the shipped surface before merge** for internal identifiers (board/circle names, policy-ID patterns) across `skills/`, `reference/`, and the root docs in `package.json` `files`.

Also mind the wider blast radius: the **public git repo is broader than the npm package**. Files under `docs/` (plans, brainstorms) are world-readable on a public repo even when they are not shipped to npm. Decide deliberately whether process artifacts that name internal mechanisms belong in a public repo at all.

## Why This Matters

- External readers have no internal context. An internal policy ID is meaningless to them and merely signals that an internal process they cannot see exists.
- It directly violates the repo's own external-only content rule — a self-inconsistency reviewers will (rightly) flag.
- For a boundary-enforcing feature it undercuts the feature's own premise: the public face is supposed to be the clean side of the line.
- **Plan review and code review catch different classes of issue.** This leak survived a thorough plan review because it lived in the *implementation prose* the plan didn't spell out word-for-word. Review the shipped artifact, not just the plan that led to it.

## When to Apply

- Editing anything under `skills/`, `reference/`, or root docs enumerated in `package.json` `files`.
- Building or changing a skill that reflects internal/external state or enforces a public/private boundary.
- Any time agent-facing prose is tempted to cite an internal ticket, policy, board, or private repo by name.

## Examples

Before (leaks internal names into a shipped file):

```text
Never consult, reference, or infer private coordination
(<internal-circle-name>, "<internal-board-name>", triage/priority/delegation).
```

After (same rule, self-contained):

```text
Never consult, reference, or infer how work is triaged, prioritized, or
delegated internally — that coordination is private and lives elsewhere.
```

Before (internal ID as a public heading):

```text
4. **<internal-policy-id> stays with Development.** ...
```

After (plain description):

```text
4. **Code quality and security stay with Development.** ...
```

Pre-merge guard — run over the shipped surface and expect no hits:

```bash
grep -rniE "<internal-board-pattern>|<internal-circle-pattern>|<internal-policy-id-pattern>" \
  skills/ reference/ $(node -e "console.log(require('./package.json').files.filter(f=>!f.includes('*')).join(' '))")
```

## Related

- `AGENTS.md` — "External-only content" convention (the rule this reinforces).
- `skills/contribute/SKILL.md` — the boundary-enforcing skill this surfaced in.
- `CONTRIBUTING-TO-ANDAMIO.md` — the public front-door doc, written public-safe from the start.
