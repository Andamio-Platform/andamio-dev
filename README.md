# andamio-dev

A Claude Code plugin that serves two purposes:

- **Take the "Build on Andamio" course** — a seven-module curriculum with interactive lessons, hands-on exercises, and on-chain credential assessment, delivered by AI agent skills.
- **Use Andamio from your terminal** — ten operational skills for day-to-day development: API exploration, CLI guidance, cost estimation, course/project operations, and more.

Use one or both. The course teaches the concepts you'll use the ops skills for; the ops skills remain useful long after you finish the course.

## Install

### Claude Code Plugin (recommended)

Add to your `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "andamio-dev@andamio": true
  },
  "extraKnownMarketplaces": {
    "andamio": {
      "source": {
        "source": "github",
        "repo": "Andamio-Platform/andamio-marketplace"
      }
    }
  }
}
```

### Clone

```bash
git clone https://github.com/Andamio-Platform/andamio-dev.git
cd andamio-dev
```

## Three ways to start

| Command | Use when |
|---------|----------|
| `/start` | You're not sure where to begin. Detects intent and routes you to the right skill. |
| `/orientation` | First time here — take a 15-minute guided tour of the plugin with hands-on exercises. |
| `/learn` | You want the full curriculum. Starts the "Build on Andamio" course. |

## For developers — operational skills

Ten skills for day-to-day Andamio development. Works standalone without the course.

| Skill | Command | What it does |
|-------|---------|-------------|
| **Orientation** | `/orientation` | First-run walkthrough — 15-minute guided tour with hands-on exercises. |
| **Start** | `/start` | Entry point. Detects intent, routes to the right skill. |
| **Explore API** | `/explore-api` | Search Gateway API endpoints by natural language. |
| **CLI Guide** | `/cli-guide` | Get exact CLI commands for any operation. |
| **Auth Setup** | `/auth-setup` | Walk through API key, wallet JWT, and environment config. |
| **Cost Estimator** | `/cost-estimator` | Calculate ADA costs for courses, projects, and user scenarios. |
| **Course Ops** | `/course-ops` | Course lifecycle: create, modules, teachers, content import. |
| **Project Ops** | `/project-ops` | Project lifecycle: create, tasks, contributors, treasury. |
| **Troubleshoot** | `/troubleshoot` | Debug API errors, CLI failures, and transaction rejections. |
| **Compound** | `/compound` | Extract patterns from sessions to improve future guidance. |

## For learners — the course

Run `/learn` to start. An instructor agent delivers each lesson, guides you through exercises, and runs CLI commands alongside you. When you finish a module, an assessor agent evaluates your assignment — pass and the next module unlocks.

### What you'll learn

| Module | Name | What you'll be able to do |
|--------|------|---------------------------|
| 100 | Foundations | Explain Andamio's learning model, install the CLI, fund a wallet |
| 200 | Identity | Mint an access token, authenticate with API keys and JWTs |
| 300 | Reading Andamio | Query the gateway API, navigate the OpenAPI spec |
| 400 | TX State Machine | Execute transactions, diagnose failures, handle edge cases |
| 500 | Courses End-to-End | Create and run a full course lifecycle on-chain |
| 600 | Projects End-to-End | Create and run a full project lifecycle with treasury |
| 700 | Build Something Real | Ship a working Andamio integration |

31 learning targets across 7 modules, all drafted. You can also read the lessons directly in `courses/build-on-andamio/lessons/m{N}/` without running the course.

### How it works

1. Each module has 4–5 lessons with hands-on exercises
2. Lessons alternate between Learning Mode (understanding concepts) and Operational Mode (running commands)
3. Every module ends with an assignment — submit evidence for each learning target
4. An assessor evaluates your work and either accepts or asks for revision
5. Your progress is tracked locally; optionally submit evidence on-chain for a credential NFT

## Prerequisites

Required for everything (course and ops skills):

- A terminal with an AI coding agent (Claude Code, Cursor, or similar)
- The [Andamio CLI](https://github.com/Andamio-Platform/andamio-cli)
- Free test ADA from the Cardano preprod faucet

New to Cardano? Start with `/orientation` or `/learn` — both walk you through CLI install and faucet funding. No real money needed; everything runs on preprod testnet.

## Examples

Runnable bash scripts that demonstrate the full transaction state machine loop:

```bash
# Course lifecycle: create → module → enroll → submit → assess → claim credential
export SKEY_PATH=/path/to/payment.skey
./examples/course-lifecycle.sh

# Project lifecycle: create → task → commit → assess → claim credential
export SKEY_PATH=/path/to/payment.skey
export TREASURY_ADA=200
export TASK_REWARD_ADA=50
./examples/project-lifecycle.sh
```

Each transaction follows the same 5-step pattern: build → sign → submit → register → wait(updated).

## What's bundled

- **Course content** (`courses/`) — "Build on Andamio" curriculum source: 31 SLTs across 7 modules, lessons, assignments, SLT quality review, and drafting guidelines
- **Course delivery harness** (`.claude/`) — the `/learn` orchestrator plus instructor and assessor agents
- **Gateway API spec** — 111 endpoints for courses, projects, transactions, auth (single entry point — backends are not called directly)
- **TX loops reference** (`reference/tx-loops.yaml`) — canonical transaction workflows with complete CLI commands, body examples, and gotchas
- **Cost registry** — real transaction cost data (fees, min UTXO, execution units)
- **CLI reference** (`reference/andamio-cli-context.md`) — complete command reference with agent workflow examples
- **Acceptance test prerequisites** (`reference/acceptance-test-prerequisites.md`) — wallet setup, environment config, and verification checklist
- **Runnable examples** (`examples/`) — full tx state machine scripts for course and project lifecycles

## Environments

| Environment | API URL | Network |
|-------------|---------|---------|
| Preprod (default) | preprod.api.andamio.io | Cardano testnet (free test ADA) |
| Mainnet | mainnet.api.andamio.io | Cardano mainnet (real ADA) |

Always start on preprod.

## Compatibility

Built to the [Agent Skills](https://agent-skills.cc) open standard. Developed and tested on Claude Code; may work with any Agent Skills-compliant agent (Cursor, Gemini CLI, OpenAI Codex, Goose, Roo Code, etc.). Report issues with specific agents and we'll expand support.

## Further reading

- **[AGENTS.md](AGENTS.md)** — full project context for AI agents: architecture, auth model, conventions, directory structure
- **[CLAUDE.md](CLAUDE.md)** — guidance for Claude Code sessions in this repo
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — how to contribute skills, knowledge entries, and spec updates
- **[CHANGELOG.md](CHANGELOG.md)** — release notes

## License

MIT
