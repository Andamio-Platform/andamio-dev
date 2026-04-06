# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read [AGENTS.md](AGENTS.md) for full project context — API specs, authentication model, environments, and conventions.

## What This Repo Is

**andamio-dev** is a Claude Code plugin (not a code project). It provides:
1. **A 7-module course** ("Build on Andamio") delivered by AI agent skills
2. **Operational skills** for day-to-day Andamio development (API exploration, CLI guidance, cost estimation)
3. **Bundled specs and reference** for the Andamio Gateway API (111 endpoints), Andamioscan (34 endpoints), cost registry, and CLI

There is no build step, no test suite, no linter. "Testing" means invoking skills in Claude Code and verifying behavior.

## Architecture

Two skill systems coexist, with different locations:

| System | Location | Purpose |
|--------|----------|---------|
| Plugin skills | `skills/` (10 skills) | Operational — API exploration, CLI guide, auth setup, cost estimator, course/project ops, troubleshooting, compounding |
| Course harness | `.claude/skills/` (3 skills) + `.claude/agents/` (2 agents) | Teaching — lesson delivery, assignment assessment, progress orchestration |

**Course harness flow**: `/learn` skill orchestrates → spawns `instructor` agent (for lessons) or `assessor` agent (for assignments) → agents use `deliver-lesson` / `assess-assignment` skills → progress tracked in `progress.json`.

**Course content**: `courses-in-progress/build-on-andamio/lessons/m{N}/` — modules 100–400 have lessons, 500–700 are not yet drafted.

**Knowledge base**: `knowledge/*.yaml` — append-only YAML files. Always increment counts, never overwrite. Update `knowledge/index.yaml` after extraction.

**Path resolution**: When `${CLAUDE_PLUGIN_ROOT}` is set (plugin context), read specs from there. Otherwise all paths are project-relative.

## Key Conventions

- **Two modes**: Skills detect *learning* vs *operational* intent. Learning mode explains and teaches; operational mode executes via CLI with `--output json`.
- **CLI-first in operational mode**: Always use the Andamio CLI for operations. Direct API calls are for learning mode only.
- **Agent Skills standard**: All skill definitions use YAML frontmatter (`name`, `description`, `license`, `metadata`).
- **Modules are sequentially gated**: A module's assignment must pass before the next module unlocks.
- **All agents use `model: "opus"`**.
- **Exclude admin endpoints**: Skills should filter out `/v1/admin/*` and internal state management endpoints when presenting to developers.
- **Preprod first**: Always target `preprod.api.andamio.io`. Mainnet uses real ADA.

## Working with Skills

To test a skill change: invoke the corresponding slash command (`/explore-api`, `/cli-guide`, `/learn`, etc.) in Claude Code and verify the behavior.

To add a new plugin skill: create `skills/<name>/SKILL.md` with Agent Skills frontmatter. To add a course harness skill: create `.claude/skills/<name>/SKILL.md`.

## Releasing

Published via npm (`@andamio/dev`) and the Andamio marketplace. `package.json` `files` array controls what ships. Releases are coordinated by the Andamio team.
