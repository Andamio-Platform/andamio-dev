# AGENTS.md

Project context for AI agents working in this repository. Read this file to understand the project, conventions, and workflow.

## Project Overview

**andamio-dev** is an Agent Skills package originally built as a Claude Code plugin. It serves two purposes: (1) delivering the "Build on Andamio" course via AI agent skills, and (2) providing operational skills for day-to-day Andamio development. The primary artifacts are course content (`courses/`), portable agent skill definitions (`skills/`), compatibility harnesses (`.agents/`, `.claude/`), bundled API specifications (`specs/`), CLI reference documentation (`reference/`), and a compounding knowledge base (`knowledge/`).

This is **not a code project**. There is no build step, no test suite, no linter.

## Directory Structure

```
skills/                   # Portable agent skills (Agent Skills standard, 13 skills)
  orientation/            # First-run experience — 15-minute guided walkthrough with hands-on exercises
  start/                  # Entry point — detect intent and mode, route to the right skill
  learn/                  # Course orchestrator — lessons, assignments, progress tracking
  deliver-lesson/         # Pedagogy guide for Build on Andamio lessons
  assess-assignment/      # Assessment guide for module assignment evidence
  auth-setup/             # API key + wallet JWT authentication walkthrough
  explore-api/            # Natural-language search across Gateway API endpoints
  cli-guide/              # Interactive CLI command guidance
  cost-estimator/         # ADA cost calculator for courses and projects
  course-ops/             # Course lifecycle: create, modules, teachers, content
  project-ops/            # Project lifecycle: create, tasks, contributors, treasury
  troubleshoot/           # Debug API errors, CLI failures, transaction rejections
  compound/               # Extract patterns from sessions into knowledge files
.agents/                  # Agent compatibility layer
  skills/                 # Relative symlinks to portable skills
courses/                  # Course source of truth (authored markdown)
  build-on-andamio/       # "Build on Andamio" — 7 modules, 31 SLTs
    00-course.md          # Course overview
    01-slts.md            # Canonical SLT list (all modules)
    lessons/m{N}/         # Lessons and assignment for each module (N = 100..700)
    drafting-guidelines.md, terminology.md, ...
.claude/                  # Claude compatibility harness
  skills/                 # Compatibility wrappers for course skills now canonical in skills/
  agents/instructor.md    # Delivers lessons, guides exercises
  agents/assessor.md      # Evaluates module assignments
examples/                 # Runnable scripts demonstrating full tx state machine loops
  course-lifecycle.sh     # Course: create → module → enroll → submit → assess → claim
  project-lifecycle.sh    # Project: create → task → commit → assess → claim
specs/                    # Bundled API specifications (read-only reference)
  andamio-api.yaml        # Andamio Gateway API (Swagger 2.0, 111 endpoints — single entry point)
  cost-registry.json      # Transaction cost data (fees, min UTXO, execution units)
reference/                # Bundled reference documentation
  andamio-cli-context.md  # CLI agent context (commands, auth, composability)
  tx-loops.yaml           # Canonical transaction workflows (source of truth for tx flows)
  acceptance-test-prerequisites.md
knowledge/                # Compound knowledge base (YAML files)
  index.yaml              # Master index and aggregate stats
  gotchas.yaml            # Known errors with root causes and fixes
  faq.yaml                # Frequently asked questions from developer sessions
  endpoint-usage.yaml     # Endpoint usage patterns and context
  cost-scenarios.yaml     # Real-world cost calculations
compiled/                 # Gitignored. Build output of `coach:compile` for `andamio course import-all`. Never edit.
progress.json             # Gitignored. Per-learner state written by the /learn skill.
```

## Bundled Assets

### Andamio API (`specs/andamio-api.yaml`)

The public-facing Andamio API. 111 endpoints across these groups:

| Group | Endpoints | Auth | Purpose |
|-------|-----------|------|---------|
| Auth | 7 | varies | Developer registration, wallet login, session management |
| API Key | 6 | JWT | Key lifecycle: request, rotate, revoke, usage |
| Courses | 24 | API key + JWT | Course CRUD, modules, teachers, student enrollment |
| Projects | 22 | API key + JWT | Project CRUD, tasks, contributors, treasury |
| Transactions | 24 | JWT | Build, sign, submit, register, track Cardano transactions |
| Users | 12 | varies | Profile, dashboard, access tokens |
| Billing | 4 | JWT | Subscription management |
| System | 2 | none | Health check, JWKS |

**Endpoint filtering**: Skills should exclude admin endpoints (`/v1/admin/*`) and internal state management endpoints when presenting options to developers.

### Cost Registry (`specs/cost-registry.json`)

Machine-readable transaction cost data including execution units, fee calculations, and min UTXO requirements for all Andamio transaction types.

### CLI Reference (`reference/andamio-cli-context.md`)

Complete CLI command reference: auth, config, course, teacher, project, manager, tx, apikey, spec. Includes composability contract, exit codes, agent workflow examples.

## Authentication Model

Two methods coexist:

| Method | Header | Access | How to Get |
|--------|--------|--------|------------|
| API Key | `X-API-Key` | Read-only | Register at preprod.app.andamio.io/api-setup |
| Wallet JWT | `Authorization: Bearer <jwt>` | Read + Write | `andamio user login` (browser wallet signing) |

Both headers are sent simultaneously when both credentials exist. JWT lifetime is ~24 hours.

## Environments

| Environment | Gateway URL | App URL | Network |
|-------------|-------------|---------|---------|
| Preprod (default) | preprod.api.andamio.io | preprod.app.andamio.io | Cardano Preprod testnet |
| Mainnet | mainnet.api.andamio.io | app.andamio.io | Cardano Mainnet |

**Always start on preprod.** Mainnet uses real ADA. Test ADA for preprod is free from the Cardano faucet.

## Conventions

**Skill format**: Agent Skills standard with YAML frontmatter (`name`, `description`, `license`, `metadata`).

**Skill source of truth**: `skills/` is the portable source of truth for all agent skills, including the learning course harness. `.agents/skills/` may contain relative symlinks back to `skills/` for agents that discover project skills there. Do not copy skill directories into `.agents/skills/`. `.claude/skills/` is a compatibility surface only; keep canonical course behavior in `skills/`.

**Path resolution**: Skills resolve paths based on execution context:
- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read specs/reference from `${CLAUDE_PLUGIN_ROOT}`. Read/write knowledge at `${CLAUDE_PLUGIN_DATA}/knowledge/`.
- **Clone context** (default): All paths relative to project root.

**Knowledge updates**: Append-only. Increment counts, don't overwrite. Deduplicate entries. Always update `knowledge/index.yaml` stats after extraction.

**Two modes — learning and operational**: Skills serve two modes detected from developer intent:
- **Learning mode** (questions: "how", "what", "why", "explain"): Show API calls, explain on-chain mechanics, walk through the tx state machine step by step, reference specs and lifecycle examples. The developer builds a mental model.
- **Operational mode** (commands: "create", "list", "build", "import", "run"): Use CLI with `--output json`, chain results, prefer `tx run` over manual steps. The agent executes; the developer gets results.
Skills with both paths should use `### When Learning` / `### When Operating` sections. The `/start` skill detects mode from intent and routes accordingly. Mode is not a setting — developers switch freely mid-conversation.

**CLI-first operations**: In operational mode, always use the CLI. The CLI abstracts the Cardano transaction lifecycle, handles auth headers, and provides composable JSON output. Direct API calls are for learning mode — teaching developers what happens under the hood so they can build their own integrations.

**External-only content**: No internal API details. Everything in this plugin should be derivable from public specs, docs, and the CLI.

## Plugin Context

When running as a Claude Code plugin, the `/start` skill initializes `${CLAUDE_PLUGIN_DATA}/knowledge/` from seed data on first run. The `/compound` skill writes to `${CLAUDE_PLUGIN_DATA}/knowledge/`. Clone/symlink users are unaffected — paths default to project-relative.
