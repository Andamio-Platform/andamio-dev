# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read [AGENTS.md](AGENTS.md) for full project context — API specs, authentication model, environments, and conventions.

## What This Repo Is

**andamio-dev** is an Agent Skills package originally built as a Claude Code plugin (not a code project). It provides:
1. **A 7-module course** ("Build on Andamio") delivered by AI agent skills
2. **Operational skills** for day-to-day Andamio development (API exploration, CLI guidance, cost estimation)
3. **Bundled specs and reference** for the Andamio Gateway API (111 endpoints), cost registry, and CLI

There is no build step, no test suite, no linter. "Testing" means invoking skills in an agent harness such as Claude Code or Codex and verifying behavior.

## Architecture

`skills/` is the portable source of truth for all skills. Compatibility surfaces may point at it.

| System | Location | Purpose |
|--------|----------|---------|
| Portable skills | `skills/` (13 skills) | Learning and operations — `/learn`, lesson delivery, assessment, API exploration, CLI guide, auth setup, cost estimator, course/project ops, troubleshooting, compounding |
| Codex/project discovery | `.agents/skills/` | Relative symlinks to `skills/` |
| Claude compatibility | `.claude/skills/` | Thin wrappers that point to canonical skills in `skills/` |

**Course harness flow**: `/learn` orchestrates inline → uses `deliver-lesson` for teaching and `assess-assignment` for evidence review → progress tracked in `progress.json`. Claude-specific instructor/assessor agent files may remain for compatibility, but canonical behavior belongs in `skills/`.

**Course content**: `courses/build-on-andamio/` is the source of truth for the course. Lessons live in `courses/build-on-andamio/lessons/m{N}/`; SLTs in `01-slts.md`; assignments in each module's `assignment.md`. All seven modules (100–700) have drafted lessons.

**Compiled artifacts**: `compiled/` is a gitignored build output produced by the `coach:compile` skill for `andamio course import-all`. Treat it as ephemeral — never edit compiled files, never commit them. Source always wins.

**Reference data**: `reference/tx-loops.yaml` is the canonical source for all Andamio transaction workflows. Each loop has named steps (off-chain and on-chain), exact CLI commands, roles, prerequisites, validated fees, and known gotchas. **Read this file first when running or testing transactions** — it is more complete than the tx-flow docs in devkit or the individual course lessons. For acceptance testing setup, also read `reference/acceptance-test-prerequisites.md`.

**Knowledge base**: `knowledge/*.yaml` — append-only YAML files. Always increment counts, never overwrite. Update `knowledge/index.yaml` after extraction.

**Path resolution**: When `${CLAUDE_PLUGIN_ROOT}` is set (plugin context), read specs from there. Otherwise all paths are project-relative.

## Key Conventions

- **Two modes**: Skills detect *learning* vs *operational* intent. Learning mode explains and teaches; operational mode executes via CLI with `--output json`.
- **CLI-first in operational mode**: Always use the Andamio CLI for operations. Direct API calls are for learning mode only.
- **Agent Skills standard**: All skill definitions use YAML frontmatter (`name`, `description`, `license`, `metadata`).
- **Modules are sequentially gated**: A module's assignment must pass before the next module unlocks.
- **Exclude admin endpoints**: Skills should filter out `/v1/admin/*` and internal state management endpoints when presenting to developers.
- **Preprod first**: Always target `preprod.api.andamio.io`. Mainnet uses real ADA.

## Working with Skills

To test a skill change: invoke the corresponding skill (`/explore-api`, `/cli-guide`, `/learn`, etc. in Claude Code, or `$skill-name` / natural invocation in Codex) and verify the behavior.

To add a new skill: create `skills/<name>/SKILL.md` with Agent Skills frontmatter. Add a relative symlink under `.agents/skills/` only when project-local discovery needs it. Do not make `.claude/skills/` the canonical source.

## Releasing

Published via npm (`@andamio/dev`) and the Andamio marketplace. `package.json` `files` array controls what ships. Releases are coordinated by the Andamio team.
