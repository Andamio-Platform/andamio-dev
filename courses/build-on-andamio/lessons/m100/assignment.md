---
module: 100
title: "Module 100 Assignment: Foundations"
slts_covered: ["100.1", "100.2", "100.3", "100.4"]
estimated_time_min: 20
---

# Module 100 Assignment: Foundations

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 100.1 — Contribution-centered learning

Compute the `slt_hash` for Module 100:

```bash
andamio course credential compute-hash \
  --slt "I can explain Andamio's contribution-centered learning model." \
  --slt "I can install and configure the Andamio CLI." \
  --slt "I can fund a preprod wallet from the Cardano testnet faucet." \
  --slt "I can distinguish Learning Mode from Ops Mode in this plugin." \
  --output json
```

Paste the output.

### SLT 100.2 — Install the Andamio CLI

Verify the CLI is installed:

```bash
andamio --version
```

Paste the output.

### SLT 100.3 — Fund a preprod wallet

Fund a wallet from the Cardano preprod faucet. Provide:

1. Your preprod address (starts with `addr_test1`).
2. A [preprod.cardanoscan.io](https://preprod.cardanoscan.io) link showing a nonzero balance, or the faucet transaction hash.

### SLT 100.4 — Learning Mode and Ops Mode

Confirm your CLI is configured and pointed at preprod:

```bash
andamio config show --output json
```

Paste the output.

## Part 2: Feedback

Not optional. Feedback is how this course improves — every student who submits it contributes to the next version.

1. **What was the clearest? What was the muddiest?**
2. **One change you'd make to Module 100?**

Detailed feedback → open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link.

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/100/assignment`

**CLI:** Submission mechanics covered in M500.5. For your first assignment, the App is simpler.

## What happens next

Accepted → Module 200 unlocks. Refused → revise and resubmit.
