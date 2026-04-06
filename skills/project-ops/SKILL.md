---
name: project-ops
description: Project lifecycle guidance — create projects, manage tasks, handle contributors, fund treasury, and issue credentials. CLI-first with API alternatives.
license: MIT
compatibility: Requires the Andamio CLI for most operations. Install via brew install andamio-platform/tap/andamio.
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Project Ops

## Description

Guides developers through the complete project lifecycle on Andamio. Projects are Cardano-native task management systems with on-chain treasury, escrow-based task rewards, and verifiable credentials for completed work.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read specs from `${CLAUDE_PLUGIN_ROOT}/specs/`, reference from `${CLAUDE_PLUGIN_ROOT}/reference/`.
- **Clone/symlink context** (default): Read from `specs/` and `reference/` relative to project root.

### Pre-Execution Check

1. Read `specs/andamio-api.yaml` for project endpoint details.
2. Read `reference/andamio-cli-context.md` for CLI command reference.
3. Check authentication:

```bash
andamio user status 2>/dev/null
```

If no JWT is detected, redirect to `/auth-setup`.

### Project Lifecycle

#### 1. Create Project

The most complex Andamio transaction. Creates 6 validator UTxOs, a stake account, and mints 6 tokens.

**Cost**: ~143 ADA base (1 manager) + treasury deposit. See /cost-estimator for precise breakdown.

**Via CLI:**
```bash
# Discover your alias
andamio user me --output json | jq -r '.alias'

# Build the transaction
andamio tx build /v2/tx/instance/owner/project/create \
  --body '{
    "alias": "my-alias",
    "managers": ["manager1", "manager2"],
    "treasury_deposit": 200000000
  }' \
  --output json
```

**Treasury deposit**: ADA locked in the on-chain treasury. This funds task rewards. The `treasury_deposit` field is in lovelace (1 ADA = 1,000,000 lovelace).

**Planning tip:** Set all initial managers at creation — adding managers later costs ~10.3 ADA each.

#### 2. Create Tasks

Tasks lock reward amounts in escrow until assessed.

**Via CLI:**
```bash
# Create a task with title and reward
andamio project task create <project-id> \
  --title "Build API integration" \
  --lovelace 50000000 \
  --expiration 2026-06-01

# Create with rich content from Markdown file
andamio project task create <project-id> \
  --title "Design review" \
  --lovelace 25000000 \
  --expiration 2026-07-01 \
  --content-file task-description.md
```

**Cost**: Task reward + ~0.43 ADA tx fee. The reward is locked in escrow until the task is assessed.

**Via API:**
```
POST /v2/tx/project/manager/tasks/manage
Auth: API Key + JWT
Body: {
  alias,
  project_id,
  contributor_state_id,
  tasks_to_add: [
    { project_content, expiration_posix, lovelace_amount, native_assets: [] }
  ],
  tasks_to_remove: [],
  deposit_value: [["lovelace", <total_reward_lovelace>]]
}
```
All three of `tasks_to_add`, `tasks_to_remove`, and `deposit_value` are required even when empty/zero. `contributor_state_id` identifies the manager's on-chain contributor state UTxO (managers hold a contributor state the same way contributors do).

**Bulk task management:**
```bash
# Export tasks to Markdown files
andamio project task export <project-id>

# Edit tasks locally, then import
andamio project task import <project-id> --dry-run  # Preview changes
andamio project task import <project-id>             # Apply changes
```

#### 3. Contributor Flow

Contributors join projects, commit to tasks, submit work, and claim credentials:

1. **Commit to task** (~15 ADA first time, ~0.51 ADA after):
   ```
   POST /v2/tx/project/contributor/task/commit
   Body: { alias, project_id, contributor_state_id, task_hash, task_info }
   ```
   First commit mints a contributor-state token (~14.5 ADA deposit, recoverable). The `task_hash` is the 64-char Blake2b-256 of the on-chain task datum; discover it via `andamio project list-tasks <project-id>` or andamioscan. `task_info` is free-form text, max 140 chars.

2. **Submit work** (on-chain evidence update, ~0.3 ADA):
   ```
   POST /v2/tx/project/contributor/task/action
   Body: { alias, project_id, project_info }
   ```
   This endpoint is **dual-purpose**: with `project_info` it updates evidence on-chain; **without** `project_info` it triggers a leave-project action. Presence of the field determines the action.

3. **Manager assesses** (~0.35 ADA):
   ```
   POST /v2/tx/project/manager/tasks/assess
   Body: {
     alias,
     project_id,
     contributor_state_id,
     task_decisions: [{ alias, outcome: "accept" | "refuse" | "deny" }]
   }
   ```
   - `"accept"` — submission passes; contributor can claim credential.
   - `"refuse"` — "try again"; evidence is cleared; contributor resubmits via a new commit TX.
   - `"deny"` — **permanent expulsion**. Contributor state reverts to uncommitted and treasury assets are clawed back. Terminal.

   > ⚠ **DenyProject indexer gap (as of 2026-04-04):** andamioscan only indexes Accept (constructor 0) and Refuse (constructor 1). A `deny` outcome lands on-chain but is silently ignored by the indexer, so it will not currently show up in platform views. Track [DenyProjectPlan] for status before relying on Deny in production.

4. **Claim credential** (nets +13 ADA):
   ```
   POST /v2/tx/project/contributor/credential/claim
   Body: { alias, project_id, contributor_state_id }
   ```
   Mints credential NFT, burns contributor-state, returns ~14.5 ADA deposit. Charges a 1 ADA protocol fee to the instance-treasury.

#### 4. Fund Treasury

Add ADA to the project treasury at any time:

```
POST /v2/tx/project/user/treasury/add-funds
Auth: API Key + JWT
Body: { project_id, amount: 100000000 }
```

Amount is in lovelace. Funds are locked in the on-chain treasury and available for task rewards.

#### 5. Manage Managers

```
POST /v2/tx/project/owner/managers/manage
Auth: API Key + JWT
Body: { project_id, add_managers: [alias], remove_managers: [alias] }
```

Costs ~10.3 ADA per update transaction.

#### 6. Blacklist Management

Exclude contributors from the project:

```
POST /v2/tx/project/owner/contributor-blacklist/manage
Auth: API Key + JWT
Body: { project_id, add_blacklist: [alias], remove_blacklist: [alias] }
```

Costs ~0.34 ADA. Use when a contributor needs to be removed from participation.

### Key Concepts

**Treasury system**: On-chain ADA pool that funds task rewards. Managed by project owner. Deposited at creation and topped up via add-funds.

**Task escrow**: When tasks are created, their reward amount is moved from treasury to escrow. When tasks are assessed (pass), escrow releases to the contributor. When tasks are deleted, escrow returns to treasury.

**Contributor state**: On-chain token that tracks a contributor's participation. Minted on first task commit (~14.5 ADA deposit). Burned when credential is claimed (deposit refunded).

**Credential NFT**: Permanent on-chain proof of contribution. Minted to the contributor's wallet when they claim after completing assessed tasks.

### Querying Project Data

**Via CLI:**
```bash
# List projects
andamio project list --output json

# Get project details
andamio project get <project-id> --output json

# List tasks
andamio project task list <project-id> --output json

# Get specific task
andamio project task get <task-index> --project-id <project-id> --output json
```

**Via Andamioscan** (on-chain verification):
```
GET /api/v2/projects                              # All projects
GET /api/v2/projects/{id}/details                  # Project aggregate
GET /api/v2/projects/{id}/contributors/{alias}/status  # Contributor progress
```

### Offer Next Steps

- "Want to estimate costs for your project?" → `/cost-estimator`
- "Need to set up authentication?" → `/auth-setup`
- "Want to manage a course instead?" → `/course-ops`
- "Hit an error?" → `/troubleshoot`

### Guidelines

- Always mention the treasury deposit requirement when creating projects
- Explain that task rewards are locked in escrow — this is real ADA commitment
- Highlight that credential claims are net positive for contributors
- Default to CLI for task management (create, export, import)
- Show API for transaction operations (create project, assess tasks)
- Lovelace conversions: always clarify 1 ADA = 1,000,000 lovelace
