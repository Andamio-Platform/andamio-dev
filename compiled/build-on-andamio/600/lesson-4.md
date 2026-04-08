# Run a full project lifecycle on Andamio

## Before we start

Same structure as M500.5, different domain. You'll create a project with a funded treasury, publish a task, commit as a contributor, get assessed, and claim a credential with the task reward. Five on-chain transactions, one loop.

The reference for this lesson is `examples/project-lifecycle.sh`. You can run the script end to end or execute each transaction manually.

## Prerequisites

A project requires a course credential as a prerequisite. If you haven't run the course lifecycle (M500.5), you'll need a course with at least one module and a credential for the contributor alias. The example scripts are designed to run in sequence — `course-lifecycle.sh` first, then `project-lifecycle.sh`.

You'll also need more test ADA than the course lifecycle. Budget ~400 ADA: ~112 ADA in service fees and deposits, plus whatever you put in the treasury (the script defaults to 200 ADA).

```bash
export SKEY_PATH=/path/to/payment.skey
export TREASURY_ADA=200
export TASK_REWARD_ADA=50
```

## The project.setup loop

Two transactions create the project and publish a task. This is the `project.setup` loop from `reference/tx-loops.yaml`.

### TX 1: Create the project

```bash
andamio tx run /v2/tx/instance/owner/project/create \
  --body '{"alias":"'"$ALIAS"'","managers":["'"$ALIAS"'"],"course_prereqs":[["'"$COURSE_ID"'",["'"$SLT_HASH"'"]]]}' \
  --skey "$SKEY_PATH" \
  --tx-type project_create
```

The `course_prereqs` field links the project to a course credential prerequisite. The format is an array of tuples: `[["<course_id>", ["<slt_hash_1>", "<slt_hash_2>"]]]`. Each tuple pairs a course ID with the slt_hashes that contributors must have earned.

This is the most complex transaction on Andamio: six mints, six validator UTxOs, a stake account registration, and a protocol reserve deposit. Cost: ~112 ADA in service fees (100 base + 10 per manager) plus ~45 ADA in minUTxO deposits.

**Important:** This transaction creates the treasury UTxO but does NOT fund it for task rewards. You must fund the treasury separately before publishing tasks (see TX 2a below).

After `updated`, discover two IDs you'll need for every subsequent transaction:

```bash
PROJECT_ID=$(andamio project list --output json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data'][-1]['project_id'])")

CONTRIBUTOR_STATE_ID=$(andamio project show "$PROJECT_ID" --output json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['contributor_state_id'])")
```

| ID | What it is | Where it comes from |
|----|-----------|-------------------|
| `project_id` | LocalStateNFT policy ID — the project's on-chain identity | `project list` response |
| `contributor_state_id` | ContributorState minting policy ID — scoped to this project | `project show` response |

Both are 56-character hex strings. Every project transaction after creation requires both.

### TX 2a: Fund the treasury

The treasury must hold enough ADA to cover all task rewards before you can publish tasks.

```bash
andamio tx run /v2/tx/project/user/treasury/add-funds \
  --body '{"alias":"'"$ALIAS"'","project_id":"'"$PROJECT_ID"'","deposit_value":[["lovelace",'"$TREASURY_LOVELACE"']]}' \
  --skey "$SKEY_PATH" \
  --tx-type treasury_fund
```

Cost: ~0.18 ADA tx fee plus the deposit amount. The deposit moves ADA from your wallet into the project treasury. After `updated`, verify the balance:

```bash
andamio project get "$PROJECT_ID" --output json | python3 -c "import json,sys; print('Treasury balance:', json.load(sys.stdin)['data']['treasury_balance'])"
```

The displayed balance excludes a 5 ADA protocol reserve, so depositing 200 ADA shows a balance of 195 ADA.

### TX 2b: Publish a task

Create the task off-chain, then mint it with `tasks_manage`:

```bash
# Off-chain: create task record
andamio project task create "$PROJECT_ID" \
  --title "Build API integration example" \
  --lovelace "$TASK_REWARD_LOVELACE" \
  --expiration "2026-12-31" \
  --content "Build an example demonstrating the Andamio API integration pattern."

# On-chain: mint task, move reward from treasury to escrow
andamio tx run /v2/tx/project/manager/tasks/manage \
  --body-file tasks-body.json \
  --skey "$SKEY_PATH" \
  --tx-type tasks_manage \
  --instance-id "$PROJECT_ID"
```

Where `tasks-body.json`:

```json
{
  "alias": "alice-dev",
  "project_id": "a1b2c3d4...",
  "contributor_state_id": "e5f6a7b8...",
  "tasks_to_add": [
    {
      "project_content": "Build an example demonstrating the Andamio API integration pattern.",
      "expiration_posix": 1767225600000,
      "lovelace_amount": 50000000,
      "native_assets": []
    }
  ],
  "tasks_to_remove": [],
  "deposit_value": [["lovelace", 50000000]]
}
```

| Field | Purpose |
|-------|---------|
| `tasks_to_add` | Tasks to publish. Each has content, expiration, reward, and optional native assets. |
| `deposit_value` | Total reward moving from treasury to escrow. Must cover all `tasks_to_add` rewards. |
| `tasks_to_remove` | For removing unpublished tasks. Reward returns to treasury. |

Cost: ~0.43 ADA tx fee. The task reward (50 ADA) moves from treasury to escrow — it's not a new cost, it's a reallocation.

After `updated`, discover the `task_hash`:

```bash
TASK_HASH=$(andamio project task list "$PROJECT_ID" --output json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data'][-1]['task_hash'])")
```

## The project.credential loop

Three transactions take a contributor from commitment to credential. This is the `project.credential` loop from `reference/tx-loops.yaml`.

### TX 3: Contributor commits

```bash
andamio tx run /v2/tx/project/contributor/task/commit \
  --body '{"alias":"'"$ALIAS"'","project_id":"'"$PROJECT_ID"'","contributor_state_id":"'"$CONTRIBUTOR_STATE_ID"'","task_hash":"'"$TASK_HASH"'","task_info":"Committing to build the API integration example"}' \
  --skey "$SKEY_PATH" \
  --tx-type project_join
```

Cost: ~15 ADA on first commit (~14.5 ADA state deposit + ~0.51 ADA tx fee). The deposit is locked in the ContributorState UTxO and refunded at credential claim.

The contributor must hold the prerequisite course credential — the transaction builder verifies this on-chain and rejects with 422 if the credential is missing.

### TX 4: Manager assesses

```bash
andamio tx run /v2/tx/project/manager/tasks/assess \
  --body '{"alias":"'"$ALIAS"'","project_id":"'"$PROJECT_ID"'","contributor_state_id":"'"$CONTRIBUTOR_STATE_ID"'","task_decisions":[{"alias":"'"$ALIAS"'","outcome":"accept"}]}' \
  --skey "$SKEY_PATH" \
  --tx-type task_assess
```

Cost: ~0.35 ADA. The `task_decisions` array supports batch assessment — multiple contributors, mixed outcomes (accept/refuse/deny), one transaction.

### TX 5: Contributor claims credential

```bash
andamio tx run /v2/tx/project/contributor/credential/claim \
  --body '{"alias":"'"$ALIAS"'","project_id":"'"$PROJECT_ID"'","contributor_state_id":"'"$CONTRIBUTOR_STATE_ID"'"}' \
  --skey "$SKEY_PATH" \
  --tx-type project_credential_claim
```

Cost: **net gain**. The contributor receives:
- ~14.5 ADA state deposit refund
- Task reward from escrow (50 ADA minus 5% commission = 47.5 ADA)
- A credential NFT

Minus tx fee (~0.36 ADA) and 1 ADA protocol fee. Net gain: ~60+ ADA.

## Cost summary

| Transaction | Paid by | Cost |
|-------------|---------|------|
| `project_create` | Owner | ~112 ADA (service) + ~45 ADA (deposits) + treasury deposit |
| `tasks_manage` | Manager | ~0.43 ADA (fee) + reward moves to escrow |
| `project_join` | Contributor | ~15 ADA (~14.5 deposit + ~0.51 fee) |
| `task_assess` | Manager | ~0.35 ADA |
| `project_credential_claim` | Contributor | **Net gain**: deposit refund + reward - fees |

The `project.credential` loop costs ~1.27 ADA in tx fees (contributor: ~0.92; manager: ~0.35). The contributor deposits ~14.5 ADA at join and gets it back plus the task reward at claim.

## Running the example script

```bash
export SKEY_PATH=/path/to/payment.skey
export TREASURY_ADA=200
export TASK_REWARD_ADA=50
./examples/project-lifecycle.sh
```

The script discovers `project_id`, `contributor_state_id`, and `task_hash` automatically. At the end, it prints all transaction hashes and a breakdown of where the ADA went.

## Your turn

Run the full project lifecycle — either via `examples/project-lifecycle.sh` or manually. Paste the `project_credential_claim` transaction hash (the final TX).

If you haven't run the course lifecycle first, you'll need to — the contributor needs a course credential as a prerequisite.

## Rubric

A valid `project_credential_claim` hash is a 64-character hex string. Verify with `andamio tx status <hash>` — state should be `updated`, `tx_type` should be `project_credential_claim`. Your wallet should now contain a project credential NFT and more ADA than when the claim started (the deposit refund + reward).

## What you just did

You ran a complete project lifecycle on Andamio: created a project with a funded treasury, published a task with an escrow reward, committed as a contributor, got assessed, and claimed a credential with a net ADA gain. The money moved through treasury → escrow → contributor's wallet, enforced by the protocol at every step.

This is the `project.credential` loop — the pattern behind every piece of funded work on Andamio.

You also unlocked `/project-ops` in Ops Mode. That skill wraps the project operations from this module. You know what it does under the hood.
