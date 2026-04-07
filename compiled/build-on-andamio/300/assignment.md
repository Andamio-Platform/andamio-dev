# Module 300 Assignment: Reading Andamio

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 300.1 — The source field

Pick any course:

```bash
andamio course list --output json
```

Paste the course's `course_id`, `source` value, and one module's `slt_hash`. If you have the SLT text, verify the hash:

```bash
andamio course credential compute-hash --slt "..." --slt "..." --output json
```

Paste both the computed hash and the on-chain `slt_hash`. Do they match?

### SLT 300.2 — Navigating the spec

Find the endpoint that lists a project's tasks. Paste the HTTP method, path, and how you found it (grep command, search query, or spec viewer).

### SLT 300.3 — Querying credentials

Query your credentials:

```bash
andamio course student credentials list --output json
```

Paste the output (trim to the first course if long). Empty `data` array is fine — you'll have enrollment evidence by M500.

### SLT 300.4 — tx_type mapping

List the available transaction types:

```bash
andamio tx types --output json
```

Paste any five entries. From the full output, find the `tx_type` and build endpoint for: (1) creating a course, (2) a student submitting evidence. Paste both mappings.

## Part 2: Feedback

Not optional. Feedback is how this course improves.

1. **What was the clearest? What was the muddiest?**
2. **One change you'd make to Module 300?**

Detailed feedback → open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link.

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/300/assignment`

**CLI:** Submission mechanics covered in M500.5.

## What happens next

Accepted → Module 400 unlocks, `/explore-api`, `/cli-guide`, `/cost-estimator` available. Three down, four to go.
