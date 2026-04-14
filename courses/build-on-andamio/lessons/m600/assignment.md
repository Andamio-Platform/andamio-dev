---
module: 600
title: "Module 600 Assignment: Projects End-to-End"
slts_covered: ["600.1", "600.2", "600.3", "600.4"]
estimated_time_min: 20
---

# Module 600 Assignment: Projects End-to-End

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 600.1 — How projects differ from courses

Query the project you created in M600.4:

```bash
andamio project show <project-id> --output json
```

Paste the output. From it, identify: `project_id`, `contributor_state_id`, and treasury balance.

### SLT 600.2 — Compute a task_hash

Compute the hash for the task you created, then verify it matches the on-chain task:

```bash
andamio project task compute-hash \
  --content "<your task content>" \
  --lovelace <reward> \
  --expiration <date> \
  --output json

andamio project task list <project-id> --output json
```

Paste both outputs.

### SLT 600.3 — The commitment lifecycle

Verify the manager's assessment transaction from the project lifecycle:

```bash
andamio tx status <task_assess_hash> --output json
```

Paste the hash and the status output.

### SLT 600.4 — Run the full lifecycle

Verify the credential claim and confirm the credential landed:

```bash
andamio tx status <project_credential_claim_hash> --output json
andamio course student credentials list --output json
```

Paste both outputs.

## Part 2: Feedback

Not optional. Feedback is how this course improves.

1. **What was the clearest? What was the muddiest?**
2. **One change you'd make to Module 600?**

Detailed feedback → open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link.

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/600/assignment`

**CLI:**

```bash
andamio course student commitment create \
  --course-id "{COURSE_ID}" --module-code 600

andamio tx run /v2/tx/course/student/assignment/commit \
  --body '{"alias":"YOUR_ALIAS","course_id":"{COURSE_ID}","slt_hash":"MODULE_600_HASH","assignment_info":"YOUR_EVIDENCE"}' \
  --skey "$SKEY_PATH" \
  --tx-type assignment_submit
```

## What happens next

Accepted → Module 700 unlocks, `/project-ops` Ops skill available. Six down, one to go.
