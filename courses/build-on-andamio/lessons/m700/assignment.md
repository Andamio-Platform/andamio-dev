---
module: 700
title: "Module 700 Assignment: Build Something Real"
slts_covered: ["700.1", "700.2", "700.3", "700.4", "700.5"]
estimated_time_min: 25
---

# Module 700 Assignment: Build Something Real

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 700.1 — Choose the right integration strategy

One sentence: which strategy you chose (template, direct API, or CLI-first) and why.

### SLT 700.2 — Estimate the ADA cost of a user flow

Pick a scenario. Show the formula, the numbers, and which `tx-loops.yaml` loops you used. Break down setup cost vs per-participant cost.

### SLT 700.3 — Handle TX failure modes in code

Paste the failure-handling code from your integration (any language). Must cover at least two of the five failure modes.

### SLT 700.4 — Ship a minimal working integration

Link to your integration (repo, gist, or paste). One sentence on what it does, one on how to run it.

Must: authenticate with the Andamio API, perform at least one interaction, handle at least one failure.

### SLT 700.5 — Critique the Andamio developer experience

Open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) with your critique. Be specific — name modules, endpoints, commands, or errors. Paste the issue link.

## Part 2: Feedback

Not optional. Feedback is how this course improves.

1. **What was the clearest — in Module 700 or the entire course? What was the muddiest?**
2. **One change you'd make?**

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/700/assignment`

**CLI:**

```bash
andamio course student commitment create \
  --course-id "{COURSE_ID}" --module-code 700

andamio tx run /v2/tx/course/student/assignment/commit \
  --body '{"alias":"YOUR_ALIAS","course_id":"{COURSE_ID}","slt_hash":"MODULE_700_HASH","assignment_info":"YOUR_EVIDENCE"}' \
  --skey "$SKEY_PATH" \
  --tx-type assignment_submit
```

## What happens next

Seven credentials, each tied to a specific `slt_hash`, each verifiable on-chain. `/compound` Ops skill unlocks.

A credential should prove you did the work. You did.
