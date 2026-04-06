---
module: 400
title: "Module 400 Assignment: The Transaction State Machine"
slts_covered: ["400.1", "400.2", "400.3", "400.4", "400.5"]
estimated_time_min: 25
---

# Module 400 Assignment: The Transaction State Machine

This is the submission that earns your Module 400 credential. Module 400 covered Andamio's transaction lifecycle end to end: the five steps every write goes through, the five statuses you can see in `tx status`, the five failure modes, and the two commitment states that require manual handling on expiry.

Module 400 is reference-heavy. Most of this assignment is you writing down what you learned so the submission itself is a study guide you'll come back to whenever you hit a TX problem in Module 500, 600, or 700.

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 400.1 — The five steps

Write the five steps of the Andamio TX state machine in order, and for each one write a single sentence describing what happens. Don't paraphrase the lesson directly — use your own words. A good answer names **build, sign, submit, register, wait** in order, and each sentence captures both *what the step does* and *where it happens* (local machine, Andamio API, Cardano network).

Also answer in one sentence: **In which step is your private key used, and why does this matter?**

### SLT 400.2 — Why `updated` is safe

Write the bug scenario from M400.2 in your own words, as if you're explaining it to a teammate who's new to Andamio. A strong answer names:

1. What state the naive code waits for (`confirmed`).
2. What the gap between `confirmed` and `updated` actually is (the Andamio API's off-chain sync).
3. Why the bug is intermittent rather than consistent.
4. The one-line fix.

Two or three paragraphs is about right.

### SLT 400.3 — Execute through the state machine

Paste the output of:

```bash
andamio tx status <your-access-token-mint-hash>
```

Where `<your-access-token-mint-hash>` is the transaction hash from your M200.1 mint. If you didn't save it, find it by searching your wallet address on [preprod.cardanoscan.io](https://preprod.cardanoscan.io) and looking for the access token mint transaction.

With the output in hand, answer these three questions:

1. What `state` is the transaction in?
2. How many seconds passed between `created_at` and `confirmed_at`?
3. How many seconds passed between `confirmed_at` and `updated_at`?

### SLT 400.4 — Diagnose TX failures

For each of the following scenarios, name the failure mode and describe what the developer should do. A good answer names one of **build error, sign error, submit rejection, chain expiry, off-chain sync failure**, and the response should match the diagnostic workflow from M400.4.

1. A `tx run` command fails with `Error: failed to build transaction: 400 Bad Request: {"error": "insufficient funds"}`.
2. A `tx status` response shows `state: failed`, `failure_reason: TASK_NOT_FOUND`, `confirmed_at: 2026-04-05T12:00:30Z`.
3. A `tx status` response shows `state: expired`, `confirmed_at: null`, `not_indexed_count: 72`.

### SLT 400.5 — Commitment state expiry

In one or two sentences, name the two pending states that do NOT revert on TX expiry, and explain why. A strong answer identifies `PENDING_TX_COMMIT` and `PENDING_TX_LEAVE` and captures the reason for each: COMMIT doesn't revert because there's no pre-transaction state to revert to, and LEAVE doesn't revert because reverting would undo an intentional user decision.

## Part 2: Feedback

Same two prompts as previous modules. Not optional, not graded.

1. **What in Module 400 was the clearest for you? What was the muddiest?** Module 400 is heavier on protocol mechanics than the earlier modules — five lessons about state machines and failure modes can feel dense. The muddy bits are especially valuable feedback because they're the parts where you'd get stuck under pressure.
2. **If you had one change to make to Module 400, what would it be?** A lesson you'd rewrite, a concept you'd add, a comprehension check you'd replace, a diagnostic workflow you'd expand. No change is too small.

If your feedback is long-form, open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link here instead.

## How to submit

**Via the Andamio App.** Paste each evidence item and feedback answer into the assignment form at `app.andamio.io/courses/{COURSE_ID}/modules/400/assignment` *(the direct link will land here once the course is published)*. Submit, and a teacher will review.

**Via the CLI.** Same caveat as previous modules — full CLI submission mechanics are covered in Module 500, Lesson 5. For Module 400, the Andamio App path is simpler.

## What happens next

Once a teacher accepts your Module 400 assignment, Module 500 unlocks and the `/troubleshoot` Ops Mode skill becomes available. That skill is the Ops Mode shortcut for the diagnostic workflow you just learned in M400.4 and M400.5 — it wraps the "look at `tx status`, identify the failure mode, take the right action" loop into a reach-for-it tool. Because you walked through the diagnosis manually, `/troubleshoot` will feel like a summary of what you already know, not a black box.

Module 500 is where the course starts to feel like real work. You'll create an actual course on preprod, add modules to it, walk a student through enrollment, submit evidence, assess it, and claim a credential. Every transaction in that loop goes through the five-step state machine you just mastered, and every failure mode you just learned about will be something you can recognize immediately if it happens.

Four modules down, three to go.
