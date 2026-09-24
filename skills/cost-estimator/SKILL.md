---
name: cost-estimator
description: Calculate ADA costs for Andamio operations. Estimate total cost for courses, projects, and user scenarios with four-component breakdowns.
license: MIT
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Cost Estimator

## Description

Calculates ADA costs for different Andamio scenarios. Accepts natural-language descriptions like "course with 3 teachers and 10 modules" and returns a four-component breakdown: transaction fees, service fees, min UTXO deposits, and recoverable deposits.

## Instructions

### Path Resolution

Bundled paths in this skill (`specs/`, `reference/`, `knowledge/`) are relative to the **package root**: the directory two levels above this `SKILL.md`, after resolving symlinks — the one that contains `specs/andamio-api.yaml`. Resolve them from there, never from the current working directory, which is the developer's own project and does not contain these files. From this file, `specs/cost-registry.json` is `../../specs/cost-registry.json`.

Knowledge files are developer data. Read them from the state directory first — `${CLAUDE_PLUGIN_DATA}/knowledge/` when `${CLAUDE_PLUGIN_DATA}` is set, otherwise `knowledge/` in the current working directory — and fall back to the package's seed `knowledge/`.

### Pre-Execution Knowledge Check

1. Read `specs/cost-registry.json` for real execution unit data and fee structures.
2. Read `reference/tx-loops.yaml` for canonical loop definitions, dotted names, and validated fees.
3. If knowledge files exist, read `knowledge/cost-scenarios.yaml` for previously calculated scenarios. Proceed without it if missing.

### Transaction Loops

Andamio operations are organized into named **transaction loops** — multi-step workflows that accomplish a complete outcome. Reference loops by their dotted name (e.g., `course.credential`, `project.setup`).

**Validated loops** (tested against live stack, real fee data):

| Loop | Dotted Name | Total Cost | Notes |
|------|-------------|------------|-------|
| Course Setup | `course.setup` | ~119.3 ADA + ~1.86 ADA/module | course_create (~119.3, incl. 100 ADA service fee) + modules_manage |
| Project Setup | `project.setup` | ~148 ADA + treasury deposit | project_create (~148, incl. 100 ADA service fee) + treasury_fund + tasks_manage |
| Course Credential | `course.credential` | ~1.27 ADA | Per student: enroll → assess → claim |
| Project Credential | `project.credential` | ~1.24 ADA + max(1 ADA, commission × reward) | Contributor net positive (deposit refund + reward minus commission) |
| Access Token | `general.access-token` | ~2.87 ADA | Prerequisite for course/project creation (no service fee in v3) |

**Stubbed loops** (defined, not yet tested): `project.credential.native-assets`, `course.credential.sequential`, `course.credential.refused`, `project.credential.refused`, `project.credential.denied`, `project.tasks.replace`, `course.modules.ongoing`, `course.teachers.rotate`, `course.credential.cohort`, `project.treasury.drawdown`, `general.auth.headless`

When estimating costs, compose from loops:
- "Stand up a course and credential 50 students" = `general.access-token` + `course.setup` + 50 × `course.credential`
- "Full project with 10 contributors" = `general.access-token` + `course.setup` + `project.setup` + 10 × (`course.credential` + `project.credential`)

See `reference/tx-loops.yaml` for full step sequences, roles, prerequisites, and known gotchas.

### Cost Components

Every Andamio transaction has up to four cost components:

| Component | Recoverable? | Description |
|-----------|-------------|-------------|
| **Transaction Fee** | No | Network fee to stake pool operators. Varies by script complexity: 0.27–1.30 ADA |
| **Service Fee** | No | Protocol fee to Andamio's serviceFeeRecipient: 100 ADA to create a course or project, 10 ADA per teacher or manager added, and `max(1 ADA, commission_rate × reward)` at project credential claim. Every other transaction: none. |
| **Min UTXO Deposits** | Partially | Minimum ADA locked in validator UTxOs. Released when UTxOs are consumed. |
| **Recoverable Deposits** | Yes | ADA locked in state UTxOs. Refunded when credentials are claimed. |

### Transaction Cost Reference

> **Service fees are measured on preprod** (2026-09-23, gateway API 2.5.2) and paid to a single `serviceFeeRecipient`. Each figure in `specs/cost-registry.json` carries the transaction it was read from. Mainnet may differ.

#### Global

| Transaction | Tx Fee | Service Fee | Min UTXO | Notes |
|-------------|--------|-------------|----------|-------|
| Mint Access Token | ~0.36 ADA | 0 ADA | ~3.76 ADA (3 index nodes) | Entry point. ~2.87 ADA total. |

#### Course Operations

| Transaction | Tx Fee | Service Fee | Min UTXO | Notes |
|-------------|--------|-------------|----------|-------|
| Create Course | ~0.56 ADA | 100 ADA | ~18.8 ADA | ~119.3 ADA total, measured with one initial teacher |
| Update Teachers | ~0.30 ADA | 10 ADA per teacher added; 0 to remove | 0 | Spend-and-recreate. ~10.33 ADA to add one teacher |
| Manage Modules | ~0.27 ADA | 0 (free) | ~1.59 ADA/module | Scales linearly |
| Student Enroll | ~0.37 ADA | 0 | ~2.27 ADA | ~2.64 ADA total |
| Update Assignment | ~0.28 ADA | 0 | ~0.05 ADA | Datum grows |
| Assess Assignment | ~0.27 ADA | 0 | 0 | Tx fee only |
| Claim Credential | ~0.35 ADA | 0 | ~-2.0 ADA refund | Student gains ~1.65 ADA |

#### Project Operations

| Transaction | Tx Fee | Service Fee | Min UTXO | Notes |
|-------------|--------|-------------|----------|-------|
| Create Project | ~1.30 ADA | 100 ADA | ~44.6 ADA (incl. 5 ADA treasury reserve) + 2 ADA stake registration | ~148 ADA total, measured with one initial manager; treasury funded separately |
| Update Managers | ~0.30 ADA | 10 ADA per manager added; 0 to remove | 0 | Spend-and-recreate. ~10.35 ADA to add one manager |
| Manage Blacklist | ~0.34 ADA | 0 | 0 | — |
| Create Tasks | ~0.32 ADA | 0 | task reward amount | Reward paid from the manager's wallet into the treasury and locked for the task |
| First Task Commit | ~0.54 ADA | 0 | ~2.3 ADA | Locked in contributor state (recoverable); ~2.82 ADA total |
| Subsequent Commits | ~0.51 ADA | 0 | 0 | No new deposit |
| Assess Tasks | ~0.35 ADA | 0 | 0 | — |
| Claim Project Credential | ~0.36 ADA | max(1 ADA, commission × reward) | ~-2.0 ADA refund | Default commission 5%; tiered (5/3/2/1%) per project. See `commissionTiers` in cost-registry. |
| Add Treasury Funds | ~0.30–0.50 ADA | 0 | deposit amount | — |

### Scenario Calculator

When the developer describes a scenario, calculate the total:

**Example: "Course with 3 teachers and 10 modules, expecting 50 students doing 5 assignments each"**

```
Course Setup (one-time):
  Create course, all 3 teachers named at create:
                                  100 + 0.56 + 18.8     = ~119.36 ADA
  Create 10 modules:              10 × 1.86             = ~18.60 ADA
  Setup subtotal:                                       = ~137.96 ADA

Per Student (50 students × 5 assignments each):
  Enroll (per student):           2.64 × 50             = ~132.00 ADA
  Update (per assignment):        0.33 × 250            = ~82.50 ADA
  Assess (per assignment):        0.27 × 250            = ~67.50 ADA
  Claim (per student):           -1.65 × 50             = ~-82.50 ADA
  Student/teacher subtotal:                             = ~199.50 ADA

TOTAL: ~337.46 ADA
  One-time costs:     ~137.96 ADA (non-recoverable)
  Operational costs:  ~199.50 ADA (partially recoverable via claims)

Cost per student: ~3.99 ADA net (across 5 assignments)
```

> course_create was measured with one initial teacher. Whether naming more teachers at creation raises its fee has not been measured; say so when a scenario depends on it. Teachers added *after* creation pay 10 ADA each (~10.33 ADA with the tx fee).

### Output Format

Always present results with:

1. **Summary line**: "Estimated total: X ADA"
2. **Breakdown by phase**: Setup (one-time) vs. Operational (per-user)
3. **Component table**: Tx fees, service fees, deposits, refunds
4. **Per-user cost**: Net cost per student/contributor
5. **Recoverable amount**: Total ADA that returns via credential claims

### Caveats

Always include:

> Costs are based on the bundled cost registry and may vary slightly with Cardano protocol parameter updates. Transaction fees depend on network conditions and script execution complexity. Last updated: [read date from cost-registry.json].

> On preprod, these costs apply but test ADA is free from the Cardano faucet at https://docs.cardano.org/cardano-testnets/tools/faucet/

### Cost Optimization Tips

Offer when relevant:

- Creation is the largest one-time cost: a 100 ADA service fee plus ~19 ADA (course) or ~47 ADA (project) in deposits and fees
- Name every teacher or manager in the create transaction — each one added later costs ~10.3 ADA (10 ADA service fee + tx fee). Removing one costs only the tx fee (~0.25 ADA)
- Module management has no service fee — batch or individual is similar cost
- Assignment submission and assessment are free (no service fee)
- Credential claims are net positive — students/contributors get deposits back
- Project rewards: commission rate (default 5%) is taken at claim. Upgrade tier via power-up to lower it.
- Treasury deposits are fully locked but can fund task rewards

### Guidelines

- Always use the four-component breakdown — developers need to understand where ADA goes
- Distinguish one-time costs from per-user operational costs
- Highlight recoverable deposits — they're not "spent," they're locked
- Show net costs after refunds from credential claims
- Round to 2 decimal places for readability
- When scenarios are ambiguous, ask clarifying questions (number of teachers, expected students, etc.)
