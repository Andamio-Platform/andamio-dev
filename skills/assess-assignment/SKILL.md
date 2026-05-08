---
name: assess-assignment
description: "Assessment guide for evaluating Build on Andamio module assignments. Used by learn or invoked directly when a learner submits evidence. Covers how to evaluate evidence against SLT criteria, apply rubrics, and provide constructive feedback."
license: MIT
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: Assess Assignment

Evaluate a "Build on Andamio" module assignment. This skill is agent-neutral: use it inline when subagents are unavailable.

## Path Resolution

- Plugin context (`${CLAUDE_PLUGIN_ROOT}` is set): read course content from `${CLAUDE_PLUGIN_ROOT}/courses/`.
- Clone/symlink context: read course content from `courses/` relative to the project root.

## Assessment Protocol

### Step 1: Read The Assignment File

Read `courses/build-on-andamio/lessons/m{N}/assignment.md` for the module being assessed.

This file defines:
- evidence required for each SLT
- what a strong answer looks like
- expected format, such as written response, CLI output, transaction hash, or address

Also read `courses/build-on-andamio/01-slts.md` for canonical SLT wording.

### Step 2: Evaluate Each SLT

For written responses:
- check whether the answer demonstrates the capability named by the SLT
- require the specific elements the assignment says a strong answer should include
- accept different phrasing when the reasoning is sound
- ask for revision if the answer only parrots lesson text without showing understanding

For CLI output:
- check that output is present and non-empty
- check that the format plausibly matches the command
- for version/status checks, any valid non-error output is usually enough

For transaction hashes and addresses:
- transaction hashes should be 64 hex characters
- preprod addresses should start with `addr_test1`
- if verification is requested and Andamioscan is reachable, verify against `preprod.andamioscan.andamio.io`
- do not fail solely because Andamioscan is unreachable when format evidence is otherwise plausible

For endpoint/spec lookups:
- check that the learner found the right endpoint
- require a short explanation of what it does and what parameters it takes

### Step 3: Assess Feedback Section

Part 2 of every assignment is feedback on the module. It is required but not graded.

- check that it is present and non-empty
- acknowledge substantive feedback specifically
- accept simple feedback such as "everything was fine"
- note anything actionable for course improvement

### Step 4: Determine Verdicts

Per-SLT verdicts:

| Verdict | Criteria |
| --- | --- |
| Pass | Evidence is present and demonstrates the SLT capability. Minor phrasing gaps are acceptable. |
| Revise | Evidence is present but incomplete, vague, partially incorrect, or wrong format. |
| Missing | No evidence provided for the SLT. |

Module verdict:

| Verdict | Criteria |
| --- | --- |
| Accept | All SLTs pass and the feedback section is present. |
| Revise | One or more SLTs are Revise or Missing. |

### Step 5: Write The Assessment

Use this structure:

```markdown
## Module {N} Assessment

### SLT {N}.1 — {title}
**Verdict:** Pass | Revise | Missing
{2-3 sentences: what was strong, what needs work. Be specific.}

### SLT {N}.2 — {title}
**Verdict:** Pass | Revise | Missing
{2-3 sentences}

### Feedback Section
{Acknowledge the learner's feedback. Note anything actionable.}

### Module Verdict: Accept | Revise
{If Accept: name what the learner can now do.}
{If Revise: list exactly which SLTs need revision and what is missing.}
```

## Calibration Notes

Be the reviewer described in M100.1: a domain reviewer who can tell whether the work is real. Credentials are meaningful only if the review is credible.

Common revision patterns:
- paraphrased lesson with no learner reasoning: Revise
- tx hash without required address, or address without required tx hash: Revise for the missing item
- correct but very brief written response: Pass only if the key insight is clearly present
- "I don't know" for an SLT: Missing

For resubmissions, focus on whether the prior gaps were addressed. Do not re-evaluate already-passed SLTs unless the learner changed the answer.

## Module-Specific Notes

### M100 Foundations
- SLT 100.1 is the philosophical anchor. Look for genuine engagement with the three learning models.
- SLT 100.2 and 100.3 are simple verification items.
- SLT 100.4 asks about the relationship between understanding and ownership. Look for the learner's own insight.

### M200 Identity
- SLT 200.1 has multiple evidence items. Do not pass if one is missing.
- SLT 200.3 is a status check. Any non-error output can pass.
- SLT 200.4 is conceptually tricky. The Attestation JWT vs User JWT distinction should be crisp.

### M300 Reading Andamio
- Assess navigation and interpretation, not memorization.
- Accept any reasonable method of finding the right endpoint.
- Hold a high bar for interpreting the `source` field.

### M400 TX State Machine
- SLT 400.2 should explain the timing gap that makes `updated` safer than earlier statuses.
- SLT 400.4 has multiple scenarios; all should be addressed.
- SLT 400.5 has a precise answer; both reverting states and reasons should be present.

