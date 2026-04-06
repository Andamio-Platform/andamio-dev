# Drafting guidelines — Build on Andamio

Guidelines every lesson in this course must honor. If a draft violates one of these, fix the draft, not the rule.

## What we're making

A course that can be consumed in two ways and means the same thing in both:

1. **On the web** at `app.andamio.io`, as prose a developer reads top-to-bottom, writes notes against, and moves through at their own pace.
2. **In an agent harness** like Claude Code or Cursor, as an orchestrated conversation where the agent presents the lesson, checks comprehension, runs commands on the learner's behalf, and tracks progress.

Neither shape is the "real" one. The content is the course. The interface is a choice the learner makes. The course never asks the learner which one they picked. It never checks. It never assumes.

## The four principles

### 1. Dual-interface by default

Every lesson must read cleanly as standalone prose on a static web page, and must also be orchestratable by an agent as an interactive session. The test: print the lesson, hand it to a developer, and it should teach them something. Paste the lesson into an agent harness, and the agent should be able to run the learner through it.

### 2. Teaching is ownership

The point of the course is not to hand learners access to the plugin's skills. The point is to make those skills theirs. A tool you don't understand is someone else's tool even when you're the one holding it. The gating between Learning Mode and Ops Mode exists so that by the time a learner reaches `/course-ops` or `/project-ops`, that skill feels like a summary of what they already know — not a revelation, not a black box, not something someone else built that they now depend on.

This is the contribution-centered pedagogy applied to the developer toolchain itself. It's also the direct answer to a real worry: a generation of developers using AI to produce work faster than they understand it, and finding it harder to level up because the understanding layer got skipped. This course runs the opposite way. Agents are welcome; mystery is not.

### 3. Agent-neutral assignments

The course cares about the work, not the route to the work. If a learner writes a comprehension answer from memory, that's a pass. If a learner writes the same answer with an agent explaining the concept in the next window, that's also a pass. If a learner figures out how to submit an assignment by asking their agent to read `andamio --help` and execute the right command, *that's a big win* — they used the tool and earned the outcome, and the agent was a teacher in the loop.

The course never asks "did you do this with an agent?" It asks "can you produce the work, and does the work hold up?" Contribution-centered learning measures evidence, not effort. The route doesn't matter.

### 4. Prose-first, agent-augmented

Every interactive affordance the course offers is optional, layered on top of prose that works without it. Where an agent can add real value — fetching a source document, running a command, checking an answer against a rubric — the lesson mentions the affordance as an option, never a requirement. The prose itself does the teaching.

## Operational guidelines

1. **Write prose-first.** Draft the lesson as if it's appearing on a web page with no interactivity. Then add affordances for the agent harness on top. Never write the other way around.

2. **Never assume the reader has an agent.** Don't say "the course agent will check your answer." Don't say "ask the agent to fetch the source." Phrase interactive moments as "if you have an agent with you, it can..." with a parallel path for readers who don't.

3. **Never check whether the reader has an agent.** The course doesn't ask. It offers the affordance and moves on. Two readers, same content, same result, different paths — and the course never needs to distinguish them.

4. **Make the rubric visible.** Every comprehension check shows the learner exactly what a correct answer looks like before they submit. This is contribution-centered learning at the meta level: the target is visible, the learner is aiming at it, not guessing.

5. **Teach mechanism, not just usage.** The lesson for a CLI command doesn't stop at "run this, see the output." It names what the command wraps, what endpoint it calls, what response it returns, what happens when it fails. The learner finishes the lesson able to reconstruct the tool's behavior from first principles, not just invoke it. By the time the matching Ops skill unlocks, the learner could have written the skill themselves.

6. **Close every lesson with ownership, not access.** The final beat of every lesson is "I now understand what this is for," not "I can now use this." If the learner leaves a lesson thinking "I have a new tool," something went wrong. They should leave thinking "I now understand a thing, and here are the tools that embody that thing."

7. **Lesson files are self-contained.** Lesson markdown under `lessons/` must not reference private repositories or internal-only paths — not in the body, not in the frontmatter. This includes `andamio-ai-context`, `andamio-dev-kit-internal`, and any other repo a general learner couldn't reach. If a lesson is derived from an internal source, the connection lives in author briefings and team dogfooding, not in the file itself. Team members working through the course will recognize those connections from their own context; external learners never see paths to things they can't open. This rule applies to lesson files only — course-author artifacts like `00-course.md`, `05-research-pass.md`, and this guidelines file are internal working documents and may reference any source that's useful for the author.

8. **Lessons are read-only. Assignments are where submission happens.** A lesson file under `lessons/` never asks the student to enter, submit, or produce anything the course will consume. No "paste your answer here," no "write your three responses below." Lessons present content; they do not collect it. The student's credentialed work lives in the module's `assignment.md`, not in any lesson. Per-lesson "Your turn" sections exist, but they are self-checks — the student reads the scenario, reads the visible rubric, and verifies the concept landed. Nothing gets submitted at the lesson level.

   **The one exception is always-open feedback.** Students can share informal feedback on any lesson at any time by opening an issue at the public [andamio-dev](https://github.com/Andamio-Platform/andamio-dev) repository. Lessons may link to that repository as an always-available feedback affordance. Feedback-via-issues is itself a contribution under the pedagogy the course teaches, and inviting it continuously (not just at module assignment time) is how the course keeps the opening promise that students are contributing from the first lesson.

9. **Every module has an assignment with a feedback section.** Alongside the lessons in each module's folder lives `assignment.md`, the module-level assignment the student submits to earn the module's credential. Every assignment has two parts: **evidence** for the module's SLTs (what the student produces — a written reflection, a transaction they ran, a repo link, a code snippet, a set of annotated responses) and **a feedback section** (an open invitation for the student to say what worked, what confused them, and what they would change). The feedback section is non-negotiable. M100.1's opening promises the learner that "we'll ask for feedback as you work through this course" — that promise is kept by every module, every time, not just the first or the last.

10. **Honor the terminology rules in `terminology.md`.** The file `courses-in-progress/build-on-andamio/terminology.md` is the authoritative reference for which names to use when referring to parts of the Andamio ecosystem in lesson content. Approved terms: **Andamio API**, **Andamio CLI**, **Andamio App**, **Andamio App Template**, **access token**, **alias**, **course**, **project**, **evidence**, **credential**. Forbidden terms: **gateway** (and any form), **andamioscan**, **Atlas** / **tx-api** / **txapi** (and any form), **db-api** / **dbapi** (and any form). Internal service names are not subjects of this course; learners see a small, stable public surface and nothing else. Every new lesson must be checked against `terminology.md` before it ships. If you find yourself reaching for a forbidden term, the approved substitute is in the table.

## What good looks like

A lesson passage that honors the guidelines:

> The `andamio tx run` command looks like a single invocation, but it wraps the five-step state machine you just learned. Build: it POSTs your body to the Atlas endpoint and receives unsigned CBOR. Sign: it hands the CBOR to your signing path (a `.skey` file or a browser wallet) and gets signed CBOR back. Submit: it broadcasts the signed CBOR to Cardano and receives a tx_hash. Register: it POSTs the tx_hash to the gateway so the gateway starts tracking it. Wait: it polls the gateway's status endpoint until the state reaches `updated`.
>
> If you're reading this on the web and want to see the command output, run it yourself with a throwaway TX like `treasury/add-funds`. If you're reading this in an agent harness, you can ask your agent to run it with a throwaway TX and walk through the output with you. Either way, the result is the same: you see the five steps happen and you know what each one is doing.

Notice:
- Prose is complete without the agent. A reader on the web can follow this and learn.
- The affordance is offered conditionally, not assumed.
- The "teach mechanism, not usage" guideline is honored — the reader learns what the command *wraps*, not just how to invoke it.
- The closing beat is understanding, not access.

## What drift looks like

A passage that fails the guidelines:

> When you're ready, paste the tx_hash into the chat and the course agent will look up its status and confirm it reached `updated`.

Problems:
- Assumes an agent. A web reader has no chat.
- Treats the agent as required, not optional.
- Offloads the understanding to the agent ("the agent will look up and confirm") instead of teaching the learner how to look it up themselves.

The rewrite:

> Run `andamio tx status <tx_hash>` to see the current state. You'll see the state progress from `pending` to `confirmed` to `updated` over the next 30–90 seconds. `updated` means the transaction is on-chain and the gateway's database has synced — the only state where it's safe to refetch related data.
>
> If you're in an agent harness, you can ask your agent to watch the status for you and let you know when it reaches `updated`. Same command, either way.

## Applying the guidelines to unlock mechanics

The Ops Mode unlock table isn't a reward ladder. It's a promise: every skill in `andamio-dev` behind the gate is a skill the learner has been taught to understand before they touch it. If a new Ops skill gets added to the plugin, a corresponding lesson is added to the course *at the same time*. The plugin never surfaces mystery.

This is the pedagogical argument for progressive unlock. Not "you haven't earned this yet." Rather: "you don't yet know what this is, so handing it to you would be dishonest. Let's fix that first."

## Placeholder tokens

Some content in lesson and assignment files can't be finalized until the course publishes — the course's URL on `app.andamio.io`, the install command for the `andamio-dev` plugin, on-chain SLT hashes for modules that haven't been minted yet. Rather than ship vague prose or broken links, we use typed placeholder tokens that get grep-and-replaced during the publication pass.

### The registry

Every placeholder token currently in use lives in this table. Adding a new token means adding a row here in the same commit that introduces the token.

| Token | Used for | First appears in | Replace with at publish time |
|---|---|---|---|
| `{COURSE_ID}` | Direct URL to the course on `app.andamio.io` | `lessons/m100/100.1-contribution-centered-learning.md`, `lessons/m100/assignment.md` | The course's 56-char hex LocalStateNFT policy ID once it's been minted |
| `{PLUGIN_INSTALL_COMMAND}` | The exact shell command for installing the `andamio-dev` plugin into Claude Code, Cursor, or a similar agent harness | `lessons/m100/100.4-learning-mode-and-ops-mode.md` | The literal install command once the plugin publishes |

### The rules

1. **Naming.** Placeholder tokens use `{UPPER_SNAKE_CASE}` inside curly braces. This is the grep target for the publication pass. Do not use angle brackets, dollar signs, or other marker styles — mixing conventions makes the release pass harder.

2. **Document before use.** Any new placeholder token added to a lesson or assignment must also be added to the registry table above in the same commit. If a token isn't in the registry, it's not a placeholder — it's a typo or a hallucinated variable.

3. **Visible in the rendered lesson.** Placeholder tokens should appear verbatim in rendered Markdown so web readers know they're looking at a placeholder state, not a real command or URL. Wrap them in inline code (`{LIKE_THIS}`) or present them inside a fenced code block with a `# Placeholder — ...` comment line immediately above.

4. **Never ship.** Before publishing the course, run a sweep across `lessons/**/*.md` and any other learner-facing files, replacing every token with its real value. If any `{UPPER_SNAKE_CASE}` token remains in a learner-facing file at publish time, the publication pass failed and publication should halt.

5. **Author artifacts are exempt.** Course working documents under `courses-in-progress/` — `00-course.md`, the teacher-phase artifacts (`01-slts.md` through `05-research-pass.md`), this guidelines file, research notes — can reference placeholder tokens freely without triggering the publication sweep. The sweep runs only over learner-facing files.

### Finding tokens

To audit which tokens are currently in use across lesson files:

```bash
grep -rE '\{[A-Z_]+\}' lessons/
```

Every result should correspond to a row in the registry. Any result that doesn't is a sign the registry is out of date.
