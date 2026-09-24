#!/bin/bash
# project-lifecycle.sh
#
# Full project transaction state machine loop on Andamio.
# Walks through every on-chain operation from project creation to credential claim.
#
# Every transaction follows the same five steps as course-lifecycle.sh:
#   build → sign → submit → register → wait(updated)
# This script runs them with 'andamio tx run', which does all five in one
# command. It has to: project_join and project_credential_claim must be
# registered with the task_hash in their metadata, which 'tx run' injects from
# the request body and 'tx register' has no way to send.
#
# One alias plays every role here: owner, manager and contributor. In a real
# project those are different people.
#
# Prerequisites:
#   - andamio CLI installed (brew install andamio-platform/tap/andamio)
#   - API key configured (andamio auth login --api-key <key>)
#   - Wallet JWT active (andamio user login)
#   - A submit endpoint configured. The URL must be the full submit route, e.g.
#       andamio config set-submit-url https://cardano-preprod.blockfrost.io/api/v0/tx/submit
#       andamio config set-submit-header project_id <your-blockfrost-project-id>
#   - A Cardano .skey file for signing (preprod)
#   - A course credential for this alias — run course-lifecycle.sh first; it
#     prints the COURSE_ID and SLT_HASH this script needs
#   - ~160 test ADA plus the treasury deposit, from the faucet
#     (https://docs.cardano.org/cardano-testnets/tools/faucet/)
#   - jq
#
# Usage:
#   export SKEY_PATH=/path/to/payment.skey
#   export COURSE_ID=<course_id from course-lifecycle.sh>
#   export SLT_HASH=<slt_hash from course-lifecycle.sh>
#   export TREASURY_ADA=200   # ADA to deposit in treasury (default: 200)
#   export TASK_REWARD_ADA=50 # ADA reward per task (default: 50)
#   export SUBMIT_URL=...     # optional: overrides the configured submit URL for this run
#   ./project-lifecycle.sh
#
# Cost breakdown (preprod, measured 2026-09-23, all in test ADA):
#   Create project (1 manager):             ~148 ADA (100 service fee + ~44.6 deposits
#                                                     + 2 stake registration + ~1.3 tx fee)
#   Fund treasury:                          treasury deposit + ~0.18 ADA
#   Publish task:                           task reward + ~0.32 ADA
#   Contributor first commit:               ~2.82 ADA (~2.3 locked + ~0.54 tx fee)
#   Manager assess:                         ~0.35 ADA
#   Contributor claim credential:           net gain (reward - commission + ~2 ADA back - ~0.36 fee)

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SKEY_PATH="${SKEY_PATH:?Set SKEY_PATH to your payment.skey file}"
COURSE_ID="${COURSE_ID:?Set COURSE_ID to the course whose credential gates this project}"
SLT_HASH="${SLT_HASH:?Set SLT_HASH to the module slt_hash printed by course-lifecycle.sh}"
TREASURY_ADA="${TREASURY_ADA:-200}"
TASK_REWARD_ADA="${TASK_REWARD_ADA:-50}"
SUBMIT_ARGS=()
[ -n "${SUBMIT_URL:-}" ] && SUBMIT_ARGS=(--submit-url "$SUBMIT_URL")

# Convert ADA to lovelace (1 ADA = 1,000,000 lovelace)
TREASURY_LOVELACE=$((TREASURY_ADA * 1000000))
TASK_REWARD_LOVELACE=$((TASK_REWARD_ADA * 1000000))

BASE_URL=$(andamio config show --output json | jq -r '.base_url')
ALIAS=$(andamio user status --output json | jq -r '.user_alias')

echo "=== Andamio Project Lifecycle ==="
echo "Environment:     $BASE_URL"
echo "Alias:           $ALIAS"
echo "Signer:          $SKEY_PATH"
echo "Prerequisite:    course $COURSE_ID, module $SLT_HASH"
echo "Treasury:        $TREASURY_ADA ADA ($TREASURY_LOVELACE lovelace)"
echo "Task reward:     $TASK_REWARD_ADA ADA ($TASK_REWARD_LOVELACE lovelace)"
echo ""

# ---------------------------------------------------------------------------
# Helper: build, sign, submit, register and wait for "updated" in one command
# ---------------------------------------------------------------------------
# Arguments:
#   $1 = build endpoint
#   $2 = request body (JSON string)
#   $3 = tx_type for registration
#   $4 = instance id (project_id) for registration, optional
#
# Progress goes to stderr. Sets RUN_RESULT (the tx run JSON, including the
# build response) and TX_HASH for the caller.

run_tx() {
  local endpoint="$1" body="$2" tx_type="$3" instance_id="${4:-}"
  local args=(--body "$body" --skey "$SKEY_PATH" --tx-type "$tx_type" --output json)
  [ -n "$instance_id" ] && args+=(--instance-id "$instance_id")
  args+=(${SUBMIT_ARGS[@]+"${SUBMIT_ARGS[@]}"})

  RUN_RESULT=$(andamio tx run "$endpoint" "${args[@]}")
  TX_HASH=$(jq -r '.tx_hash' <<<"$RUN_RESULT")
  echo "  $tx_type: $TX_HASH ($(jq -r '.state' <<<"$RUN_RESULT"))" >&2
}

# ---------------------------------------------------------------------------
# TX 1: Create Project
# ---------------------------------------------------------------------------
# Most complex Andamio transaction.
# Mints: 6 tokens (TreasuryScript, ProjectState, TreasuryToken, Governance,
#                   LocalStateToken, LocalStateNFT)
# Creates: 6 validator UTxOs + 1 stake account
# Cost: ~148 ADA (100 service fee + ~44.6 deposits incl. a 5 ADA treasury
#       reserve + 2 ADA stake registration + ~1.3 tx fee)
#
# course_prereqs is an array of [course_id, [slt_hash, ...]] tuples: a
# contributor must hold those credentials before committing to a task. Name
# every manager here — a manager added later pays a further 10 ADA service fee.

echo "============================================"
echo "TX 1/6: CREATE PROJECT"
echo "============================================"
echo "  Mints 6 tokens, creates 6 validator UTxOs."
echo "  Registers an on-chain stake account."
echo "  The project_id = LocalStateNFT policy ID."
echo ""

run_tx \
  "/v2/tx/instance/owner/project/create" \
  "{\"alias\": \"$ALIAS\", \"managers\": [\"$ALIAS\"], \"course_prereqs\": [[\"$COURSE_ID\", [\"$SLT_HASH\"]]]}" \
  "project_create"
CREATE_TX=$TX_HASH

# The build response carries the new project_id. The contributor_state_id is
# scoped to this project; every later project transaction needs both.
PROJECT_ID=$(jq -r '.build_response.project_id' <<<"$RUN_RESULT")
CONTRIBUTOR_STATE_ID=$(andamio project get "$PROJECT_ID" --output json | jq -r '.data.contributor_state_id')

echo "Project ID:           $PROJECT_ID"
echo "Contributor state ID: $CONTRIBUTOR_STATE_ID"
echo ""

# ---------------------------------------------------------------------------
# TX 2: Fund the Treasury
# ---------------------------------------------------------------------------
# The treasury is created with a 5 ADA reserve and no task funds.
# The deposit is locked on-chain as the project's budget — not a fee.
# Cost: ~0.18 ADA tx fee + the deposit

echo "============================================"
echo "TX 2/6: FUND TREASURY"
echo "============================================"
echo "  Deposits $TREASURY_ADA ADA into the on-chain treasury."
echo ""

run_tx \
  "/v2/tx/project/user/treasury/add-funds" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"deposit_value\": [[\"lovelace\", $TREASURY_LOVELACE]]}" \
  "treasury_fund" \
  "$PROJECT_ID"
FUND_TX=$TX_HASH
echo ""

# ---------------------------------------------------------------------------
# TX 3: Publish a Task
# ---------------------------------------------------------------------------
# Off-chain draft first, then tasks_manage mints it.
# deposit_value must equal the sum of the tasks' rewards. It is paid from the
# manager's wallet into the treasury (the project's treasury_fundings list
# records it) and locked for the reward.
# Cost: ~0.32 ADA tx fee + the reward

echo "============================================"
echo "TX 3/6: PUBLISH TASK"
echo "============================================"
echo "  Creates the task off-chain, then mints it."
echo "  Reward: $TASK_REWARD_ADA ADA."
echo ""

EXPIRATION="2026-12-31T00:00:00Z"
EXPIRATION_POSIX=1798675200000   # the same instant, in Unix milliseconds
TASK_CONTENT="Build an example demonstrating the Andamio API integration pattern."

andamio project task create "$PROJECT_ID" \
  --title "Build API integration example" \
  --lovelace "$TASK_REWARD_LOVELACE" \
  --expiration "$EXPIRATION" \
  --content "$TASK_CONTENT" \
  --output json >/dev/null

run_tx \
  "/v2/tx/project/manager/tasks/manage" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\", \"tasks_to_add\": [{\"project_content\": \"$TASK_CONTENT\", \"expiration_posix\": $EXPIRATION_POSIX, \"lovelace_amount\": $TASK_REWARD_LOVELACE, \"native_assets\": []}], \"tasks_to_remove\": [], \"deposit_value\": [[\"lovelace\", $TASK_REWARD_LOVELACE]]}" \
  "tasks_manage" \
  "$PROJECT_ID"
TASK_TX=$TX_HASH

# The task_hash is the task's on-chain identity. Contributors commit to it.
TASK_HASH=$(andamio project tasks "$PROJECT_ID" --output json | jq -r '.data[-1].task_hash')

echo "Task published. task_hash: $TASK_HASH"
echo ""

# ---------------------------------------------------------------------------
# TX 4: Contributor Commits to Task
# ---------------------------------------------------------------------------
# Mints: ContributorState token (first time only)
# Creates: ContributorState validator UTxO
# Cost: ~2.82 ADA first time (~2.3 ADA locked + ~0.54 tx fee)
#
# The locked ADA is RECOVERABLE — returned when the credential is claimed.
# There is no off-chain create step: this TX's confirmation creates the
# commitment, in COMMITTED. The builder rejects the commit (422) if the
# contributor doesn't hold the course_prereqs credential.

echo "============================================"
echo "TX 4/6: CONTRIBUTOR COMMITS TO TASK"
echo "============================================"
echo "  Contributor joins the project and commits to the task."
echo "  First commit mints ContributorState token."
echo ""

run_tx \
  "/v2/tx/project/contributor/task/commit" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\", \"task_hash\": \"$TASK_HASH\", \"task_info\": \"Committing to build the API integration example\"}" \
  "project_join" \
  "$PROJECT_ID"
COMMIT_TX=$TX_HASH

echo "Committed. Commitment status: COMMITTED."
echo ""

# ---------------------------------------------------------------------------
# TX 5: Manager Assesses
# ---------------------------------------------------------------------------
# Three outcomes: accept, refuse (retry) or deny (terminal).
# Cost: ~0.35 ADA

echo "============================================"
echo "TX 5/6: MANAGER ASSESSES"
echo "============================================"
echo "  Manager accepts the contribution."
echo ""

run_tx \
  "/v2/tx/project/manager/tasks/assess" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\", \"task_decisions\": [{\"alias\": \"$ALIAS\", \"outcome\": \"accept\"}]}" \
  "task_assess" \
  "$PROJECT_ID"
ASSESS_TX=$TX_HASH

echo "Assessed: ACCEPTED."
echo ""

# ---------------------------------------------------------------------------
# TX 6: Contributor Claims Credential
# ---------------------------------------------------------------------------
# Mints: Credential NFT
# Burns: ContributorState token
# Releases: the task reward (minus commission) and the ADA locked at commit
# Commission: max(1 ADA, commission_rate × reward); commission_rate defaults to 5%

echo "============================================"
echo "TX 6/6: CLAIM CREDENTIAL"
echo "============================================"
echo "  Burns ContributorState, pays the reward, mints the credential NFT."
echo ""

run_tx \
  "/v2/tx/project/contributor/credential/claim" \
  "{\"alias\": \"$ALIAS\", \"project_id\": \"$PROJECT_ID\", \"contributor_state_id\": \"$CONTRIBUTOR_STATE_ID\"}" \
  "project_credential_claim" \
  "$PROJECT_ID"
CLAIM_TX=$TX_HASH

echo "Credential claimed. Commitment status: REWARDED."
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
echo "  Task:             $TASK_HASH — assessed and rewarded"
echo "  Credential:       NFT in contributor's wallet"
echo ""
echo "Transaction history:"
echo "  1. project_create:           $CREATE_TX"
echo "  2. treasury_fund:            $FUND_TX"
echo "  3. tasks_manage:             $TASK_TX"
echo "  4. project_join:             $COMMIT_TX"
echo "  5. task_assess:              $ASSESS_TX"
echo "  6. project_credential_claim: $CLAIM_TX"
echo ""
echo "Verify on Andamioscan:"
echo "  https://andamioscan.io/projects/$PROJECT_ID"
echo ""
echo "Where the ADA went:"
echo "  Treasury deposit:  $TREASURY_ADA ADA (locked on-chain, funds future tasks)"
echo "  Task reward:       $TASK_REWARD_ADA ADA (paid to the contributor on claim, minus commission)"
echo "  Commit deposit:    ~2.3 ADA (returned to contributor on claim)"
echo "  Service fees:      100 ADA at creation + the claim commission (non-recoverable)"
echo "  Tx fees:           ~3 ADA (to Cardano stake pools, non-recoverable)"
