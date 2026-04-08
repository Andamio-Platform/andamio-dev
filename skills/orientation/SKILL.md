---
name: orientation
description: Get a developer building on Andamio in 15 minutes. Verifies tooling, explores real data, runs a hands-on operation, and introduces learning vs operational modes.
license: MIT
compatibility: Requires the Andamio CLI (v0.10.1+). Install via brew install andamio-platform/tap/andamio.
metadata:
  author: Andamio
  version: 0.1.0
---

# Andamio Developer Onboarding

Welcome a developer to the Andamio platform. Walk them through the toolchain, verify their setup, explore real data, and run a hands-on operation so they leave ready to build.

**Target time: 15-20 minutes** (core steps 1-7). Step 8 is an optional deep dive.

## Student Learning Targets

By the end of this onboarding, the developer will be able to:

1. **Describe** what Andamio does and what the CLI + plugin combination enables
2. **Verify** their CLI installation and authentication status
3. **Distinguish** between learning mode (understand the protocol) and operational mode (get things done)
4. **Execute** CLI queries to explore real course and project data on preprod
5. **Explain** the transaction state machine pattern and how `tx run` wraps it
6. **Navigate** the available skills to find help for any Andamio task

## Prerequisites

This skill requires the **Andamio CLI** (`andamio`). If missing, install it:

```bash
brew install andamio-platform/tap/andamio
```

An API key is needed for most operations. The skill will check and walk through setup if needed.

## Steps

### 1. Welcome and Context (2 minutes)

Greet the developer and set the stage:

> Welcome to **Andamio Dev** — the developer toolkit for building on the Andamio Protocol.
>
> **What Andamio is:** A protocol for on-chain courses, projects, and credentials on Cardano. Organizations create courses with learning targets, students submit evidence and earn credential NFTs. Projects have treasuries that fund tasks — contributors earn ADA rewards and credential NFTs for completed work. Everything is verifiable on-chain.
>
> **What you're working with:** Three pieces that work together:
> 1. **Andamio CLI** (`andamio`) — the binary that talks to the protocol. Queries data, manages content, builds and submits Cardano transactions.
> 2. **This plugin** (andamio-dev) — skills and reference docs that give your agent deep knowledge of the protocol, API, costs, and troubleshooting.
> 3. **Your agent** (Claude Code or similar) — the harness that reads the skills, runs the CLI, and helps you build.
>
> The combination means you can say "create a course" or "what endpoints handle enrollment?" and get real results — not just documentation, but actual operations against the protocol.

**Comprehension check:** Ask: *"In your own words, what's the difference between the CLI and this plugin?"*

(CLI does things. Plugin knows things. Together with an agent, you can do and understand simultaneously.)

### 2. Prerequisite Check (2 minutes)

Check tooling before going further:

```bash
# Check CLI is installed and which version
andamio --version

# Check authentication state
andamio auth status 2>/dev/null
andamio user status 2>/dev/null

# Check current environment
andamio config show 2>/dev/null
```

**If CLI is installed and auth is configured:** Tell them they're ready. Note whether they have API key only (read-only) or JWT too (read+write).

**If CLI is missing:** Walk through installation:
```bash
brew install andamio-platform/tap/andamio
```

**If no API key:** Walk through setup:
> You'll need an API key for read access. Go to https://preprod.app.andamio.io/api-setup, connect your wallet, register, verify your email, and generate a key. Then:
> ```bash
> andamio auth login --api-key <your-key>
> ```
> For full details, run `/auth-setup`.

**If no JWT (and they'll need write access):** Note it for later:
> You have read-only access. For write operations (creating courses, submitting evidence, transactions), you'll need wallet authentication. We can set that up later with `/auth-setup`.

### 3. Two Modes: Learning and Operating (2 minutes)

Introduce the distinction that shapes how every skill works:

> This plugin works in two modes, and it's important to understand the difference:
>
> **Learning mode** — "How does Andamio work?"
> You want to understand the protocol. Skills show you the API calls behind each operation, explain the on-chain data structures, walk through the transaction state machine step by step. You see how courses store SLTs, how credentials are minted, how the treasury funds task escrow. The API examples and lifecycle scripts are your textbooks.
>
> **Operational mode** — "Create a course for me."
> You want to get things done. The agent runs CLI commands, parses JSON output, chains the results into the next step. `andamio tx run` instead of manual build/sign/submit/register/poll. The CLI is your tool; the agent operates it.
>
> You don't set a mode explicitly — the skills detect it from what you ask. "How do courses work?" triggers learning. "List my courses" triggers operational. You can switch freely mid-conversation.
>
> **The key insight:** Learning mode builds your mental model so that operational mode isn't magic. When something goes wrong in operational mode, you have the understanding to debug it.

**Comprehension check:** Ask: *"If you wanted to understand how enrollment deposits work on-chain, which mode would that be? What about if you wanted to enroll a student right now?"*

(First is learning — show the API call, explain the UTxO. Second is operational — run the CLI command.)

### 4. Skills Tour (2 minutes)

Walk through what's available, organized by purpose:

> Here are the skills available in this plugin. You don't need to memorize them — just know what's available.

**Getting oriented:**

| Skill | What it does | When to use it |
|-------|-------------|----------------|
| `/orientation` | This walkthrough | First time, or anytime you need a refresher |
| `/start` | Detect what you need and route to the right skill | When you're not sure where to begin |
| `/auth-setup` | Walk through API key + wallet JWT configuration | Setting up credentials for the first time |

**Understanding the protocol (learning mode):**

| Skill | What it does | When to use it |
|-------|-------------|----------------|
| `/explore-api` | Search Gateway API endpoints by natural language | "What endpoints handle X?" |
| `/cost-estimator` | Calculate ADA costs for any operation | Before committing real ADA |
| `/course-ops` | Course lifecycle — create, modules, content, publish | Understanding how courses work end-to-end |
| `/project-ops` | Project lifecycle — treasury, tasks, contributors | Understanding how projects work end-to-end |

**Getting things done (operational mode):**

| Skill | What it does | When to use it |
|-------|-------------|----------------|
| `/cli-guide` | Exact CLI commands with flags and exit codes | "How do I do X with the CLI?" |
| `/troubleshoot` | Debug API errors, CLI failures, tx rejections | Something broke |

**After work:**

| Skill | What it does | When to use it |
|-------|-------------|----------------|
| `/compound` | Extract patterns from this session into knowledge files | End of a productive session |

### 5. Hands-On: Explore Real Data (3 minutes)

> Let's see the CLI in action. We'll explore what's actually on preprod right now.

Run these commands and walk through the output:

```bash
# List courses on preprod
andamio course list --output json | jq '.data[] | {id: .course_id, title: .content.title}'
```

Pick a course from the output and drill in:

```bash
# List modules for that course
andamio course modules "<course-id>" --output json | jq '.data[] | {code: .content.course_module_code, title: .content.title, status: .content.module_status}'

# List SLTs in a module
andamio course slts "<course-id>" <module-code> --output json | jq '.data[] | {index: .slt_index, text: .slt_text}'
```

Point out:
- `--output json` makes everything composable — pipe to `jq`, use in scripts, feed to other commands
- Course IDs are 56-char hex strings (Cardano policy IDs)
- Module codes are simple numbers (100, 200, 300)
- SLT indices are integers that map to lessons

If projects exist:

```bash
# List projects
andamio project list --output json | jq '.data[] | {id: .project_id, title: .content.title}'
```

**Comprehension check:** Ask: *"What would you pipe the course list command into to get just the course IDs?"*

(Answer: `jq -r '.data[].course_id'` — the two-step discovery pattern.)

### 6. The Transaction State Machine (3 minutes)

> Andamio is built on Cardano, which means write operations are blockchain transactions. Here's the pattern — every on-chain operation follows the same five steps:

```
build → sign → submit → register → wait(updated)
```

> 1. **Build** — API returns an unsigned transaction (CBOR hex)
> 2. **Sign** — Your .skey file signs the transaction locally
> 3. **Submit** — Signed transaction goes to the Cardano network
> 4. **Register** — Tell Andamio to track this transaction
> 5. **Wait** — Poll until status is "updated" (on-chain confirmed AND database synced)
>
> The `andamio tx run` command wraps all five steps into one:

```bash
andamio tx run /v2/tx/course/teacher/assignments/assess \
  --body-file payload.json \
  --skey payment.skey \
  --tx-type assessment_assess \
  --instance-id "$COURSE_ID"
```

> In learning mode, we show the five steps so you understand what's happening. In operational mode, we use `tx run` because it handles retries, polling, and error reporting.
>
> The lifecycle scripts in `examples/` walk through full course and project lifecycles step by step — excellent for understanding, but in practice you'd use `tx run`.

Show the available transaction types:

```bash
andamio tx types --output json
```

**Comprehension check:** Ask: *"What's the difference between 'confirmed' and 'updated' status for a transaction?"*

(Confirmed = on-chain but database hasn't synced yet. Updated = on-chain AND database is current. Always wait for "updated" before querying for new data.)

### 7. Wrap-Up and First Steps (2 minutes)

> **You're set up.** Here's your quick reference:

**Key resources:**
- CLI reference: `reference/andamio-cli-context.md` in this plugin
- Gateway API spec: `specs/andamio-api.yaml` (111 endpoints)
- TX loops reference: `reference/tx-loops.yaml` (canonical transaction workflows)
- Cost data: `specs/cost-registry.json`
- Lifecycle examples: `examples/course-lifecycle.sh` and `examples/project-lifecycle.sh`

**Your workflow:**
1. Not sure where to start → `/start`
2. Need exact CLI syntax → `/cli-guide`
3. Want to understand how something works → `/explore-api` or `/course-ops` / `/project-ops`
4. Need to estimate costs → `/cost-estimator`
5. Something broke → `/troubleshoot`
6. End of session → `/compound` to capture what you learned

> The combination of the CLI and this plugin means your agent can both explain and execute. Ask it to show you how enrollment works (learning), then ask it to enroll you (operational). Same session, seamless transition.

**Questions?** Ask the developer if anything was unclear or if they want to explore a specific area.

**First assignment:** Run `/cli-guide` and ask it how to list your courses. Then try `/explore-api` and ask it what endpoints handle student enrollment. Compare the two experiences — one gives you commands to run, the other shows you the API layer underneath.

### 8. Hands-On: Try an Operation (optional extension, 5 minutes)

Ask:

> Want to try a real operation? Here are a few options depending on your access level:
>
> **Read-only (API key):**
> - Export a course module to local Markdown files
> - Discover API endpoints for a specific feature
> - Estimate the cost of creating a course
>
> **Read+Write (JWT):**
> - Create a draft task on a project
> - Submit evidence for an assignment
> - Import content from local Markdown into a course module
>
> Pick one and we'll walk through it together.

If they choose an operation, run it using CLI commands. After it completes, point out:
- How the CLI handled authentication automatically
- How `--output json` made the result composable
- How this same operation would look as raw API calls (learning mode view)

If they skip, that's fine — they have everything they need to start building.

## SLT Verification Checklist

| SLT | Verified By |
|-----|------------|
| 1. Describe CLI + plugin combination | Step 1 check: "Difference between CLI and plugin?" |
| 2. Verify installation and auth | Step 2: Ran status commands |
| 3. Distinguish learning vs operational | Step 3 check: "Which mode for enrollment deposits?" |
| 4. Execute CLI queries | Step 5: Explored real data hands-on |
| 5. Explain tx state machine | Step 6 check: "Difference between confirmed and updated?" |
| 6. Navigate available skills | Step 7: First assignment bridges to real usage |

## Important Notes

- Keep this onboarding conversational and encouraging — this is someone's first experience with the platform
- Don't rush through steps; pause after each comprehension check
- If setup takes longer than expected, that's OK — getting auth right is more valuable than speed
- The hands-on exercises are the most important part — reading about the CLI is less effective than using it
- If the learner can't answer a comprehension check, loop back and re-explain before moving on
- Adapt to the developer's experience level — a Cardano developer needs less blockchain context, a web developer needs less CLI context
- Update this skill when new skills are added to the plugin or when the CLI surface changes significantly
