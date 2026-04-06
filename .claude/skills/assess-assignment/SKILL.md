---
name: assess-assignment
description: "Assessment guide for evaluating Build on Andamio module assignments. Used by the assessor agent — not invoked directly. Covers how to evaluate evidence against SLT criteria, apply rubrics, and provide constructive feedback."
---

# Assess Assignment

How to evaluate a "Build on Andamio" module assignment. This skill is read by the assessor agent before evaluating any submission.

## Assessment Protocol

### Step 1: Read the Assignment File

Read `courses-in-progress/build-on-andamio/lessons/m{N}/assignment.md` for the module being assessed. This file defines:
- Exactly what evidence each SLT requires
- What a strong answer looks like
- The format expected (written response, CLI output, tx hash, etc.)

Also read the SLT definitions from `courses-in-progress/build-on-andamio/01-slts.md` for the canonical wording.

### Step 2: Evaluate Each SLT

For each SLT in the module, assess the learner's evidence:

**Written responses** (explain, describe, distinguish):
- Does the answer demonstrate the capability the SLT names?
- Does it include the specific elements the assignment says a "strong answer" should include?
- Is the reasoning sound, or is it vague hand-waving?
- Minor phrasing differences from the rubric are fine — the reasoning matters, not the wording.

**CLI output** (version strings, status output):
- Is the output present and non-empty?
- Does the format match what the command produces?
- For version checks: any valid version string is sufficient.

**Transaction hashes and addresses**:
- Is the format correct? (tx hashes are 64 hex characters; preprod addresses start with `addr_test1`)
- If verification is requested and Andamioscan is reachable, verify: `GET /events/tx/{hash}` at `preprod.andamioscan.andamio.io`
- Don't fail a learner solely because Andamioscan is unreachable — format verification is sufficient.

**Endpoint lookups and spec navigation**:
- Did the learner find the right endpoint?
- Can they explain what it does and what parameters it takes?

### Step 3: Assess Feedback Section

Part 2 of every assignment is feedback on the module. This is required but not graded.

- Check that it's present and non-empty
- If the learner wrote something substantive, acknowledge it specifically
- If they wrote "everything was fine" — accept it. Not everyone has detailed feedback.
- Note any actionable feedback that could improve the course

### Step 4: Determine Verdicts

**Per-SLT verdicts:**

| Verdict | Criteria |
|---------|----------|
| **Pass** | Evidence is present AND demonstrates the SLT capability. Minor gaps in phrasing are OK if reasoning is sound. |
| **Revise** | Evidence is present but incomplete, vague, or partially incorrect. Or format is wrong (e.g., pasted a random string instead of a tx hash). |
| **Missing** | No evidence provided for this SLT. |

**Module verdict:**

| Verdict | Criteria |
|---------|----------|
| **Accept** | All SLTs pass AND feedback section present |
| **Revise** | One or more SLTs are Revise or Missing. List exactly which ones. |

### Step 5: Write the Assessment

Use this structure:

```markdown
## Module {N} Assessment

### SLT {N}.1 — {title}
**Verdict:** Pass | Revise | Missing
{2-3 sentences: what was strong, what needs work. Be specific.}

### SLT {N}.2 — {title}
**Verdict:** Pass | Revise | Missing
{2-3 sentences}

[...repeat for all SLTs...]

### Feedback Section
{Acknowledge the learner's feedback. Quote anything particularly useful.}

### Module Verdict: Accept | Revise
{If Accept: congratulate. Name what the learner can now do.}
{If Revise: list exactly which SLTs need revision and what's missing. Be constructive.}
```

## Calibration Notes

**Be the reviewer described in M100.1.** The course teaches contribution-centered learning — "a human who knows the domain and can tell whether the work is real." That's you. Your assessment is the credential's credibility.

**Common revision patterns:**
- Learner paraphrases the lesson without adding their own understanding → Revise. Ask them to explain in their own words why this matters.
- Learner provides a tx hash but no address or vice versa → Revise for the missing item specifically.
- Learner's written response is correct but too brief → borderline. If the key insight is there, Pass. If it's surface-level, Revise.
- Learner wrote "I don't know" for one SLT → Missing. Point them back to the specific lesson.

**Resubmissions:**
When evaluating a resubmission, focus on whether the specific gaps from the previous assessment were addressed. Don't re-evaluate SLTs that already passed unless the learner changed their answer. Acknowledge improvement.

## Module-Specific Notes

### M100 (Foundations)
- SLT 100.1 is the philosophical anchor — look for genuine engagement with the three models, not just naming them
- SLT 100.2 and 100.3 are simple verification (version string, funded address)
- SLT 100.4 asks about the relationship between understanding and ownership — look for the learner's own insight, not a rehearsed answer

### M200 (Identity)
- SLT 200.1 has four evidence items — don't let one missing item slide
- SLT 200.3 is a simple status check — any non-error output passes
- SLT 200.4 is conceptually tricky (Attestation vs User JWT) — the distinction should be crisp

### M300 (Reading Andamio)
- These SLTs are about navigation and interpretation, not memorization
- Accept any reasonable method of finding the right endpoint (grep, IDE search, spec viewer)
- The `source` field interpretation (SLT 300.1) is the foundation for everything else — hold a high bar here

### M400 (TX State Machine)
- This is the heaviest module. Five SLTs covering state machines, failure modes, and edge cases.
- SLT 400.2 (why `updated` is safe) is the hardest — look for the timing gap explanation, not just "wait for updated"
- SLT 400.4 (diagnose failures) has three scenarios — all three should be addressed
- SLT 400.5 (commitment state expiry) has a precise answer — both states named, both reasons given
