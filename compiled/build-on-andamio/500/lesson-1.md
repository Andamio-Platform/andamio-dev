# How Andamio courses are structured

## Before we start

Module 400 taught you the transaction state machine — one transaction at a time. Module 500 is where those transactions compose into something larger: a full course on Andamio. This lesson explains the structure before you start building one.

## Three layers

An Andamio course has three layers. Each exists for a different reason.

| Layer | What it is | Where it lives | Who creates it |
|-------|-----------|----------------|----------------|
| **Course** | The container. Has an owner, teachers, and a policy ID that becomes the `course_id`. | On-chain (minted as LocalStateNFT) | Owner |
| **Module** | A unit of credentialed learning. Has a code (100, 200, ...), a title, and a set of SLTs. | On-chain (minted as module token) + off-chain (lesson content, assignment) | Teacher |
| **SLT** | A student learning target — one sentence describing a capability. | Encoded into the module's `slt_hash` on-chain; readable text lives off-chain | Teacher |

The course is the identity. The modules are the credentialable units. The SLTs are the criteria for each credential.

## Every credential has an on-chain address

Every Andamio credential has a unique on-chain identifier built from two parts:

```
<course_id>.<slt_hash>
```

The `course_id` is the policy ID minted when the course is created. The `slt_hash` is the hash of the module's SLT text. Together they form an address on the blockchain — a permanent, verifiable reference to "this credential, on this course, proving these specific capabilities."

The owner of a `course_id` assigns zero or more teachers who can create credentials on that course. Every credential minted under that `course_id` is scoped to the owner's authority and the teacher's assessment.

## On-chain vs off-chain

Not everything lives on the blockchain. The split matters because it determines what's permanent, what's verifiable, and what's editable.

**On-chain (immutable once minted):**
- Course existence and `course_id`
- Module existence and `slt_hash`
- Teacher and owner roles
- Student enrollment records, assessment decisions, credentials
- Commitment hashes (the hash of evidence a student submitted)

**Off-chain (can live anywhere):**
- Module title and description
- Lesson content (the prose you're reading now)
- Assignment prompts and rubrics
- Student draft commitments (before the enrollment TX)
- The actual evidence a student submitted

The off-chain data can live anywhere. In the Andamio API, for convenience, it lives in a database. But it doesn't have to — any system that stores lesson content and student commitments works, as long as the on-chain hashes remain verifiable.

And they always are. Anyone who knows the SLT text can recompute the `slt_hash` and verify it matches the on-chain module. Anyone who has the submitted evidence can recompute the commitment hash and verify it matches what was assessed. The chain doesn't store the content — it stores the proof that the content is what it claims to be. M500.2 covers this computation.

## Why modules exist separately from the course

A course with five modules produces five independent credentials. A student who completes modules 100–300 holds three credentials, each tied to a different `slt_hash`. The course doesn't issue one big credential at the end — each module is its own credentialable unit.

This means:
- A student can earn partial credit (three of five modules).
- A project can require a specific module credential as a prerequisite, not the entire course.
- Modules can be added or updated independently after the course is created.

The module is the smallest unit that produces a credential. The SLT is the smallest unit of assessment criteria within a module.

## Why SLTs exist separately from modules

A module could just have a title and a pass/fail grade. SLTs exist because the credential needs to mean something specific — and because the `slt_hash` needs to mean something verifiable.

When a teacher assesses a student's assignment, the assessment decision covers all SLTs in that module. The `slt_hash` — deterministically computed from the SLT text — is the second half of the credential's on-chain address. Anyone who knows the SLTs can recompute the hash and check it against the chain: this credential certifies *these specific capabilities*, not just "completed Module 100."

This is the content-addressed identity from M100.1: the credential proves the holder did the work, the hash proves what "the work" was, and anyone can verify both without trusting the course operator.

## The roles

| Role | What they can do |
|------|-----------------|
| **Owner** | Create the course, add/remove teachers |
| **Teacher** | Create modules, write content, assess assignments |
| **Student** | Enroll, submit evidence, claim credentials |

Owner and teacher are often the same person on small courses. The protocol doesn't care — roles are just on-chain permissions.

## Your turn

A developer asks: *"Why can't I just create a course with one big module that covers everything?"*

In two or three sentences, explain what they'd lose. Write your answer before checking the rubric.

## Rubric

A strong answer names at least two of: (1) partial credit — students can't earn credentials for completed portions, (2) prerequisite granularity — other courses or projects can't require a specific module, only the whole course, (3) independent updates — changing one topic forces a new hash for everything. The core point: modules are the credentialable unit, and one module means one credential for the whole course.

## What you just did

You understand how courses, modules, and SLTs compose. Every credential has an on-chain address (`course_id.slt_hash`) that anyone can verify. The off-chain content — lessons, assignments, evidence — can live anywhere, because the chain stores the proof, not the content.
