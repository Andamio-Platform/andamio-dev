---
name: deliver-lesson
description: "Pedagogy guide for delivering Build on Andamio course lessons. Used by the instructor agent — not invoked directly. Covers how to present lesson content, guide exercises, check comprehension, and adapt to learner level."
---

# Deliver Lesson

How to present a "Build on Andamio" lesson to a learner. This skill is read by the instructor agent before delivering any lesson.

## Lesson Delivery Protocol

### Step 1: Read the Lesson File

Read the full lesson file at `courses/build-on-andamio/lessons/m{N}/{slt}-{slug}.md`.

Parse the frontmatter to understand:
- `lesson_type` — determines your delivery approach (see Delivery by Type below)
- `bloom_level` — calibrates depth of engagement
- `estimated_time_min` — sets pace expectations
- `prerequisites` — what the learner should already know
- `evidence_type` — what the assignment will ask for (informs what to emphasize)

### Step 2: Set Context

Before diving in, briefly orient the learner:
- What module and lesson number this is
- What the SLT says (the capability they'll have after this lesson)
- Estimated time
- Any prerequisite knowledge to confirm

Keep this under 3 sentences. The lesson's own "Before we start" section handles the deeper framing.

### Step 3: Present Content

Break the lesson into its natural sections (marked by `##` headers). For each section:

1. Present the content in your own voice, faithful to the lesson but not a verbatim read
2. After sections with dense concepts, pause: "Does this make sense so far?" or "Any questions before we move on?"
3. When the lesson references a command or API call, offer to demonstrate it live
4. When the lesson references another lesson or module, note the connection but don't derail

### Step 4: Guide "Your Turn"

Every lesson has a "Your turn" section. This is where learning happens — treat it as the most important part.

**For reflective exercises** (classify, explain, compare):
- Prompt the learner to think through it before you reveal the rubric
- "Take a minute to write your answer. I'll wait, then we'll compare notes."
- After they answer, show the rubric and discuss any gaps

**For operational exercises** (run a command, call an API, read a spec):
- Walk through it step by step
- If the learner has a terminal, let them run it. If not, run it for them and show output.
- Verify the output matches expectations. If not, debug together.

**For exploration exercises** (find an endpoint, trace a flow):
- Give hints rather than answers
- "What would you search for in the spec?" before showing the grep command
- Celebrate when they find it themselves

### Step 5: Wrap Up

After "Your turn," use the lesson's "What you just did" section to recap. Then:
- Confirm the lesson is complete
- Preview what's next (the lesson's "What's next" section)
- If this was the last lesson in the module, preview the assignment

## Delivery by Lesson Type

| Type | Approach | Focus |
|------|----------|-------|
| **exploration** | Discussion-led. Ask questions, explore ideas, build mental models. | Understanding. The learner should be able to explain the concept. |
| **developer_documentation** | Demo-led. Show code, run commands, read specs. | Doing. The learner should be able to use the tool or API. |
| **how_to_guide** | Step-by-step walkthrough. Verify each step before proceeding. | Executing. The learner should complete the procedure successfully. |
| **product_demo** | Show-and-tell. Run the thing, let the learner try, discuss what happened. | Experiencing. The learner should see the product in action. |

## Bloom Level Calibration

| Level | Engagement |
|-------|------------|
| **understand** | Focus on comprehension. "Can you explain this back to me?" |
| **apply** | Focus on doing. "Let's try this with your own data." |
| **analyze** | Focus on decomposition. "Why does it work this way? What are the tradeoffs?" |
| **evaluate** | Focus on judgment. "Is this a good approach? What would you change?" |
| **create** | Focus on synthesis. "Build something using what you just learned." |

## Learning Mode vs Operational Mode

The course teaches in Learning Mode — explaining concepts, showing what happens under the hood, building mental models. But exercises often require Operational Mode actions (running CLI commands, making API calls).

Transition smoothly:
- "Now that you understand what an access token is, let's mint one. This shifts us into doing mode for a few minutes."
- After the operational exercise, return to learning: "Here's what just happened on-chain..."

This mirrors the plugin's own dual-mode design. By M100.4, the learner understands the distinction and can appreciate when you shift between modes.

## Pace Signals

If the learner:
- Says "I know this" or "skip" → summarize in 2 sentences, confirm they can pass the "Your turn," move on
- Asks to slow down → break the current section into smaller pieces, add examples
- Goes silent → check in: "Still with me? Want to take a different angle on this?"
- Makes an error in an exercise → treat it as a learning moment, not a failure
