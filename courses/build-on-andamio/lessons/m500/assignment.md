---
module: 500
title: "Module 500 Assignment: Courses End-to-End"
slts_covered: ["500.1", "500.2", "500.3", "500.4", "500.5"]
estimated_time_min: 25
---

# Module 500 Assignment: Courses End-to-End

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 500.1 — How courses are structured

Query the course you created in M500.5:

```bash
andamio course show <course-id> --output json
```

Paste the output. From it, identify one module's credential address: `<course_id>.<slt_hash>`.

### SLT 500.2 — Compute an slt_hash

Compute the `slt_hash` for Module 500 — the module you're completing:

```bash
andamio course credential compute-hash \
  --slt "I can explain how Andamio courses are structured." \
  --slt "I can compute an slt_hash for a course module." \
  --slt "I can publish a course module on-chain." \
  --slt "I can explain the course assignment commitment lifecycle." \
  --slt "I can run a full course lifecycle on Andamio." \
  --output json
```

Paste the output.

### SLT 500.3 — Publish a course module on-chain

Verify your `modules_manage` transaction from the course lifecycle:

```bash
andamio tx status <modules_manage_hash> --output json
```

Paste the hash and the status output.

### SLT 500.4 — The commitment lifecycle

Verify the teacher's assessment transaction from the course lifecycle:

```bash
andamio tx status <assessment_assess_hash> --output json
```

Paste the hash and the status output.

### SLT 500.5 — Run the full lifecycle

Verify the credential claim and confirm the credential landed. You ran the lifecycle as the course's teacher, so the teacher view shows your own commitment:

```bash
andamio tx status <credential_claim_hash> --output json
andamio teacher assignments list --course <COURSE_ID> --output json
```

Paste both outputs. Your row's `content.commitment_status` should read `CREDENTIAL_CLAIMED`.

## Part 2: Feedback

Not optional. Feedback is how this course improves.

1. **What was the clearest? What was the muddiest?**
2. **One change you'd make to Module 500?**

Detailed feedback → open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link.

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/500/assignment`

**CLI:**

The `assignment_submit` transaction enrolls you and creates your commitment when it confirms — there is no separate create step.

```bash
andamio tx run /v2/tx/course/student/assignment/commit \
  --body '{"alias":"YOUR_ALIAS","course_id":"{COURSE_ID}","slt_hash":"MODULE_500_HASH","assignment_info":"YOUR_EVIDENCE"}' \
  --skey "$SKEY_PATH" \
  --tx-type assignment_submit
```

## What happens next

Accepted → Module 600 unlocks, `/course-ops` Ops skill available. Five down, two to go.
