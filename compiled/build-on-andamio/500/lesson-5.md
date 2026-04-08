# Run a full course lifecycle on Andamio

## Before we start

You know the structure, the hash, the publishing flow, and the commitment lifecycle. This lesson puts them together: create a course, publish a module, enroll a student, submit evidence, assess it, and claim a credential. Six on-chain transactions, one loop.

The reference for this lesson is `examples/course-lifecycle.sh` — a runnable script that executes every step below. You can read along, run the script, or run each transaction manually.

## The course.setup loop

Two transactions create the course and publish a module. This is the `course.setup` loop from `reference/tx-loops.yaml`.

### TX 1: Create the course

```bash
andamio tx run /v2/tx/instance/owner/course/create \
  --body '{"alias":"'"$ALIAS"'","teachers":["'"$ALIAS"'"]}' \
  --skey "$SKEY_PATH" \
  --tx-type course_create
```

Creates the course on-chain: mints the LocalStateNFT (whose policy ID becomes the `course_id`), LocalStateToken, and governance token. Cost: ~130 ADA (100 ADA service fee + 10 ADA per teacher + ~20 ADA in minUTxO deposits + fees).

After this reaches `updated`, discover the `course_id`:

```bash
COURSE_ID=$(andamio course list --output json \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['data'][-1]['course_id'])")
```

### TX 2: Publish a module

Three off-chain steps, then one transaction (covered in detail in M500.3):

```bash
# Off-chain: create module, approve, advance to PENDING_TX
andamio course create-module "$COURSE_ID" \
  --code 100 --title "Getting Started" \
  --slt "Learner can explain the Andamio transaction state machine" \
  --approve

andamio course teacher update-module-status \
  --course-id "$COURSE_ID" --module-code 100 --status PENDING_TX

# On-chain: mint module token
andamio tx run /v2/tx/course/teacher/modules/manage \
  --body-file modules-body.json \
  --skey "$SKEY_PATH" \
  --tx-type modules_manage \
  --instance-id "$COURSE_ID"
```

Cost: ~1.86 ADA. After `updated`, import lesson content:

```bash
andamio course import ./my-course/ --course-id "$COURSE_ID"
```

## The course.credential loop

Four transactions take a student from enrollment to credential. This is the `course.credential` loop from `reference/tx-loops.yaml`.

### TX 3: Student enrolls

```bash
# Off-chain: create commitment record (must happen before the on-chain tx)
andamio course student create \
  --course-id "$COURSE_ID" --module-code 100

# On-chain: enrollment + initial evidence
andamio tx run /v2/tx/course/student/assignment/commit \
  --body '{"alias":"'"$ALIAS"'","course_id":"'"$COURSE_ID"'","slt_hash":"'"$SLT_HASH"'","assignment_info":"Enrolling in module 100"}' \
  --skey "$SKEY_PATH" \
  --tx-type assignment_submit
```

The off-chain step is required. The on-chain transaction does not auto-create the commitment record in the database. Without it, the commitment won't appear in queries and evidence submission will fail.

Cost: ~2.14 ADA (includes ~1.45 ADA enrollment deposit, refunded at credential claim). The `assignment_info` field is the student's initial evidence (max 140 chars, stored on-chain).

After the on-chain tx confirms, submit rich evidence off-chain:

```bash
# Off-chain: submit evidence (Markdown supported)
andamio course student submit \
  --course-id "$COURSE_ID" --slt-hash "$SLT_HASH" \
  --evidence "My evidence: completed the enrollment and verified module state."
```

This transitions the commitment from AWAITING_SUBMISSION to SUBMITTED. The teacher can now see it in their review queue.

### TX 4: Student updates evidence (optional)

```bash
andamio tx run /v2/tx/course/student/assignment/update \
  --body '{"alias":"'"$ALIAS"'","course_id":"'"$COURSE_ID"'","assignment_info":"sha256:final-evidence-hash"}' \
  --skey "$SKEY_PATH" \
  --tx-type assignment_submit
```

Cost: ~0.33 ADA per update. The on-chain datum grows as evidence is added. This step is optional — the student can submit final evidence at enrollment time if they prefer.

### TX 5: Teacher assesses

```bash
andamio tx run /v2/tx/course/teacher/assignments/assess \
  --body '{"alias":"'"$ALIAS"'","course_id":"'"$COURSE_ID"'","assignment_decisions":[{"alias":"'"$ALIAS"'","outcome":"accept"}]}' \
  --skey "$SKEY_PATH" \
  --tx-type assessment_assess
```

Cost: ~0.21 ADA (teacher actually gets a small refund because the datum shrinks after grading). The `assignment_decisions` array can include multiple students in one transaction (batch assessment from M500.4).

### TX 6: Student claims credential

```bash
andamio tx run /v2/tx/course/student/credential/claim \
  --body '{"alias":"'"$ALIAS"'","course_id":"'"$COURSE_ID"'"}' \
  --skey "$SKEY_PATH" \
  --tx-type credential_claim
```

Cost: **net negative**. The student gains ~1.03 ADA because the enrollment deposit is refunded and the CourseState token is burned. A credential claim is the only transaction where the initiator ends with more ADA than they started.

The credential NFT is now in the student's wallet — permanent, portable, tied to the `slt_hash`.

## Cost summary

The `course.credential` loop costs ~1.32 ADA total (student: ~1.11 ADA net; teacher: ~0.21 ADA). For a cohort of N students, the cost scales linearly: ~1.32 ADA × N.

The `course.setup` loop costs ~132 ADA for a one-module course. Setup is a one-time cost; the credential loop runs per student per module.

| Transaction | Paid by | Cost |
|-------------|---------|------|
| `course_create` | Owner | ~130 ADA |
| `modules_manage` | Teacher | ~1.86 ADA |
| `assignment_submit` | Student | ~2.14 ADA |
| `assignment_update` | Student | ~0.33 ADA (optional, per update) |
| `assessment_assess` | Teacher | ~0.21 ADA |
| `credential_claim` | Student | -1.03 ADA (refund) |

## Running the example script

The bundled example executes all six transactions end to end:

```bash
export SKEY_PATH=/path/to/payment.skey
./examples/course-lifecycle.sh
```

The script uses the same five-step state machine helper for every transaction. Each step logs its progress. At the end, it prints the course ID, all transaction hashes, and a link to verify on-chain.

## Your turn

Run the full course lifecycle — either via `examples/course-lifecycle.sh` or by executing the six transactions manually. Paste the `credential_claim` transaction hash (the final TX in the loop).

If you're running on a wallet with limited test ADA, the setup loop alone costs ~132 ADA. Hit the faucet for at least 150 test ADA before starting.

## Rubric

A valid `credential_claim` hash is a 64-character hex string. Verify with `andamio tx status <hash>` — state should be `updated`, `tx_type` should be `credential_claim`. If you ran the full script, you should also see a credential NFT in your wallet when you check your address on [preprod.cardanoscan.io](https://preprod.cardanoscan.io).

## What you just did

You ran a complete course lifecycle on Andamio: created a course, published a module, enrolled a student, submitted evidence, assessed it, and claimed a credential NFT. Every transaction went through the five-step state machine from M400. The credential in your wallet is tied to a specific `slt_hash`, verifiable by anyone who knows the SLT text.

This is the `course.credential` loop — the real-world pattern that runs every time a student earns a credential on Andamio. The course you're taking right now follows the same loop.

You also unlocked `/course-ops` in Ops Mode. That skill wraps the operations from this module into a reach-for-it tool — because you walked through each step, it's a summary, not a black box.
