# AGENTS.md

Project context for AI agents working in this repository. Read this file to understand the project, conventions, and workflow.

## Project Overview

**andamio-dev** is an Agent Skills package originally built as a Claude Code plugin. It serves two purposes: (1) delivering the "Build on Andamio" course via AI agent skills, and (2) providing operational skills for day-to-day Andamio development. The primary artifacts are course content (`courses/`), portable agent skill definitions (`skills/`), compatibility harnesses (`.agents/`, `.claude/`), bundled API specifications (`specs/`), CLI reference documentation (`reference/`), and a compounding knowledge base (`knowledge/`).

This is **not a code project**. There is no build step, no test suite, no linter.

## Directory Structure

```
skills/                   # Portable agent skills (Agent Skills standard, 14 skills)
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
  contribute/             # Public contribution front door — see/file public-repo work
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
  andamio-api.yaml        # Andamio Gateway API — the PUBLIC contract (Swagger 2.0, 79 paths).
                          # Synced from the generated public artifact in andamio-api; the header
                          # records the source commit and sync date. Administrative and internal
                          # operations are not in it, by design. Do not hand-edit.
  cost-registry.json      # Transaction cost data (fees, min UTXO, execution units)
reference/                # Bundled reference documentation
  andamio-cli-context.md  # CLI agent context (commands, auth, composability)
  tx-loops.yaml           # Canonical transaction workflows (source of truth for tx flows)
  api-endpoints-by-use-case.md  # GENERATED from specs/andamio-api.yaml — do not hand-edit
  cli-retirements.yaml    # CLI command paths retired per release (data for check-cli-refs.py)
  public-repos.yaml       # Curated registry of public repos for the /contribute front door
  acceptance-test-prerequisites.md
scripts/                  # Maintenance checks. Both are safe to run any time.
  gen-endpoint-index.py   # Regenerates reference/api-endpoints-by-use-case.md from the contract.
                          # `--check` exits 1 when it is out of date.
  check-cli-refs.py       # Reports references to CLI commands a release retires.
                          # `--check` exits 1 once that release is marked `released`.
knowledge/                # Compound knowledge base (YAML files)
  index.yaml              # Master index and aggregate stats
  gotchas.yaml            # Known errors with root causes and fixes
  faq.yaml                # Frequently asked questions from developer sessions
  endpoint-usage.yaml     # Endpoint usage patterns and context
  cost-scenarios.yaml     # Real-world cost calculations
compiled/                 # Gitignored. Build output of `coach:compile` for `andamio course import-all`. Never edit.
progress.json             # Gitignored. Per-learner state written by the /learn skill.
docs/solutions/           # Documented solutions to past problems (bugs, conventions, patterns), by category with YAML frontmatter (module, tags, problem_type). Relevant when implementing or debugging in documented areas.
CONCEPTS.md               # Shared domain vocabulary (entities, named processes, status concepts) — relevant when orienting to the codebase or discussing domain concepts.
```

## Bundled Assets

### Andamio API (`specs/andamio-api.yaml`)

The public-facing Andamio API. 79 paths across these groups (the public contract only — administrative and internal operations are excluded by design):

| Group | Operations | Auth | Purpose |
|-------|-----------|------|---------|
| Courses | 28 | API key (+ JWT for role-scoped) | Course discovery, modules, teachers, learner commitments, assessment |
| Transactions | 22 | API key | Build, register, and track Cardano transactions |
| Projects | 21 | API key (+ JWT for role-scoped) | Project CRUD, tasks, contributors, treasury |
| Platform Auth | 3 | varies | Wallet login, session management, user profile |
| Keys | 3 | JWT | Developer API key CRUD |
| Verify | 2 | API key | Credential and task-commitment verification |
| Public | 1 | API key | Public read |

**80 operations across 79 paths.** Counts and Auth values derive from the contract's own tag groups and per-operation `security` blocks — regenerate `reference/api-endpoints-by-use-case.md` to see the current breakdown per group and the auth requirement per endpoint.

The role-scoped path prefixes that require **both** `X-API-Key` and `Authorization: Bearer` in the same request are `/v2/course/owner`, `/v2/course/student`, `/v2/course/teacher`, `/v2/project/contributor`, `/v2/project/manager`, `/v2/project/owner`, and `/v2/user/dashboard`. `/v2/keys` requires the JWT only. Everything else takes the API key alone.

**Endpoint filtering is no longer something skills must do.** Developer-portal concerns (registration, API-key lifecycle, billing) and administrative operations are not in this spec at all — they were removed when the vendored copy was replaced with the generated public contract on 2026-07-28. If an operation is absent, treat that as the contract rather than as a gap in the file — but absence is not proof that a route is dead.

**Live but not in the contract.** A few routes work in production yet do not appear in `specs/andamio-api.yaml`. Annotate them where they are used rather than assuming they were removed:

| Route | Why it is absent | Where it is used here |
|-------|------------------|-----------------------|
| `GET /.well-known/jwks.json` | Served at the gateway service root, outside the spec's `basePath: /api` | `courses/build-on-andamio/lessons/m200/assignment.md`, lesson 200.4 |
| `POST /v2/course/student/commitment/create` | Duplicates the in-contract builder `POST /v2/tx/course/student/assignment/commit`; which becomes canonical is an open decision | `skills/course-ops/SKILL.md`, `skills/explore-api/SKILL.md` |

If you find another route that is live but absent, verify it against the spec before adding it to this table.

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
