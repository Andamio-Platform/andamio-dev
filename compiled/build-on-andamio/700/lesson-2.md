# Estimate the ADA cost of an Andamio user flow

## Before we start

You've run both lifecycle loops and seen the ADA costs per transaction. This lesson teaches you to estimate costs at the flow level — not "what does one transaction cost?" but "what does it cost to run a course with 30 students?" or "what's the budget for a project with 10 funded tasks?"

Two reference files drive the estimation: `reference/tx-loops.yaml` (named loops with validated fees) and `specs/cost-registry.json` (per-transaction cost data). Both are bundled in the `andamio-dev` plugin.

## The estimation model

Every Andamio user flow decomposes into transaction loops from `tx-loops.yaml`. Each loop has a validated cost. The total cost is the sum of loops, scaled by the number of participants.

```
Total cost = setup cost (one-time) + credential cost × N participants
```

Setup costs are fixed. Credential costs scale linearly per participant.

## Course cost estimation

A course with one module and N students:

| Component | Loop | Cost | Scales with |
|-----------|------|------|-------------|
| Create course (1 teacher) | `course.setup` | ~132 ADA | Fixed |
| Per-student credential | `course.credential` | ~1.32 ADA | × N students |

**Formula:** ~132 + (1.32 × N)

| Students | Setup | Credentials | Total | Per-student |
|----------|-------|-------------|-------|-------------|
| 1 | 132 | 1.32 | ~133 | ~133 |
| 10 | 132 | 13.20 | ~145 | ~14.5 |
| 30 | 132 | 39.60 | ~172 | ~5.7 |
| 100 | 132 | 132.00 | ~264 | ~2.6 |

The per-student cost drops as the cohort grows because setup is amortized. At 100 students, the setup is only ~50% of the total. At 1000 students, it's negligible.

Cost scales linearly per student — each student is an independent credential loop. There's no batch discount on-chain. The `course.credential.cohort` loop in `tx-loops.yaml` confirms this: ~1.32 ADA × N.

**Multi-module courses** multiply the credential cost by the number of modules:

```
Total = setup + modules × module_mint_cost + (credential_cost × N × modules)
```

Each additional module adds ~1.86 ADA in setup (the `modules_manage` mint) and ~1.32 ADA per student for the credential loop.

## Project cost estimation

A project with M funded tasks, a treasury, and N contributors:

| Component | Loop | Cost | Scales with |
|-----------|------|------|-------------|
| Create project (1 manager) | `project.setup` | ~112 ADA + treasury deposit | Fixed |
| Per-task publish | Part of `project.setup` | ~0.43 ADA | × M tasks |
| Per-contributor credential | `project.credential` | ~1.27 ADA (fees only) | × N contributors |
| Contributor deposits | Refundable at claim | ~14.5 ADA | × N (but refunded) |
| Task rewards | From treasury | Reward amount | × M tasks (net transfer, not cost) |

**Formula (non-recoverable costs):** ~112 + (0.43 × M) + (1.27 × N)

The treasury deposit and contributor deposits are recoverable — they're locked, not spent. The actual cost to run a project is the service fees, tx fees, and the 5% commission on task rewards.

**The 5% commission:** When a contributor claims a credential, 5% of the task reward goes to the protocol treasury as a commission. For a 50 ADA task reward, the commission is 2.5 ADA. This is the only ongoing protocol revenue from projects.

## Reading cost-registry.json

The cost registry at `specs/cost-registry.json` has per-transaction cost data. Two sections are useful for estimation:

**`transactionCosts`** — detailed breakdowns per transaction type:

```bash
# Look up a specific transaction's cost
python3 -c "
import json
with open('specs/cost-registry.json') as f:
    reg = json.load(f)
tx = reg['transactionCosts']['course.student.enroll']
print(f'TX fee: {tx[\"txFeeAda\"]}')
print(f'Wallet delta: {tx[\"walletDelta\"][\"ada\"]}')
"
```

**`loops`** — pre-computed loop costs:

```bash
# Look up the course credential loop cost
python3 -c "
import json
with open('specs/cost-registry.json') as f:
    reg = json.load(f)
loop = reg['loops']['course.credential']
print(f'Total loop cost: {loop[\"totalLoopCost\"]}')
print(f'Student net: {loop[\"participants\"][\"student\"][\"netCost\"]}')
print(f'Teacher net: {loop[\"participants\"][\"teacher\"][\"netCost\"]}')
"
```

The `/cost-estimator` Ops Mode skill automates this lookup and handles multi-module, multi-participant scaling.

## Who pays what

Costs are distributed across roles. This matters for budgeting.

**Course:**

| Role | Pays for | One-time or per-credential |
|------|---------|---------------------------|
| Owner | `course_create` (~130 ADA) | One-time |
| Teacher | `modules_manage` (~1.86/module), `assessment_assess` (~0.21/student) | Per-module + per-credential |
| Student | `assignment_submit` (~2.14), `credential_claim` (-1.03) | Per-credential (net ~1.11) |

**Project:**

| Role | Pays for | One-time or per-credential |
|------|---------|---------------------------|
| Owner | `project_create` (~112 ADA + treasury) | One-time |
| Manager | `tasks_manage` (~0.43/task), `task_assess` (~0.35/contributor) | Per-task + per-credential |
| Contributor | `project_join` (~15 ADA deposit), `credential_claim` (net gain) | Per-credential (net positive) |

## A worked example

**Scenario:** A 7-module course with 30 students.

```
Setup:
  course_create (1 teacher):     130.00 ADA
  modules_manage (7 modules):      7 × 1.86 = 13.02 ADA
  Setup total:                   143.02 ADA

Credentials:
  Per student per module:          1.32 ADA
  7 modules × 30 students:        7 × 30 × 1.32 = 277.20 ADA

Total:                           ~420 ADA
Per student (all 7 modules):     ~420 / 30 = ~14.0 ADA
Per credential:                  ~1.32 ADA
```

On preprod this is free test ADA. On mainnet, ~420 ADA at current prices is a real budget item — but it covers 210 on-chain credentials for 30 students.

## Your turn

Estimate the total ADA cost for this scenario:

- A project with 2 managers, a 500 ADA treasury, 5 tasks (each with a 100 ADA reward), and 5 contributors (one per task).
- Assume each contributor is accepted on the first try (no refuse/retry cycles).

Show the setup cost, the per-contributor credential cost, and the total. Then answer: how much of the total is recoverable vs non-recoverable?

## Rubric

**Setup:** `project_create` with 2 managers = ~122 ADA (100 base + 20 managers) + ~45 deposits + 500 treasury = ~667 ADA out of wallet. `tasks_manage` for 5 tasks = ~2.15 ADA. Setup total: ~669 ADA.

**Credentials:** `project.credential` × 5 contributors = 5 × ~1.27 ADA fees = ~6.35 ADA. Contributor deposits: 5 × ~14.5 ADA = ~72.5 ADA (refunded at claim).

**Total out of wallet:** ~748 ADA. **Recoverable:** treasury remainder (~0 if all tasks claimed), contributor deposits (~72.5), and some minUTxO deposits. **Non-recoverable:** ~122 ADA service fees, ~8.5 ADA tx fees, 5% commission on rewards (5 × 5 ADA = 25 ADA). Non-recoverable total: ~156 ADA.

The exact numbers depend on which costs you include in "total" — the important skill is distinguishing one-time setup from per-participant costs, and recoverable deposits from non-recoverable fees.

## What you just did

You can estimate the ADA cost of an Andamio user flow by decomposing it into transaction loops, applying per-participant scaling, and distinguishing fixed setup from per-credential costs. You know where to find the data (`tx-loops.yaml`, `cost-registry.json`) and who pays what.
