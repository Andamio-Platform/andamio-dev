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
# Prerequisites:
#   - andamio CLI installed (brew install andamio-platform/tap/andamio)
#   - API key configured (andamio auth login --api-key <key>)
#   - Wallet JWT active (andamio user login)
#   - A Cardano .skey file for signing (preprod)
#   - Test ADA from the faucet (https://docs.cardano.org/cardano-testnets/tools/faucet/)
#
# Usage:
#   export SKEY_PATH=/path/to/payment.skey
#   ./course-lifecycle.sh
#
# Cost breakdown (preprod, all in test ADA):
#   Create course (1 teacher):  ~130 ADA
#   Add 1 module:               ~1.86 ADA
#   Student enroll:             ~2.14 ADA
#   Student update:             ~0.33 ADA
#   Teacher assess:             ~0.21 ADA
#   Student claim credential:   -1.03 ADA (refund)
#   ---
#   Total loop:                 ~133.51 ADA

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SKEY_PATH="${SKEY_PATH:?Set SKEY_PATH to your payment.skey file}"
POLL_INTERVAL=5     # seconds between tx status checks
POLL_TIMEOUT=120    # max seconds to wait for confirmation

# Read config from CLI
BASE_URL=$(andamio config show --output json 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('base_url','https://preprod.api.andamio.io'))" 2>/dev/null || echo "https://preprod.api.andamio.io")
ALIAS=$(andamio user me --output json | python3 -c "import json,sys; print(json.load(sys.stdin)['alias'])")

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
#
# Returns: tx_hash via stdout (last line)

do_transaction() {
  local endpoint="$1"
  local body="$2"
  local tx_type="$3"
  local desc="$4"

  echo "--- Step: $desc ---"

  # 1. BUILD — request unsigned transaction
  echo "  [1/5] Building transaction..."
  local build_result
  build_result=$(andamio tx build "$endpoint" --body "$body" --output json)
  local unsigned_tx
  unsigned_tx=$(echo "$build_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['unsigned_tx'])")
  echo "  [1/5] Built. Unsigned tx: ${unsigned_tx:0:20}..."

  # 2. SIGN — sign with local .skey
  echo "  [2/5] Signing transaction..."
  local sign_result
  sign_result=$(andamio tx sign --tx "$unsigned_tx" --skey "$SKEY_PATH" --output json)
  local signed_tx
  signed_tx=$(echo "$sign_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['tx_hex'])")
  echo "  [2/5] Signed."

  # 3. SUBMIT — send to Cardano network
  echo "  [3/5] Submitting to Cardano..."
  local submit_result
  submit_result=$(andamio tx submit --tx "$signed_tx" --output json)
  local tx_hash
  tx_hash=$(echo "$submit_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['tx_hash'])")
  echo "  [3/5] Submitted. TX hash: $tx_hash"

  # 4. REGISTER — tell Andamio to track this transaction
  echo "  [4/5] Registering for tracking..."
  andamio tx register --tx-hash "$tx_hash" --tx-type "$tx_type" >/dev/null 2>&1
  echo "  [4/5] Registered as $tx_type."

  # 5. WAIT — poll until status is "updated" (DB synced)
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
# TX 1: Create Course
# ---------------------------------------------------------------------------
# Mints: LocalStateNFT + LocalStateToken + Governance
# Creates: 3 validator UTxOs
# Cost: ~130 ADA (100 service + 19 min UTXO + 0.55 tx fee)
# The LocalStateNFT policy ID becomes the course_id

echo "============================================"
echo "TX 1/6: CREATE COURSE"
echo "============================================"
echo "  Mints 3 tokens, creates 3 on-chain UTxOs."
echo "  The course_id = LocalStateNFT policy ID."
echo ""

COURSE_TX=$(do_transaction \
  "/v2/tx/instance/owner/course/create" \
  "{\"alias\": \"$ALIAS\", \"teachers\": [\"$ALIAS\"]}" \
  "course_create" \
  "Create course")

# Discover the course_id from the newly created course
echo "Discovering course_id..."
COURSE_ID=$(andamio course list --output json | python3 -c "
import json, sys
courses = json.load(sys.stdin)['data']
# Most recently created course (last in list or match by alias)
print(courses[-1]['course_id'])
")
echo "Course ID: $COURSE_ID"
echo ""

# ---------------------------------------------------------------------------
# TX 2: Add Module
# ---------------------------------------------------------------------------
# Mints: Module token
# Creates: Module validator UTxO
# Cost: ~1.86 ADA (0 service fee + 1.59 min UTXO + 0.27 tx fee)
# Module status starts as DRAFT

echo "============================================"
echo "TX 2/6: ADD MODULE"
echo "============================================"
echo "  Mints module token, creates module UTxO."
echo "  Module starts in DRAFT status (SLTs editable)."
echo ""

# Define the Student Learning Targets for this module.
# The slt_hash is derived from this exact list — same SLTs in, same hash out.
SLT_1="Learner can explain the Andamio transaction state machine"

# Compute the slt_hash locally so we can reference the same module both on-chain
# (via the TX body) and later from the student's enrollment TX.
SLT_HASH=$(andamio course credential compute-hash --slt "$SLT_1" --output json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['slt_hash'])")
echo "Computed slt_hash: $SLT_HASH"

# Create the module shell off-chain (DB record with the SLTs).
# This must exist in PENDING_TX status before modules_manage confirms so the
# gateway's batch confirm can match the on-chain token to a DB row.
andamio course create-module "$COURSE_ID" \
  --code 100 \
  --title "Getting Started with Andamio" \
  --slt "$SLT_1" \
  --sort-order 1 >/dev/null 2>&1

# The module manage TX mints the module token on-chain.
# Body shape (per PROTOCOL.md §6.1): modules_to_add, modules_to_update,
# and modules_to_remove are ALL required arrays even when empty.
# `module_code` is off-chain only and never appears in TX bodies.
MODULE_TX=$(do_transaction \
  "/v2/tx/course/teacher/modules/manage" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"modules_to_add\": [{\"slts\": [\"$SLT_1\"], \"allowed_student_state_ids\": [], \"prereq_slt_hashes\": []}], \"modules_to_update\": [], \"modules_to_remove\": []}" \
  "modules_manage" \
  "Add module 100")

echo "Module 100 minted on-chain (slt_hash: $SLT_HASH)."
echo ""

# ---------------------------------------------------------------------------
# TX 3: Student Enrolls (Assignment Commit)
# ---------------------------------------------------------------------------
# Mints: CourseState token (on first enrollment)
# Creates: CourseState validator UTxO
# Cost: ~2.14 ADA (0 service + 1.74 min UTXO + 0.40 tx fee)
# Locks enrollment deposit (~1.45 ADA, refunded on credential claim)

echo "============================================"
echo "TX 3/6: STUDENT ENROLLS"
echo "============================================"
echo "  Student commits to an assignment."
echo "  Mints CourseState token, locks enrollment deposit."
echo "  Deposit is refunded when credential is claimed."
echo ""

# First create a draft commitment (off-chain)
andamio course student commitment create \
  --course-id "$COURSE_ID" \
  --module-code 100 >/dev/null 2>&1 || true

ENROLL_TX=$(do_transaction \
  "/v2/tx/course/student/assignment/commit" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"slt_hash\": \"$SLT_HASH\", \"assignment_info\": \"Enrolling in module 100\"}" \
  "assignment_submit" \
  "Student enrollment")

echo "Student enrolled in course."
echo ""

# ---------------------------------------------------------------------------
# TX 4: Student Updates Assignment
# ---------------------------------------------------------------------------
# Mints: nothing
# Modifies: CourseState UTxO datum (evidence grows)
# Cost: ~0.33 ADA (0 service + 0.05 min UTXO delta + 0.28 tx fee)
# The datum expands as evidence is added

echo "============================================"
echo "TX 4/6: STUDENT SUBMITS EVIDENCE"
echo "============================================"
echo "  Student updates assignment with evidence."
echo "  CourseState datum grows on-chain."
echo ""

UPDATE_TX=$(do_transaction \
  "/v2/tx/course/student/assignment/update" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"assignment_info\": \"sha256:example-evidence-hash\"}" \
  "assignment_submit" \
  "Submit assignment evidence")

echo "Assignment evidence submitted."
echo ""

# ---------------------------------------------------------------------------
# TX 5: Teacher Assesses
# ---------------------------------------------------------------------------
# Mints: nothing
# Modifies: CourseState UTxO datum (assessment stored)
# Cost: ~0.21 ADA (0 service - 0.07 refund + 0.28 tx fee)
# Teacher actually gets a small refund (datum shrinks after grading)

echo "============================================"
echo "TX 5/6: TEACHER ASSESSES"
echo "============================================"
echo "  Teacher grades the assignment."
echo "  Assessment decision stored on-chain."
echo "  Teacher gets a small ADA refund (datum shrinks)."
echo ""

ASSESS_TX=$(do_transaction \
  "/v2/tx/course/teacher/assignments/assess" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\", \"assignment_decisions\": [{\"alias\": \"$ALIAS\", \"outcome\": \"accept\"}]}" \
  "assessment_assess" \
  "Teacher assessment")

echo "Assignment assessed: ACCEPT."
echo ""

# ---------------------------------------------------------------------------
# TX 6: Student Claims Credential
# ---------------------------------------------------------------------------
# Mints: Credential NFT (to student's wallet)
# Burns: CourseState token
# Cost: -1.03 ADA (student GAINS ADA — enrollment deposit refunded)
# The credential NFT is permanent proof of completion

echo "============================================"
echo "TX 6/6: CLAIM CREDENTIAL"
echo "============================================"
echo "  Student claims credential NFT."
echo "  Burns CourseState token, refunds enrollment deposit."
echo "  Student GAINS ~1.03 ADA — credential claims are net positive."
echo ""

CLAIM_TX=$(do_transaction \
  "/v2/tx/course/student/credential/claim" \
  "{\"alias\": \"$ALIAS\", \"course_id\": \"$COURSE_ID\"}" \
  "credential_claim" \
  "Claim credential")

echo "Credential NFT minted to wallet."
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
echo "  Module:     100 (Getting Started with Andamio)"
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
