# andamio-dev

Learn to build on the Andamio Protocol. A seven-module course with interactive lessons, hands-on exercises, and on-chain credential assessment — delivered by AI agent skills.

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

### npm

```bash
npm install @andamio/dev
```

### Clone

```bash
git clone https://github.com/Andamio-Platform/andamio-dev.git
cd andamio-dev
```

## Take the Course

Start the "Build on Andamio" course:

```
/learn
```

The course walks you through 7 modules, from first concepts to shipping a working integration. An instructor agent delivers each lesson, guides you through exercises, and runs CLI commands alongside you. When you finish a module, an assessor agent evaluates your assignment — pass and the next module unlocks.

### What You'll Learn

| Module | Name | What you'll be able to do |
|--------|------|---------------------------|
| 100 | Foundations | Explain Andamio's learning model, install the CLI, fund a wallet |
| 200 | Identity | Mint an access token, authenticate with API keys and JWTs |
| 300 | Reading Andamio | Query the gateway API, navigate the OpenAPI spec |
| 400 | TX State Machine | Execute transactions, diagnose failures, handle edge cases |
| 500 | Courses End-to-End | Create and run a full course lifecycle on-chain |
| 600 | Projects End-to-End | Create and run a full project lifecycle with treasury |
| 700 | Build Something Real | Ship a working Andamio integration |

31 learning targets across 7 modules. Modules 100–400 are available now. Modules 500–700 are in development.

### How It Works

1. Each module has 4–5 lessons with hands-on exercises
2. Lessons alternate between Learning Mode (understanding concepts) and Operational Mode (running commands)
3. Every module ends with an assignment — submit evidence for each learning target
4. An assessor evaluates your work and either accepts or asks for revision
5. Your progress is tracked locally; optionally submit evidence on-chain for a credential NFT

### Prerequisites

- A terminal with an AI coding agent (Claude Code, Cursor, or similar)
- The [Andamio CLI](https://github.com/Andamio-Platform/andamio-cli) (installed in Module 100, Lesson 2)
- Free test ADA from the Cardano preprod faucet (covered in Module 100, Lesson 3)

No Cardano experience required. No real money needed — everything runs on preprod testnet.

## Reference Skills

Outside the course, the plugin provides operational skills for day-to-day development:

| Skill | Command | What it does |
|-------|---------|-------------|
| **Start** | `/start` | Entry point. Detects intent, routes to the right skill. |
| **Explore API** | `/explore-api` | Search Gateway and Andamioscan endpoints by natural language. |
| **CLI Guide** | `/cli-guide` | Get exact CLI commands for any operation. |
| **Auth Setup** | `/auth-setup` | Walk through API key, wallet JWT, and environment config. |
| **Cost Estimator** | `/cost-estimator` | Calculate ADA costs for courses, projects, and user scenarios. |
| **Course Ops** | `/course-ops` | Course lifecycle: create, modules, teachers, content import. |
| **Project Ops** | `/project-ops` | Project lifecycle: create, tasks, contributors, treasury. |
| **Troubleshoot** | `/troubleshoot` | Debug API errors, CLI failures, and transaction rejections. |
| **Compound** | `/compound` | Extract patterns from sessions to improve future guidance. |

These skills complement the course. As you complete each module, the relevant operational skills become contextually useful — you understand what they do because you learned the concepts first.

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

## What's Bundled

- **Gateway API spec** — 111 endpoints for courses, projects, transactions, auth
- **Andamioscan spec** — 34 read-only endpoints for on-chain verification
- **Cost registry** — Real transaction cost data (fees, min UTXO, execution units)
- **CLI reference** — Complete command reference with agent workflow examples

## Environments

| Environment | API URL | Network |
|-------------|---------|---------|
| Preprod (default) | preprod.api.andamio.io | Cardano testnet (free test ADA) |
| Mainnet | mainnet.api.andamio.io | Cardano mainnet (real ADA) |

Always start on preprod.

## Compatibility

Works with any agent that supports the [Agent Skills](https://agent-skills.cc) standard:

- Claude Code
- Cursor
- GitHub Copilot
- Gemini CLI
- OpenAI Codex
- Goose
- Roo Code

## License

MIT
