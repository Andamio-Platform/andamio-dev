---
module: 300
title: "Module 300 Assignment: Reading Andamio"
slts_covered: ["300.1", "300.2", "300.3", "300.4"]
estimated_time_min: 20
---

# Module 300 Assignment: Reading Andamio

This is the submission that earns your Module 300 credential. Module 300 was all reads — understanding the `source` field, navigating the OpenAPI spec, querying credentials, and mapping `tx_type` values to build endpoints. No on-chain transactions this time; everything you learned is about interpreting data the Andamio API already has.

As with the previous two modules, if you paused during each lesson's "Your turn," most of the assignment is in your notes already. Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 300.1 — The source field

In your own words, write two or three sentences answering: **What are the three possible values of the `source` field on an Andamio API course response, and what does each value tell you about the response's reliability?**

A strong answer names `merged`, `chain_only`, and `db_only`, and for each one says which fields you can trust (on-chain fields vs off-chain fields) and under what circumstances the state occurs.

### SLT 300.2 — Navigating the spec

Paste the path and HTTP method for the endpoint that returns the list of valid transaction types.

A correct answer: `GET /v2/tx/types`.

If you found it in under a minute, that's the skill. Report the path and method, and if you want, include one sentence about how you found it (grep, IDE search, spec viewer) so the course knows which workflow people are actually using.

### SLT 300.3 — Querying credentials

Paste the (abbreviated) output of:

```bash
andamio course student credentials list --output json
```

You can trim the output to the first course (or first two) in the response; you don't need to paste every field if you have many enrollments. For whichever course(s) you include, answer these two questions:

1. What's the `source` value, and does it match what you'd expect given your own state?
2. If the course has any modules, which ones have you claimed credentials for? (Or: confirm the `claimed_credentials` array is empty, if that's the case.)

If your `data` array is empty because you haven't enrolled in anything yet, paste the empty response and note that M100–M200 got you to the minted access token but not to an enrollment. That's fine — you'll get your first enrollment evidence in Module 500.

### SLT 300.4 — tx_type mapping

Paste the output of:

```bash
andamio tx types --output json
```

You can trim to the first five or six entries if the full list is long. From the output, answer: **What is the `tx_type` and build endpoint for the following two operations?**

1. Creating a new course.
2. A contributor committing to a project task.

Correct answers are `course_create` → `/v2/tx/instance/owner/course/create` and `project_join` → `/v2/tx/project/contributor/task/commit`.

## Part 2: Feedback

Same two prompts as previous modules. Not optional, not graded.

1. **What in Module 300 was the clearest for you? What was the muddiest?** Module 300 is reference-heavy compared to M100 and M200 — lots of field names and endpoint paths. If one of the lookups felt tedious or unclear, that's useful signal.
2. **If you had one change to make to Module 300, what would it be?** A lesson you'd rewrite, a concept you'd add, a comprehension check you'd replace. No change is too small.

If your feedback is long-form, open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link here instead.

## How to submit

**Via the Andamio app.** Paste each evidence item and feedback answer into the assignment form at `app.andamio.io/courses/{COURSE_ID}/modules/300/assignment` *(the direct link will land here once the course is published)*. Submit, and a teacher will review.

**Via the CLI.** Same caveat as the previous modules — the full mechanics of CLI assignment submission are covered in Module 500, Lesson 5.

## What happens next

Once a teacher accepts your Module 300 assignment, Module 400 unlocks and three Ops Mode skills become available: `/explore-api`, `/cli-guide`, and `/cost-estimator`. All three are shortcuts for things you just learned manually — finding endpoints in the spec, looking up CLI syntax, and estimating ADA costs. They'll feel like summaries of what you already know, not black boxes.

Three modules down. Four to go.
