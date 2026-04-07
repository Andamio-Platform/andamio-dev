# Critique the Andamio developer experience

## Before we start

Last lesson of the course. You've gone from "what is Andamio" to a working integration. This lesson asks you to look back and say what worked, what didn't, and what you'd change. The critique isn't a formality — it's the course doing what the course teaches.

## Why this lesson exists

In M100.1, you learned about contribution-centered learning: a credential should prove someone did the work, and the work should improve the system. Feedback is itself a contribution. A student who works through seven modules and then articulates what confused them, what took too long, what should be rewritten — that student is doing exactly what the model describes.

This lesson invites that contribution explicitly. Your critique is evidence under the same framework you've been studying.

## What to critique

Think about your experience across all seven modules. Some dimensions to consider:

**The API surface:**
- Were endpoints discoverable? When you needed to find the right endpoint, did you find it quickly?
- Were error messages actionable? When something failed, did the error tell you what to fix?
- Were the request and response shapes consistent? Did patterns from one endpoint predict behavior of another?

**The CLI:**
- Did commands do what you expected? Were flags intuitive?
- Was `--output json` consistently useful for scripting?
- Were there operations that should have had a CLI command but didn't?

**The transaction model:**
- Was the five-step state machine clear, or does it still feel like ceremony?
- Did the `updated` vs `confirmed` distinction make sense? Did you get caught by it?
- Were cost surprises handled well? Did you know what a transaction would cost before running it?

**The course itself:**
- Which module was the most useful? Which was the least?
- Was there a concept that clicked only after a later lesson? Should the ordering change?
- Were the exercises the right difficulty? Too easy, too hard, or just right?

**The ecosystem:**
- Was documentation sufficient? Where did you have to guess?
- Was the preprod experience representative of what mainnet would be?
- If you used an agent, did the agent improve or hinder the learning?

## What a good critique looks like

A good critique is specific and constructive. Compare:

**Vague:** "The API was confusing."

**Specific:** "The `modules_manage` endpoint requires `modules_to_update` and `modules_to_remove` as empty arrays even when you're only adding. I hit a 400 error twice before I figured out all three arrays are required. The error message said 'invalid body' with no indication which field was missing."

The second version tells the team exactly what to fix: either make the arrays optional, or improve the error message. The first version tells them nothing actionable.

## The feedback loop

Your critique goes somewhere. Module assignments include a feedback section — not graded, but read. The `andamio-dev` repo is public, and issues are the canonical channel for DX feedback:

[github.com/Andamio-Platform/andamio-dev/issues](https://github.com/Andamio-Platform/andamio-dev)

An issue titled "M500.3: PENDING_TX status transition is undiscoverable" with your experience, the error you hit, and the fix you'd suggest — that's contribution-centered learning running on itself. The course improves because students build on it.

## Your turn

Write a critique of the Andamio developer experience based on your work through all seven modules. Cover at least two dimensions from the list above. Be specific — name the module, the command, the endpoint, the error, or the moment. Aim for a paragraph or two.

There's no rubric for this one. A good critique is honest.

## What you just did

You articulated what worked and what didn't, with enough specificity that someone could act on it. That's the feedback-as-contribution model from M100.1: the course isn't a fixed artifact, and the student working through it carefully is often the person best positioned to improve it.
