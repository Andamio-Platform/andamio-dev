---
name: deliver-lesson
description: "Pedagogy guide for delivering Build on Andamio course lessons. Used by learn or invoked directly when a learner asks for a specific lesson. Covers how to present lesson content, guide exercises, check comprehension, and adapt to learner level."
license: MIT
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: Deliver Lesson

Present a "Build on Andamio" lesson to a learner. This skill is agent-neutral: use it inline when subagents are unavailable.

## Path Resolution

- Plugin context (`${CLAUDE_PLUGIN_ROOT}` is set): read course content from `${CLAUDE_PLUGIN_ROOT}/courses/`.
- Clone/symlink context: read course content from `courses/` relative to the project root.

## Lesson Delivery Protocol

### Step 1: Read the Lesson File

Read the full lesson file at `courses/build-on-andamio/lessons/m{N}/{slt}-{slug}.md`.

Parse the frontmatter to understand:
- `lesson_type` — determines your delivery approach
- `bloom_level` — calibrates depth of engagement
- `estimated_time_min` — sets pace expectations
- `prerequisites` — what the learner should already know
- `evidence_type` — what the assignment will ask for

If the learner gives only an SLT number such as `100.1`, locate the file by matching the filename prefix under the module directory.

### Step 2: Set Context

Briefly orient the learner:
- module and lesson number
- the SLT/capability they are working toward
- estimated time
- prerequisites to confirm

Keep this under three sentences. The lesson's own "Before we start" section handles deeper framing.

### Step 3: Present Content

Break the lesson into its natural sections marked by `##` headers.

For each section:
- present the content in your own voice, faithful to the lesson but not as a verbatim dump
- pause after dense concepts for questions
- when the lesson references a command or API call, offer to demonstrate it live
- when the lesson references another lesson or module, note the connection without derailing

### Step 4: Guide "Your Turn"

Every lesson has a "Your turn" section. Treat it as the most important part.

For reflective exercises:
- prompt the learner to think before revealing rubric-level guidance
- ask for their answer, then compare notes and discuss gaps

For operational exercises:
- walk through the task step by step
- let the learner run commands when possible, or run safe read-only commands for them
- use `--output json` for CLI commands
- verify output and debug errors together

For exploration exercises:
- give hints before answers
- ask what they would search for before showing commands or spec locations

### Step 5: Wrap Up

After "Your turn":
- recap using the lesson's "What you just did" section
- confirm whether the lesson is complete, partial, or still in progress
- preview the next lesson or assignment
- report completion status to the orchestrator if this skill is being used from `learn`

## Delivery By Lesson Type

| Type | Approach | Focus |
| --- | --- | --- |
| `exploration` | Discussion-led. Ask questions, explore ideas, build mental models. | Understanding |
| `developer_documentation` | Demo-led. Show code, run commands, read specs. | Doing |
| `how_to_guide` | Step-by-step walkthrough. Verify each step before proceeding. | Executing |
| `product_demo` | Show-and-tell. Run the thing, let the learner try, discuss what happened. | Experiencing |

## Bloom Level Calibration

| Level | Engagement |
| --- | --- |
| `understand` | Focus on comprehension. Ask the learner to explain it back. |
| `apply` | Focus on doing with their own data. |
| `analyze` | Focus on decomposition, tradeoffs, and why it works. |
| `evaluate` | Focus on judgment and critique. |
| `create` | Focus on synthesis and building something. |

## Learning Mode vs Operational Mode

The course teaches in Learning Mode: concepts, mechanics, and mental models. Exercises often shift briefly into Operational Mode: CLI commands, API calls, or transaction workflows.

Transition explicitly, then return to the concept:
- "Now that the idea is clear, let's run the command."
- "Here is what just happened on-chain."

## Pace Signals

If the learner:
- says "I know this" or "skip": summarize quickly, confirm they can pass the exercise, and move on
- asks to slow down: break the current section into smaller pieces
- goes silent: check whether they want a different angle
- hits an error: treat it as a learning moment and use `troubleshoot` patterns when relevant

