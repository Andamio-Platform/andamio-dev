#!/bin/bash
# project-lifecycle.sh
#
# Full project transaction state machine loop on Andamio.
# Walks through every on-chain operation from project creation to credential claim.
#
# Projects are Cardano-native task management:
#   - On-chain treasury funds task rewards
#   - Task escrow locks reward until assessment
#   - Credential NFTs prove completed work
#   - Contributors get deposits back + rewards on claim
#
# Each step follows the same pattern:
#   1. Build unsigned tx  (API returns CBOR hex)
#   2. Sign tx            (local .skey or browser wallet)
#   3. Submit tx          (to Cardano network)
#   4. Register tx        (tell Andamio to track it)
#   5. Wait for "updated" (DB synced after on-chain confirmation)
#
# Prerequisites:
#   - andamio CLI installed (brew install andamio-platform/tap/andamio)
#   - API key configured (andamio auth login --api-key <key>)
#   - Wallet JWT active (andamio user login)
#   - A Cardano .skey file for signing (preprod)
#   - ~400 test ADA from the faucet (https://docs.cardano.org/cardano-testnets/tools/faucet/)
#
# Usage:
#   export SKEY_PATH=/path/to/payment.skey
#   export TREASURY_ADA=200   # ADA to deposit in treasury (default: 200)
#   export TASK_REWARD_ADA=50 # ADA reward per task (default: 50)
#   ./project-lifecycle.sh
#
# Cost breakdown (preprod, all in test ADA):
#   Create project (1 mgr, 200 treasury):  ~343 ADA
#   Create task (50 ADA reward):            ~50.43 ADA
#   Contributor first commit:               ~15.01 ADA
#   Manager assess:                         ~0.35 ADA
#   Contributor claim credential:           -13.15 ADA (refund + reward)
#   ---
#   Total loop: ~395.64 ADA (most locked in treasury/escrow, recoverable)

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SKEY_PATH="${SKEY_PATH:?Set SKEY_PATH to your payment.skey file}"
TREASURY_ADA="${TREASURY_ADA:-200}"
TASK_REWARD_ADA="${TASK_REWARD_ADA:-50}"
POLL_INTERVAL=5
POLL_TIMEOUT=120

# Convert ADA to lovelace (1 ADA = 1,000,000 lovelace)
TREASURY_LOVELACE=$((TREASURY_ADA * 1000000))
TASK_REWARD_LOVELACE=$((TASK_REWARD_ADA * 1000000))

BASE_URL=$(andamio config show --output json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('base_url','https://preprod.api.andamio.io'))" 2>/dev/null || echo "https://preprod.api.andamio.io")
ALIAS=$(andamio user me --output json | python3 -c "import json,sys; print(json.load(sys.stdin)['alias'])")

echo "=== Andamio Project Lifecycle ==="
echo "Environment:     $BASE_URL"
echo "Alias:           $ALIAS"
echo "Signer:          $SKEY_PATH"
echo "Treasury:        $TREASURY_ADA ADA ($TREASURY_LOVELACE lovelace)"
echo "Task reward:     $TASK_REWARD_ADA ADA ($TASK_REWARD_LOVELACE lovelace)"
echo ""

# ---------------------------------------------------------------------------
# Helper: execute a full tx state machine cycle
# (same as course-lifecycle.sh — identical pattern for every tx)
# ---------------------------------------------------------------------------

do_transaction() {
  local endpoint="$1"
  local body="$2"
  local tx_type="$3"
  local desc="$4"

  echo "--- Step: $desc ---"

  # 1. BUILD
  echo "  [1/5] Building transaction..."
  local build_result
  build_result=$(andamio tx build "$endpoint" --body "$body" --output json)
  local unsigned_tx
  unsigned_tx=$(echo "$build_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['unsigned_tx'])")
  echo "  [1/5] Built. Unsigned tx: ${unsigned_tx:0:20}..."

  # 2. SIGN
  echo "  [2/5] Signing transaction..."
  local sign_result
  sign_result=$(andamio tx sign --tx "$unsigned_tx" --skey "$SKEY_PATH" --output json)
  local signed_tx
  signed_tx=$(echo "$sign_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['tx_hex'])")
  echo "  [2/5] Signed."

  # 3. SUBMIT
  echo "  [3/5] Submitting to Cardano..."
  local submit_result
  submit_result=$(andamio tx submit --tx "$signed_tx" --output json)
  local tx_hash
  tx_hash=$(echo "$submit_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['tx_hash'])")
  echo "  [3/5] Submitted. TX hash: $tx_hash"

  # 4. REGISTER
  echo "  [4/5] Registering for tracking..."
  andamio tx register --tx-hash "$tx_hash" --tx-type "$tx_type" >/dev/null 2>&1
  echo "  [4/5] Registered as $tx_type."

  # 5. WAIT for "updated" (on-chain confirmed + DB synced)
  echo "  [5/5] Waiting for confirmation + DB sync..."
  local elapsed=0
  while [ $elapsed -lt $POLL_TIMEOUT ]; do
    local status
    status=$(andamio tx status "$tx_hash" --output json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('status','pending'))" 2>/dev/null || echo "pending")

    if [ "$status" = "updated" ]; then
      echo "  [5/5] Confirmed and synced."
      echo ""
      echo "$tx_hash"
      return 0
    elif [ "$status" = "failed" ]; then
      echo "  [5/5] FAILED. Check: andamio tx status $tx_hash"
      return 1
    fi

    sleep $POLL_INTERVAL
    elapsed=$((elapsed + POLL_INTERVAL))
    echo "  [5/5] Status: $status (${elapsed}s / ${POLL_TIMEOUT}s)"
  done

  echo "  [5/5] TIMEOUT waiting for confirmation."
  echo "$tx_hash"
  return 1
}

# ---------------------------------------------------------------------------
# TX 1: Create Project
# ---------------------------------------------------------------------------
# Most complex Andamio transaction.
# Mints: 6 tokens (TreasuryScript, ProjectState, TreasuryToken, Governance,
#                   LocalStateToken, LocalStateNFT)
# Creates: 6 validator UTxOs + 1 stake account
# Cost: ~143 ADA base + treasury deposit
#
# The on-chain treasury is a real ADA pool. The treasury_deposit is locked
# and used to fund task rewards. It's not a fee — it's your project's budget.

echo "============================================"
echo "TX 1/5: CREATE PROJECT"
echo "============================================"
echo "  Mints 6 tokens, creates 6 validator UTxOs."
echo "  Registers an on-chain stake account."
echo "  Deposits $TREASURY_ADA ADA into the on-chain treasury."
echo "  The project_id = LocalStateNFT policy ID."
echo ""

CREATE_TX=$(do_transaction \
  "/v2/tx/instance/owner/project/create" \
  "{\"alias\": \"$ALIAS\", \"managers\": [\"$ALIAS\"], \"treasury_deposit\": $TREASURY_LOVELACE}" \
  "project_create" \
  "Create project with ${TREASURY_ADA} ADA treasury")

# Discover the project_id and contributor_state_id.
# contributor_state_id is the ContributorState minting policy ID — one per
# project, minted at project creation. Every subsequent project TX (tasks_manage,
# task/commit, task/action, tasks_assess, credential/claim) needs it.
echo "Discovering project_id and contributor_state_id..."
PROJECT_JSON=$(andamio project list --output json)
PROJECT_ID=$(echo "$PROJECT_JSON" | python3 -c "
import json, sys
projects = json.load(sys.stdin)['data']
print(projects[-1]['project_id'])
")
CONTRIBUTOR_STATE_ID=$(andamio project show "$PROJECT_ID" --output json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['contributor_state_id'])")
echo "Project ID:           $PROJECT_ID"
echo "ContributorState ID:  $CONTRIBUTOR_STATE_ID"
echo ""

# ---------------------------------------------------------------------------
# TX 2: Create Task
# ---------------------------------------------------------------------------
# Mints: nothing
# Moves: reward amount from treasury to task escrow
# Cost: reward + ~0.43 ADA tx fee
#
# The task reward is LOCKED in escrow until the task is assessed.
# If the task is deleted before assessment, reward returns to treasury.

echo "============================================"
echo "TX 2/5: CREATE TASK"
echo "============================================"
echo "  Creates a task with $TASK_REWARD_ADA ADA reward."
echo "  Reward moves from treasury to escrow (locked until assessed)."
echo ""

# Prepare task fields. `project_content` is the on-chain task description
# (max 140 chars). `expiration_posix` is a UNIX timestamp in milliseconds.
TASK_CONTENT="Build an example demonstrating the Andamio API integration pattern."
TASK_EXPIRATION_MS=1767225600000  # 2026-12-31T00:00:00Z

# Create the task off-chain first (DB record) so the gateway has something to
# match the on-chain task to after confirmation.
andamio project task create "$PROJECT_ID" \
  --title "Build API integration example" \
  --lovelace "$TASK_REWARD_LOVELACE" \
  --expiration "2026-12-31" \
  --content "$TASK_CONTENT" >/dev/null 2>&1

# tasks_manage body (per PROTOCOL.md §6.2): all three of tasks_to_add,
# tasks_to_remove, and deposit_value are required fields. deposit_value is a
# list of [asset, amount] pairs covering the total reward moving into escrow.
TASK_TX=$(do_transaction \
  "/v2/tx/project/manager/tasks/manage" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\", \"tasks_to_add\": [{\"project_content\": \"$TASK_CONTENT\", \"expiration_posix\": $TASK_EXPIRATION_MS, \"lovelace_amount\": $TASK_REWARD_LOVELACE, \"native_assets\": []}], \"tasks_to_remove\": [], \"deposit_value\": [[\"lovelace\", $TASK_REWARD_LOVELACE]]}" \
  "tasks_manage" \
  "Create task with ${TASK_REWARD_ADA} ADA reward")

# Discover the task_hash so the contributor can commit to it below.
# task_hash is Blake2b-256 of the Plutus Data Constr 0 task datum — known only
# after the task is minted on-chain.
TASK_HASH=$(andamio project task list "$PROJECT_ID" --output json \
  | python3 -c "import json,sys; tasks = json.load(sys.stdin)['data']; print(tasks[-1]['task_hash'])")
echo "Task created. Reward locked in escrow. task_hash: $TASK_HASH"
echo ""

# ---------------------------------------------------------------------------
# TX 3: Contributor Commits to Task
# ---------------------------------------------------------------------------
# Mints: ContributorState token (first time only)
# Creates: ContributorState validator UTxO
# Cost: ~15.01 ADA first time (14.5 state deposit + 0.51 tx fee)
#        ~0.51 ADA for subsequent commits (no new deposit)
#
# The 14.5 ADA deposit is RECOVERABLE — returned when credential is claimed.
# This prevents spam: you need skin in the game to commit to tasks.

echo "============================================"
echo "TX 3/5: CONTRIBUTOR COMMITS TO TASK"
echo "============================================"
echo "  Contributor joins the project and commits to task."
echo "  First commit mints ContributorState token."
echo "  Locks ~14.5 ADA deposit (refunded on credential claim)."
echo ""

COMMIT_TX=$(do_transaction \
  "/v2/tx/project/contributor/task/commit" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\", \"task_hash\": \"$TASK_HASH\", \"task_info\": \"Committing to build the API integration example\"}" \
  "project_join" \
  "Contributor commits to task")

echo "Contributor committed to task $TASK_HASH."
echo ""

# ---------------------------------------------------------------------------
# TX 4: Manager Assesses Task
# ---------------------------------------------------------------------------
# Mints: nothing
# Modifies: ContributorState UTxO datum (assessment stored)
# Cost: ~0.35 ADA
#
# Project assessments have THREE outcomes (unlike courses, which only have
# accept/refuse):
#   - "accept" → contributor can claim credential + reward
#   - "refuse" → "try again"; evidence cleared; contributor resubmits via a
#                 new commit TX
#   - "deny"   → PERMANENT EXPULSION; treasury assets clawed back; terminal
#
# ⚠ DenyProject indexer gap (as of 2026-04-04): andamioscan only indexes
#   Accept (constructor 0) and Refuse (constructor 1). A "deny" outcome lands
#   on-chain but is silently ignored by the indexer — the contributor will
#   not show as DENIED in platform views. Track DenyProjectPlan for status
#   before relying on Deny in production.

echo "============================================"
echo "TX 4/5: MANAGER ASSESSES TASK"
echo "============================================"
echo "  Manager reviews and accepts the task submission."
echo "  Assessment outcome (accept / refuse / deny) stored on-chain."
echo ""

ASSESS_TX=$(do_transaction \
  "/v2/tx/project/manager/tasks/assess" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\", \"task_decisions\": [{\"alias\": \"$ALIAS\", \"outcome\": \"accept\"}]}" \
  "task_assess" \
  "Manager assessment")

echo "Task assessed: ACCEPT."
echo ""

# ---------------------------------------------------------------------------
# TX 5: Contributor Claims Credential
# ---------------------------------------------------------------------------
# Mints: Credential NFT (to contributor's wallet)
# Burns: ContributorState token
# Releases: ~14.5 ADA deposit back to contributor
# Transfers: task reward from escrow to contributor
# Cost: NEGATIVE — contributor GAINS ~13+ ADA
#
# This is the payoff. The contributor receives:
#   1. A permanent credential NFT (on-chain proof of work)
#   2. Their state deposit back (~14.5 ADA)
#   3. The task reward from escrow
#
# Net: contributor gains deposit + reward - service fee - tx fee

echo "============================================"
echo "TX 5/5: CLAIM PROJECT CREDENTIAL"
echo "============================================"
echo "  Contributor claims credential NFT."
echo "  Burns ContributorState, refunds ~14.5 ADA deposit."
echo "  Receives task reward from escrow."
echo "  Contributor GAINS ADA — claims are net positive."
echo ""

CLAIM_TX=$(do_transaction \
  "/v2/tx/project/contributor/credential/claim" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\"}" \
  "project_credential_claim" \
  "Claim project credential")

echo "Credential NFT minted to wallet."
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo "============================================"
echo "PROJECT LIFECYCLE COMPLETE"
echo "============================================"
echo ""
echo "On-chain state:"
echo "  Project:          $PROJECT_ID"
echo "  Treasury:         $TREASURY_ADA ADA deposited (minus task reward)"
echo "  Task:             Assessed and completed"
echo "  Credential:       NFT in contributor's wallet"
echo ""
echo "Transaction history:"
echo "  1. project_create:           $CREATE_TX"
echo "  2. tasks_manage:             $TASK_TX"
echo "  3. project_join:             $COMMIT_TX"
echo "  4. task_assess:              $ASSESS_TX"
echo "  5. project_credential_claim: $CLAIM_TX"
echo ""
echo "Verify on Andamioscan:"
echo "  https://andamioscan.io/projects/$PROJECT_ID"
echo ""
echo "Where the ADA went:"
echo "  Treasury deposit:  $TREASURY_ADA ADA (locked on-chain, funds future tasks)"
echo "  Task escrow:       $TASK_REWARD_ADA ADA (transferred to contributor on claim)"
echo "  State deposit:     ~14.5 ADA (returned to contributor on claim)"
echo "  Service fees:      ~101 ADA (to protocol treasury, non-recoverable)"
echo "  Tx fees:           ~2.94 ADA (to Cardano stake pools, non-recoverable)"
echo ""
echo "Key insight: credential claims are NET POSITIVE for contributors."
echo "They get their deposit back plus the task reward."
echo ""
echo "============================================"
echo "IN PRACTICE: USE 'tx run'"
echo "============================================"
echo ""
echo "This script shows the 5-step state machine for learning purposes."
echo "In practice, 'andamio tx run' wraps all 5 steps into one command:"
echo ""
echo "  andamio tx run /v2/tx/instance/owner/project/create \\"
echo "    --body '{\"alias\":\"$ALIAS\",\"managers\":[\"$ALIAS\"],\"treasury_deposit\":$TREASURY_LOVELACE}' \\"
echo "    --skey \$SKEY_PATH \\"
echo "    --tx-type project_create"
echo ""
echo "tx run handles build, sign, submit, register, and polling automatically."
echo "Progress goes to stderr. Use --output json for scripted consumption."
echo "Use --no-wait to skip confirmation polling."
