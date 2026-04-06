---
module: 400
title: "Module 400 Assignment: The Transaction State Machine"
slts_covered: ["400.1", "400.2", "400.3", "400.4", "400.5"]
estimated_time_min: 25
---

# Module 400 Assignment: The Transaction State Machine

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 400.1 — The five steps

Run a transaction through the manual five-step path (not `tx run`):

```bash
andamio tx build <endpoint> --body '<json>' --output json
andamio tx sign --tx <unsigned_tx> --skey ./payment.skey --output json
andamio tx submit --tx <signed_tx> --output json
andamio tx register --tx-hash <hash> --tx-type <type>
andamio tx status <hash> --output json
```

Paste all five outputs.

### SLT 400.2 — Why `updated` is safe

From your `tx status` output above, note the time gap between `confirmed_at` and `updated_at`. Paste the two timestamps.

### SLT 400.3 — Execute through the state machine

Covered by 400.1 above. If you used `tx run` instead of the manual path, paste:

```bash
andamio tx status <hash> --output json
```

showing `state: updated`.

### SLT 400.4 — Diagnose TX failures

Trigger a build error:

```bash
andamio tx build /v2/tx/global/user/access-token/mint \
  --body '{"invalid": "data"}' --output json 2>&1
```

Paste the error output.

### SLT 400.5 — Commitment state expiry

If you have a transaction that reached `expired` or `failed`, paste its `tx status` output — that's the most interesting evidence. Otherwise, the `updated` status from 400.1 covers this.

## Part 2: Feedback

Not optional. Feedback is how this course improves.

1. **What was the clearest? What was the muddiest?**
2. **One change you'd make to Module 400?**

Detailed feedback → open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link.

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/400/assignment`

**CLI:** Submission mechanics covered in M500.5.

## What happens next

Accepted → Module 500 unlocks, `/troubleshoot` Ops skill available. Four down, three to go.
