---
module: 100
title: "Module 100 Assignment: Foundations"
slts_covered: ["100.1", "100.2", "100.3", "100.4"]
estimated_time_min: 20
---

# Module 100 Assignment: Foundations

This is the submission that earns your Module 100 credential. It consolidates the four lessons of Module 100 into a single artifact a teacher will read and either accept or ask you to revise.

Nothing here is new work. If you paused to think during each lesson's "Your turn" section, most of this assignment is already in your notes — the assignment just asks you to paste your answers into one place.

The assignment has two parts: evidence for each of the four SLTs, and feedback on the module itself. Both parts are required.

## Part 1: Evidence

### SLT 100.1 — Contribution-centered learning

In your own words, write one paragraph answering this question: **What does contribution-centered learning mean, and why did Andamio choose it over completion-centered or test-gated models?**

A strong answer names the three models, identifies what the first two fail to measure, and states what contribution-centered learning measures instead. Three to six sentences is about right. If you wrote your answer during M100.1's self-check, paste it here; if not, write it now.

### SLT 100.2 — Install the Andamio CLI

Paste the output of:

```bash
andamio --version
```

One line. The version string is the evidence.

### SLT 100.3 — Fund a preprod wallet from the faucet

Two items:

1. The preprod address you funded (starts with `addr_test1`).
2. One of: the transaction hash the faucet returned, or a [preprod.cardanoscan.io](https://preprod.cardanoscan.io) link to your address showing a nonzero balance.

Either form of the second item is sufficient. Both prove the wallet is funded. Pick whichever is easier.

### SLT 100.4 — Learning Mode vs Ops Mode

In one or two sentences, explain why Ops Mode skills are gated behind Learning Mode modules. Name the relationship between understanding and ownership.

If you did the mapping exercise in M100.4's "Your turn" and one of the four scenarios felt genuinely ambiguous, mention it here. Edge cases are useful information even when they don't have clean answers.

## Part 2: Feedback

This section is not optional, and it's not graded. It's where you tell the course what worked for you and what didn't.

Two open prompts:

1. **What in Module 100 was the clearest for you? What was the muddiest?** Point at specific sentences, sections, or concepts if you can. "The whole thing was fine" is a valid answer, but a more specific one helps the course improve faster.
2. **If you had one change to make to Module 100, what would it be?** Anything goes. A lesson you'd rewrite. A concept you'd add. A comprehension check you'd replace. A typo you noticed. No change is too small.

If you find yourself writing something longer than this section has room for, open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link in your feedback instead. Long-form feedback on the course is itself a valid contribution under the same model the course teaches — which means it's the kind of work that earns credentials in other Andamio courses.

## How to submit

Two options depending on how you're working through the course.

**Via the Andamio app.** Paste each evidence item and feedback answer into the assignment form at `app.andamio.io/courses/{COURSE_ID}/modules/100/assignment` *(the direct link will land here once the course is published)*. Submit, and a teacher will review.

**Via the CLI.** The `andamio` CLI can orchestrate the submission end-to-end. The full mechanics of a course assignment submission — building, signing, submitting, and tracking the on-chain transaction — are covered in Module 500, Lesson 5. For your first assignment, the Andamio app path is the simpler choice. If you want the terminal path anyway, run `andamio course student --help` to see the current subcommand options.

## What happens next

Once you submit, a teacher reviews your assignment. If they accept it, Module 100's SLTs are marked complete in your progress file and Module 200 unlocks for you. If they ask for revision, you'll see their comments and can resubmit — that's the `refuse → resubmit` loop you'll learn about formally in Module 500.

Either way, you've earned your first credential toward the full "Build on Andamio" course credential. Welcome to contribution-centered learning from the inside.
