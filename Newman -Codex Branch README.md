# Branch Readme: Codex Agent Compatibility

Branch: `newman-codex`

This branch makes `andamio-dev` easier to use from OpenAI Codex while preserving the repo's original Claude Code plugin support. The main change is architectural: the canonical skill implementations now live in the portable `skills/` directory, and agent-specific folders act as compatibility surfaces instead of separate sources of truth.

## Why This Branch Exists

`andamio-dev` started as a Claude Code plugin. That worked well for Claude-specific workflows, but it made reuse in other agent harnesses less obvious. Codex discovers project skills from `.agents/skills/`, while Claude Code has historically discovered skills from `.claude/skills/`.

This branch aligns the repo with an agent-neutral model:

- portable skill definitions live in `skills/`
- Codex discovers those skills through `.agents/skills/`
- Claude compatibility remains available through `.claude/skills/`
- course delivery, lesson assessment, API exploration, CLI guidance, troubleshooting, and operational workflows all share the same canonical instructions

The result is a repo that can be shared with the Andamio team as a portable Agent Skills package, not only as a Claude plugin.

## What Changed

### 1. Added Codex project-skill compatibility

Codex can discover project-local skills from `.agents/skills/`. This branch adds `.agents/skills/` entries as relative symlinks back to the canonical portable skills:

```text
.agents/skills/start -> ../../skills/start
.agents/skills/learn -> ../../skills/learn
.agents/skills/deliver-lesson -> ../../skills/deliver-lesson
.agents/skills/assess-assignment -> ../../skills/assess-assignment
.agents/skills/explore-api -> ../../skills/explore-api
.agents/skills/cli-guide -> ../../skills/cli-guide
.agents/skills/auth-setup -> ../../skills/auth-setup
.agents/skills/cost-estimator -> ../../skills/cost-estimator
.agents/skills/course-ops -> ../../skills/course-ops
.agents/skills/project-ops -> ../../skills/project-ops
.agents/skills/troubleshoot -> ../../skills/troubleshoot
.agents/skills/compound -> ../../skills/compound
.agents/skills/orientation -> ../../skills/orientation
```

These are intentionally symlinks, not copied directories. That keeps `skills/` as the source of truth and prevents drift between agent environments.

### 2. Made the learning harness agent-neutral

The `/learn` workflow no longer depends on Claude-only subagent calls for normal operation. In Codex, the same workflow runs inline:

- `skills/learn/SKILL.md` orchestrates course progress
- `skills/deliver-lesson/SKILL.md` defines the teaching protocol
- `skills/assess-assignment/SKILL.md` defines assignment review
- `progress.json` tracks learner state locally in clone/symlink context

Claude-specific instructor and assessor files can remain as compatibility helpers, but they are no longer the canonical behavior.

### 3. Kept Claude support as a compatibility layer

The `.claude/skills/` entries now act as wrappers that point back to `skills/`. This lets Claude-oriented tooling keep working while making it clear that portable skills live outside `.claude/`.

The intended ownership model is:

| Location          | Purpose                                     |
| ----------------- | ------------------------------------------- |
| `skills/`         | Canonical portable Agent Skills             |
| `.agents/skills/` | Codex/project discovery symlinks            |
| `.claude/skills/` | Claude compatibility wrappers               |
| `.claude/agents/` | Claude-specific helper agents, where useful |

### 4. Added Codex setup documentation

`SETUP.md` now documents a Windows, WSL, and Codex path:

1. install WSL
2. clone the repo inside the Linux filesystem
3. install and verify Codex
4. create `.agents/skills/` symlinks
5. install and configure the Andamio CLI
6. authenticate against preprod
7. invoke Andamio skills from Codex

This is intended to make onboarding repeatable for Andamio team members testing Codex.

### 5. Updated project-level agent guidance

`AGENTS.md`, `CLAUDE.md`, and `README.md` now describe the repo as an Agent Skills package with multiple compatibility surfaces. They document the important conventions for future contributors:

- `skills/` is the portable source of truth
- do not copy skill directories into `.agents/skills/`
- operational mode should use the Andamio CLI
- learning mode should explain API calls and protocol mechanics
- preprod is the default environment
- compiled outputs and local progress files should not be treated as source

## How To Use This Branch With Codex

From the repo root:

```bash
codex
```

Then invoke a skill naturally:

```text
$start
```

or:

```text
Use the explore-api skill. What course endpoints can I query with only an API key?
```

or:

```text
Use the learn skill. Start the Build on Andamio course.
```

Codex should discover the skills through `.agents/skills/` and then execute the canonical instructions from `skills/`.

## Verification Checklist

Use these checks before publishing or sharing the branch:

```bash
find -L .agents/skills -maxdepth 2 -name SKILL.md -print | sort
```

Expected result: one `SKILL.md` for each portable skill.

```bash
codex --version
```

Expected result: Codex is installed and runnable from the repo root.

```bash
andamio --version
andamio config show
```

Expected result: the Andamio CLI is installed and pointed at preprod unless intentionally testing another environment.

Manual Codex smoke tests:

- `$start` shows the Andamio Dev entry flow
- `$learn` or "start the course" initializes or resumes course progress
- `Use the cli-guide skill` returns exact Andamio CLI commands
- `Use the explore-api skill` reads from the bundled API spec
- `Use the troubleshoot skill` can diagnose common CLI/API/transaction errors

## What This Branch Does Not Do

This branch does not add a build step, test suite, or application runtime. This repo is still a documentation, course, reference, and skill package.

It also does not make `.agents/skills/` a second canonical skill tree. The symlinks are only a compatibility layer for project-local skill discovery.

## Notes For Reviewers

When reviewing this branch, focus on these questions:

- Does `skills/` clearly read as the canonical portable skill source?
- Are the `.agents/skills/` symlinks correct and relative?
- Are the Claude wrappers clear enough for backward compatibility?
- Does `SETUP.md` give a new Codex user enough to start in WSL?
- Do the learning and operational modes remain clear across `README.md`, `AGENTS.md`, and individual skills?

The main goal is to let Andamio maintain one skill package that works across Claude Code, Codex, and other Agent Skills-compatible environments.
