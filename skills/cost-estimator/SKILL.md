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

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read specs from `${CLAUDE_PLUGIN_ROOT}/specs/`.
- **Clone/symlink context** (default): Read specs at `specs/` relative to project root.

### Pre-Execution Knowledge Check

1. Read `specs/cost-registry.json` for real execution unit data and fee structures.
2. If knowledge files exist, read `knowledge/cost-scenarios.yaml` for previously calculated scenarios. Proceed without it if missing.

### Cost Components

Every Andamio transaction has up to four cost components:

| Component | Recoverable? | Description |
|-----------|-------------|-------------|
| **Transaction Fee** | No | Network fee to stake pool operators. Varies by script complexity: 0.27–1.30 ADA |
| **Service Fee** | No | Protocol fee to Andamio treasury. Varies by transaction type: 0–120 ADA |
| **Min UTXO Deposits** | Partially | Minimum ADA locked in validator UTxOs. Released when UTxOs are consumed. |
| **Recoverable Deposits** | Yes | ADA locked in state UTxOs. Refunded when credentials are claimed. |

### Transaction Cost Reference

#### Global

| Transaction | Tx Fee | Service Fee | Min UTXO | Notes |
|-------------|--------|-------------|----------|-------|
| Mint Access Token | ~0.36 ADA | 5 ADA | ~3.76 ADA (3 index nodes) | Entry point. ~7.9 ADA total. |

#### Course Operations

| Transaction | Tx Fee | Service Fee | Min UTXO | Notes |
|-------------|--------|-------------|----------|-------|
| Create Course | ~0.55 ADA | 100 ADA + 10 ADA/extra teacher | ~19 ADA | ~130 ADA for 1 teacher |
| Update Teachers | ~0.30 ADA | 10 ADA | 0 | Spend-and-recreate |
| Manage Modules | ~0.27 ADA | 0 (free) | ~1.59 ADA/module | Scales linearly |
| Student Enroll | ~0.40 ADA | 0 | ~1.74 ADA | ~2.14 ADA total |
| Update Assignment | ~0.28 ADA | 0 | ~0.05 ADA | Datum grows |
| Assess Assignment | ~0.28 ADA | 0 | -0.07 ADA refund | Teacher gets small refund |
| Claim Credential | ~0.35 ADA | 0 | -1.38 ADA refund | Student gains ~1.03 ADA |

#### Project Operations

| Transaction | Tx Fee | Service Fee | Min UTXO | Notes |
|-------------|--------|-------------|----------|-------|
| Create Project | ~1.30 ADA | 100 ADA + 10 ADA/extra manager | ~40 ADA + treasury deposit | ~363 ADA with 200 ADA treasury |
| Update Managers | ~0.30 ADA | 10 ADA | 0 | Spend-and-recreate |
| Manage Blacklist | ~0.34 ADA | 0 | 0 | — |
| Create Tasks | ~0.43 ADA | 0 | task reward amount | Reward locked in escrow |
| First Task Commit | ~0.51 ADA | 0 | ~14.5 ADA | State deposit (recoverable) |
| Subsequent Commits | ~0.51 ADA | 0 | 0 | No new deposit |
| Assess Tasks | ~0.35 ADA | 0 | 0 | — |
| Claim Project Credential | ~0.35 ADA | 1 ADA | -14.5 ADA refund | Contributor gains ~13 ADA |
| Add Treasury Funds | ~0.30–0.50 ADA | 0 | deposit amount | — |

### Scenario Calculator

When the developer describes a scenario, calculate the total:

**Example: "Course with 3 teachers and 10 modules, expecting 50 students doing 5 assignments each"**

```
Course Setup (one-time):
  Create course (3 teachers):  100 + 20 + 0.55 + 19    = ~139.55 ADA
  Create 10 modules:           10 × 1.86                = ~18.60 ADA
  Setup subtotal:                                        = ~158.15 ADA

Per Student (50 students × 5 assignments each):
  Enroll (per student):        2.14 × 50                = ~107.00 ADA
  Update (per assignment):     0.33 × 250               = ~82.50 ADA
  Assess (per assignment):     0.21 × 250               = ~52.50 ADA
  Claim (per student):         -1.03 × 50               = ~-51.50 ADA
  Student/teacher subtotal:                              = ~190.50 ADA

TOTAL: ~348.65 ADA
  One-time costs:     ~158.15 ADA (non-recoverable)
  Operational costs:  ~190.50 ADA (partially recoverable via claims)

Cost per student: ~3.81 ADA net (across 5 assignments)
```

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

- Set all initial teachers/managers at creation time (avoids ~10.3 ADA per later update)
- Module management has no service fee — batch or individual is similar cost
- Assignment submission and assessment are free (no service fee)
- Credential claims are net positive — students/contributors get deposits back
- Treasury deposits are fully locked but can fund task rewards

### Guidelines

- Always use the four-component breakdown — developers need to understand where ADA goes
- Distinguish one-time costs from per-user operational costs
- Highlight recoverable deposits — they're not "spent," they're locked
- Show net costs after refunds from credential claims
- Round to 2 decimal places for readability
- When scenarios are ambiguous, ask clarifying questions (number of teachers, expected students, etc.)
