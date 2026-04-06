---
module: 200
title: "Module 200 Assignment: Identity"
slts_covered: ["200.1", "200.2", "200.3", "200.4"]
estimated_time_min: 20
---

# Module 200 Assignment: Identity

This is the submission that earns your Module 200 credential. Module 200 covered the full identity picture for Andamio: minting your on-chain alias, distinguishing the three credential shapes, getting a User JWT without a browser, and verifying identity claims offline for third parties.

As with M100, nothing here is new work. If you paused during each lesson's "Your turn" and wrote your answers down, most of this assignment is already in your notes. Plus one or two items you actually produced on the protocol — the mint transaction hash, the login status output. Two parts: evidence and feedback. Both required.

## Part 1: Evidence

### SLT 200.1 — Mint your access token

Four items:

1. **Why writes need an access token.** One or two sentences answering: *Why can't Andamio issue aliases from a database, the way every other platform does?* A strong answer names at least one of portability, verifiability, composability, or independence from the institution.
2. The alias you chose and minted.
3. The transaction hash of your access-token mint (visible at the end of the `andamio tx run` output, and in your terminal history).
4. A link to your wallet address on [preprod.cardanoscan.io](https://preprod.cardanoscan.io) showing the Andamio access token in the assets list.

### SLT 200.2 — API keys vs User JWTs

In one or two sentences, explain the core distinction: **what does an API key represent, and what does a User JWT represent?**

A strong answer captures the "asking vs acting" distinction: the API key identifies the developer sending the request; the User JWT identifies the alias acting on the protocol.

### SLT 200.3 — Headless login

Paste the output of:

```bash
andamio user status
```

This shows whether you have a valid JWT and when it expires. Any non-error output is evidence that the login succeeded.

### SLT 200.4 — Attestation JWTs

In one or two sentences, answer: **What is the one use case Attestation JWTs are designed for, and why wouldn't you use a User JWT for that use case?**

A strong answer names the third-party verification use case specifically and distinguishes it from the in-app User JWT flow.

## Part 2: Feedback

Same two prompts as Module 100. Not optional, not graded.

1. **What in Module 200 was the clearest for you? What was the muddiest?** Point at specific sentences, sections, or concepts if you can. Module 200 is technically heavier than Module 100 — more commands, more specific claim shapes, more places where a shallow reading could leave you confused later. The muddier bits are the most valuable feedback.
2. **If you had one change to make to Module 200, what would it be?** A lesson you'd rewrite, a concept you'd add, a comprehension check you'd replace, a typo you noticed. No change is too small.

If your feedback is long-form, open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link here instead.

## How to submit

**Via the Andamio app.** Paste each evidence item and feedback answer into the assignment form at `app.andamio.io/courses/{COURSE_ID}/modules/200/assignment` *(the direct link will land here once the course is published)*. Submit, and a teacher will review.

**Via the CLI.** Same caveat as M100's assignment — the full mechanics of CLI assignment submission are covered in Module 500, Lesson 5. For Module 200, the Andamio app path is the simpler choice unless you already know the CLI submission surface.

## What happens next

Once a teacher accepts your Module 200 assignment, Module 300 unlocks and the `/auth-setup` Ops Mode skill becomes available in your plugin — that skill is the Ops Mode shortcut for the auth flows you just learned. Everything `/auth-setup` does is something you just walked through manually, which means it isn't a black box when you reach for it.

Two modules down, five to go.
