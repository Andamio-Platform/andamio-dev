#!/bin/bash
# course-lifecycle.sh
#
# Full course transaction state machine loop on Andamio.
# Walks through every on-chain operation from course creation to credential claim.
#
# Each step follows the same pattern:
#   1. Build unsigned tx  (API returns CBOR hex)
#   2. Sign tx            (local .skey or browser wallet)
#   3. Submit tx          (to Cardano network)
#   4. Register tx        (tell Andamio to track it)
#   5. Wait for "updated" (DB synced after on-chain confirmation)
#
# One alias plays every role here: owner, teacher and student. In a real course
# those are different people.
#
# Prerequisites:
#   - andamio CLI installed (brew install andamio-platform/tap/andamio)
#   - API key configured (andamio auth login --api-key <key>)
#   - Wallet JWT active (andamio user login)
#   - A submit endpoint configured. The URL must be the full submit route, e.g.
#       andamio config set-submit-url https://cardano-preprod.blockfrost.io/api/v0/tx/submit
#       andamio config set-submit-header "project_id: <your-blockfrost-project-id>"
#   - A Cardano .skey file for signing (preprod)
#   - ~130 test ADA from the faucet (https://docs.cardano.org/cardano-testnets/tools/faucet/)
#   - jq
#
# Usage:
#   export SKEY_PATH=/path/to/payment.skey
#   export SUBMIT_URL=...        # optional: overrides the configured submit URL for this run
#   ./course-lifecycle.sh
#
# Cost breakdown (preprod, measured 2026-09-23, all in test ADA):
#   Create course (1 teacher):  ~119.3 ADA (100 service fee + ~18.8 deposits + ~0.56 tx fee)
#   Add 1 module:               ~1.86 ADA
#   Student enroll:             ~2.64 ADA
#   Student update:             ~0.33 ADA
#   Teacher assess:             ~0.27 ADA
#   Student claim credential:   -1.65 ADA (refund)
#   ---
#   Total loop:                 ~122.8 ADA

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SKEY_PATH="${SKEY_PATH:?Set SKEY_PATH to your payment.skey file}"
POLL_INTERVAL=5     # seconds between tx status checks
POLL_TIMEOUT=300    # max seconds to wait for confirmation
SUBMIT_ARGS=()
[ -n "${SUBMIT_URL:-}" ] && SUBMIT_ARGS=(--submit-url "$SUBMIT_URL")

BASE_URL=$(andamio config show --output json | jq -r '.base_url')
ALIAS=$(andamio user status --output json | jq -r '.user_alias')

echo "=== Andamio Course Lifecycle ==="
echo "Environment: $BASE_URL"
echo "Alias:       $ALIAS"
echo "Signer:      $SKEY_PATH"
echo ""

# ---------------------------------------------------------------------------
# Helper: execute a full tx state machine cycle
# ---------------------------------------------------------------------------
# Arguments:
#   $1 = build endpoint (e.g., /v2/tx/instance/owner/course/create)
#   $2 = request body (JSON string)
#   $3 = tx_type for registration (e.g., course_create)
#   $4 = description for logging
#   $5 = instance id (course_id) for registration, optional
#
# Progress goes to stderr. Sets BUILD_RESULT (the build response JSON) and
# TX_HASH for the caller.

do_transaction() {
  local endpoint="$1"
  local body="$2"
  local tx_type="$3"
  local desc="$4"
  local instance_id="${5:-}"

  echo "--- Step: $desc ---" >&2

  # 1. BUILD — request unsigned transaction
  echo "  [1/5] Building transaction..." >&2
  BUILD_RESULT=$(andamio tx build "$endpoint" --body "$body" --output json)
  local unsigned_tx
  unsigned_tx=$(jq -r '.unsigned_tx' <<<"$BUILD_RESULT")
  echo "  [1/5] Built. Unsigned tx: ${unsigned_tx:0:20}..." >&2

  # 2. SIGN — sign with local .skey. The signed tx's hash is known from here on.
  echo "  [2/5] Signing transaction..." >&2
  local sign_result signed_tx
  sign_result=$(andamio tx sign --tx "$unsigned_tx" --skey "$SKEY_PATH" --output json)
  signed_tx=$(jq -r '.signed_tx' <<<"$sign_result")
  TX_HASH=$(jq -r '.tx_hash' <<<"$sign_result")
  echo "  [2/5] Signed. TX hash: $TX_HASH" >&2

  # 3. SUBMIT — send to Cardano network via the configured submit endpoint
  echo "  [3/5] Submitting to Cardano..." >&2
  andamio tx submit --tx "$signed_tx" ${SUBMIT_ARGS[@]+"${SUBMIT_ARGS[@]}"} --output json >/dev/null
  echo "  [3/5] Submitted." >&2

  # 4. REGISTER — tell Andamio to track this transaction
  echo "  [4/5] Registering for tracking..." >&2
  local register_args=(--tx-hash "$TX_HASH" --tx-type "$tx_type")
  [ -n "$instance_id" ] && register_args+=(--instance-id "$instance_id")
  andamio tx register "${register_args[@]}" >/dev/null
  echo "  [4/5] Registered as $tx_type." >&2

  # 5. WAIT — poll until state is "updated" (DB synced)
  echo "  [5/5] Waiting for confirmation + DB sync..." >&2
  local elapsed=0 state
  while [ $elapsed -lt $POLL_TIMEOUT ]; do
    state=$(andamio tx status "$TX_HASH" --output json 2>/dev/null | jq -r '.state // "pending"' || echo "pending")

    case "$state" in
      updated)
        echo "  [5/5] Confirmed and synced." >&2
        echo "" >&2
        return 0 ;;
      failed|expired)
        echo "  [5/5] $state. Check: andamio tx status $TX_HASH" >&2
        return 1 ;;
    esac

    sleep $POLL_INTERVAL
    elapsed=$((elapsed + POLL_INTERVAL))
    echo "  [5/5] State: $state (${elapsed}s / ${POLL_TIMEOUT}s)" >&2
  done

  echo "  [5/5] TIMEOUT waiting for confirmation. A tx that never leaves 'pending' may" >&2
  echo "        not have reached the chain — check the submit URL ends in /tx/submit." >&2
  return 1
}

# ---------------------------------------------------------------------------
# TX 1: Create Course
# ---------------------------------------------------------------------------
# Mints: LocalStateNFT + LocalStateToken + Governance
# Creates: 3 validator UTxOs
# Cost: ~119.3 ADA (100 service fee + ~18.8 min UTXO + ~0.56 tx fee)
# The LocalStateNFT policy ID becomes the course_id. Name every teacher here:
# a teacher added later pays a further 10 ADA service fee.

echo "============================================"
echo "TX 1/6: CREATE COURSE"
echo "============================================"
echo "  Mints 3 tokens, creates 3 on-chain UTxOs."
echo "  The course_id = LocalStateNFT policy ID."
echo ""

do_transaction \
  "/v2/tx/instance/owner/course/create" \
  "{\"alias\": \"$ALIAS\", \"teachers\": [\"$ALIAS\"]}" \
  "course_create" \
  "Create course"
COURSE_TX=$TX_HASH

# The build response carries the new course_id.
COURSE_ID=$(jq -r '.course_id' <<<"$BUILD_RESULT")
echo "Course ID: $COURSE_ID"
echo ""

# ---------------------------------------------------------------------------
# TX 2: Add Module
# ---------------------------------------------------------------------------
# Mints: Module token
# Creates: Module validator UTxO
# Cost: ~1.86 ADA (0 service fee + 1.59 min UTXO + 0.27 tx fee)

echo "============================================"
echo "TX 2/6: ADD MODULE"
echo "============================================"
echo "  Mints module token, creates module UTxO."
echo ""

# Define the Student Learning Targets for this module.
# The slt_hash is derived from this exact list — same SLTs in, same hash out.
SLT_1="Learner can explain the Andamio transaction state machine"

# Create the module off-chain with its SLTs and approve it in one step. The
# response carries the computed slt_hash — the module's on-chain identity.
SLT_HASH=$(andamio course create-module \
  --course-id "$COURSE_ID" \
  --code 100 \
  --title "Getting Started with Andamio" \
  --slt "$SLT_1" \
  --sort-order 1 \
  --approve \
  --output json | jq -r '.slt_hash')
echo "Module 100 approved (slt_hash: $SLT_HASH)."

# The modules_manage confirmation only matches modules in PENDING_TX.
andamio course teacher update-module-status \
  --course-id "$COURSE_ID" --module-code 100 --status PENDING_TX >/dev/null

# The module manage TX mints the module token on-chain.
# modules_to_add, modules_to_update and modules_to_remove are ALL required
# arrays, even when empty. `module_code` is off-chain only and never appears in
# TX bodies.
do_transaction \
  "/v2/tx/course/teacher/modules/manage" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"modules_to_add\": [{\"slts\": [\"$SLT_1\"], \"allowed_student_state_ids\": [], \"prereq_credential_hashes\": []}], \"modules_to_update\": [], \"modules_to_remove\": []}" \
  "modules_manage" \
  "Add module 100" \
  "$COURSE_ID"
MODULE_TX=$TX_HASH

# Students can only enroll in a module that has assignment content.
QUIZ_FILE=$(mktemp)
cat >"$QUIZ_FILE" <<'EOF'
{
  "type": "quiz",
  "version": 1,
  "passThreshold": 1,
  "questions": [
    {
      "id": "q1",
      "prompt": "Which transaction state means the chain is confirmed and the database is synced?",
      "options": [
        { "value": "updated", "label": "updated" },
        { "value": "confirmed", "label": "confirmed" }
      ],
      "correctValue": "updated"
    }
  ]
}
EOF
andamio course import-assignment "$COURSE_ID" 100 "$QUIZ_FILE" --title "Module 100 check" --output json >/dev/null
rm -f "$QUIZ_FILE"

echo "Module 100 minted on-chain with its assignment."
echo ""

# ---------------------------------------------------------------------------
# TX 3: Student Enrolls (Assignment Commit)
# ---------------------------------------------------------------------------
# Mints: CourseState token (on first enrollment)
# Creates: CourseState validator UTxO
# Cost: ~2.64 ADA (0 service + ~2.27 locked + ~0.37 tx fee)
# There is no off-chain create step: this TX's confirmation creates the
# commitment, directly in SUBMITTED.

echo "============================================"
echo "TX 3/6: STUDENT ENROLLS"
echo "============================================"
echo "  Student commits to the assignment with initial evidence."
echo "  Mints CourseState token, locks enrollment deposit."
echo ""

do_transaction \
  "/v2/tx/course/student/assignment/commit" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"slt_hash\": \"$SLT_HASH\", \"assignment_info\": \"Enrolling in module 100\"}" \
  "assignment_submit" \
  "Student enrollment" \
  "$COURSE_ID"
ENROLL_TX=$TX_HASH

echo "Student enrolled. Commitment status: SUBMITTED."
echo ""

# ---------------------------------------------------------------------------
# TX 4: Student Updates Assignment
# ---------------------------------------------------------------------------
# Mints: nothing
# Modifies: CourseState UTxO datum (evidence grows)
# Cost: ~0.33 ADA

echo "============================================"
echo "TX 4/6: STUDENT UPDATES EVIDENCE"
echo "============================================"
echo "  Student updates assignment with evidence."
echo "  CourseState datum grows on-chain."
echo ""

do_transaction \
  "/v2/tx/course/student/assignment/update" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"assignment_info\": \"sha256:example-evidence-hash\"}" \
  "assignment_submit" \
  "Update assignment evidence" \
  "$COURSE_ID"
UPDATE_TX=$TX_HASH

echo "Assignment evidence updated."
echo ""

# ---------------------------------------------------------------------------
# TX 5: Teacher Assesses
# ---------------------------------------------------------------------------
# Mints: nothing
# Modifies: CourseState UTxO datum (assessment stored)
# Cost: ~0.27 ADA (tx fee only)

echo "============================================"
echo "TX 5/6: TEACHER ASSESSES"
echo "============================================"
echo "  Teacher grades the assignment."
echo "  Assessment decision stored on-chain."
echo ""

do_transaction \
  "/v2/tx/course/teacher/assignments/assess" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"assignment_decisions\": [{\"alias\": \"$ALIAS\", \"outcome\": \"accept\"}]}" \
  "assessment_assess" \
  "Teacher assessment" \
  "$COURSE_ID"
ASSESS_TX=$TX_HASH

echo "Assignment assessed: ACCEPTED."
echo ""

# ---------------------------------------------------------------------------
# TX 6: Student Claims Credential
# ---------------------------------------------------------------------------
# Mints: Credential NFT (to student's wallet)
# Burns: CourseState token
# Cost: -1.65 ADA (student GAINS ADA — enrollment deposit refunded)
# The credential NFT is permanent proof of completion

echo "============================================"
echo "TX 6/6: CLAIM CREDENTIAL"
echo "============================================"
echo "  Student claims credential NFT."
echo "  Burns CourseState token, refunds enrollment deposit."
echo "  Student GAINS ~1.65 ADA — credential claims are net positive."
echo ""

do_transaction \
  "/v2/tx/course/student/credential/claim" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\"}" \
  "credential_claim" \
  "Claim credential" \
  "$COURSE_ID"
CLAIM_TX=$TX_HASH

echo "Credential NFT minted to wallet. Commitment status: CREDENTIAL_CLAIMED."
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo "============================================"
echo "COURSE LIFECYCLE COMPLETE"
echo "============================================"
echo ""
echo "On-chain state created:"
echo "  Course:     $COURSE_ID"
echo "  Module:     100 (Getting Started with Andamio), slt_hash $SLT_HASH"
echo "  Credential: NFT in wallet"
echo ""
echo "Transaction history:"
echo "  1. course_create:      $COURSE_TX"
echo "  2. modules_manage:     $MODULE_TX"
echo "  3. assignment_submit:  $ENROLL_TX"
echo "  4. assignment_submit:  $UPDATE_TX"
echo "  5. assessment_assess:  $ASSESS_TX"
echo "  6. credential_claim:   $CLAIM_TX"
echo ""
echo "For project-lifecycle.sh, which needs this credential as a prerequisite:"
echo "  export COURSE_ID=$COURSE_ID"
echo "  export SLT_HASH=$SLT_HASH"
echo ""
echo "Verify on Andamioscan:"
echo "  https://andamioscan.io/courses/$COURSE_ID"
echo ""
echo "Each transaction followed the same state machine:"
echo "  build → sign → submit → register → wait(updated)"
echo ""
echo "The 'updated' state means: on-chain confirmed AND database synced."
echo "Only refetch data after 'updated' — 'confirmed' means on-chain but not synced."
echo ""
echo "============================================"
echo "IN PRACTICE: USE 'tx run'"
echo "============================================"
echo ""
echo "This script shows the 5-step state machine for learning purposes."
echo "In practice, 'andamio tx run' wraps all 5 steps into one command:"
echo ""
echo "  andamio tx run /v2/tx/instance/owner/course/create \\"
echo "    --body '{\"alias\":\"$ALIAS\",\"teachers\":[\"$ALIAS\"]}' \\"
echo "    --skey \$SKEY_PATH \\"
echo "    --tx-type course_create"
echo ""
echo "tx run handles build, sign, submit, register, and polling automatically."
echo "Progress goes to stderr. Use --output json for scripted consumption."
echo "Use --no-wait to skip confirmation polling."
