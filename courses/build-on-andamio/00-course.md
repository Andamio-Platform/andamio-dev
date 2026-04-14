---
course: Build on Andamio
slug: build-on-andamio
audience: Developers integrating Andamio into their own apps, services, or tools
status: context-gathered
phase: 6
last_updated: 2026-04-05
---

# Build on Andamio

**Working title.** A seven-module course for developers who want to build on top of the Andamio Protocol. Designed to live inside the `andamio-dev` plugin as Learning Mode — learners advance module by module, each one unlocked by the prior module's SLTs.

The course is designed to be publishable on Andamio itself: each module has a definitive SLT list, which produces a deterministic `slt_hash`. Learners can optionally submit evidence on-chain and claim a "Build on Andamio" credential NFT at the end.

## Scope

In scope:
- Andamio gateway API (`specs/andamio-api.yaml`)
- Andamio CLI
- Andamio App Template (surfaced in lessons, not in SLTs)

Out of scope:
- Andamioscan, andamio-db-api, andamio-atlas-api — learners meet these implicitly through gateway responses, but they are not subjects of the course. The internal architecture is not taught; the surface is.

## Modules

| # | Module | SLTs | Purpose |
|---|--------|------|---------|
| 100 | Foundations | 4 | Mental model + working toolchain |
| 200 | Identity | 4 | Access token, JWT auth, headless login |
| 300 | Reading Andamio | 4 | Query the gateway, interpret responses |
| 400 | The Transaction State Machine | 5 | The pattern behind every write |
| 500 | Courses End-to-End | 5 | Full course lifecycle on-chain |
| 600 | Projects End-to-End | 4 | Full project lifecycle with treasury and escrow |
| 700 | Build Something Real | 5 | Capstone integration |

Total: **31 SLTs across 7 modules.**

## Module gating

Each module is a prerequisite for the next. Progress is tracked locally at
`${CLAUDE_PLUGIN_DATA}/progress.json` with the option to submit evidence
on-chain and earn a credential.

## Module assignments

Every module has a single assignment that consolidates the module's SLTs into a submittable artifact. The assignment lives at `lessons/m<N>/assignment.md` alongside the lessons. Every assignment has two parts:

1. **Evidence for the module's SLTs** — the work the student submits to earn the module's credential. The shape depends on the module: a written reflection, a transaction the student ran, a repo link, a code snippet, a set of annotated responses.
2. **A feedback section** — an open invitation for the student to tell the course what worked, what confused them, and what they would change. Feedback is itself a valid artifact under contribution-centered learning, and soliciting it from every student on every module is how the course improves over time.

The feedback section is non-negotiable. The opening promise in M100.1 — *"We'll also ask for feedback as you work through this course"* — is kept by every module, every time, not just the first or the last. A student who completes all seven modules has had seven explicit invitations to shape how the course works for the next person. That's the pedagogy running on itself.

**Per-lesson "Your turn" sections are different.** Individual lessons include comprehension checks (e.g., the three-scenario rubric in M100.1). Those are formative self-assessment, not the credentialed evidence. The module assignment is the single artifact the student submits on-chain for the module's credential.

## Workflow status

- [x] Phase 1: SLTs drafted (`01-slts.md`) — 32 SLTs across 7 modules
- [x] Phase 2: Quality reviewed (`02-slts-quality-review.md`) — 32 Strong after rewrites
- [x] Phase 3: Lesson types classified (`03-lesson-type-classification.md`) — 16 DevDoc · 13 Exploration · 2 HTG · 1 Product Demo
- [x] Phase 4: Readiness assessed (`04-readiness-assessment.md`) — ended at 20 Ready · 12 Needs Context · 0 Needs Human
- [x] Phase 5: Delegation map *(skipped — absorbed into research pass, since 0 Needs Human)*
- [x] Phase 6: Context gathered (`05-research-pass.md`, pedagogy brief) — **32 Ready · 0 Needs Context · 0 Needs Human**
- [ ] Phase 7: Lessons built
- [ ] Phase 8: Compiled for import
- [ ] Phase 9: Compound rollup
- [ ] Phase 10: Promoted to `courses/`

## Sources

Canonical references the course author should cite when drafting lessons:

| Source | Location | Feeds |
|---|---|---|
| Andamio System Reference | `andamio-dev-kit-internal/docs/SYSTEM_REFERENCE.md` | M200, M300, M400, M500, M600 technical content |
| Andamio Authentication | `andamio-dev-kit-internal/docs/AUTH.md` | M200 auth flows, attestation JWT |
| Contribution-centered learning | `andamio-ai-context/02-strategy/contribution-centered-learning.md` | M100.1 + pedagogy framing across all modules |
| Andamio CLI source | `andamio-cli/` | M100, M200, M400, M500, M600 CLI command examples |
| Andamio gateway source | `andamio-api/` | M300, M400 gateway behavior, error shapes |
| Andamio App Template | `andamio-platform/andamio-app-template/` | M700 integration strategy and scaffold |
| Andamio App V2 | `andamio-platform/andamio-app-v2/` | M700 idiomatic failure handling patterns |
| Gateway OpenAPI spec | `andamio-dev/specs/andamio-api.yaml` | M300, M400 endpoint references |
| Cost registry | `andamio-dev/specs/cost-registry.json` | M700 cost estimation |
| **TX loops reference** (pending) | `andamio-dev/reference/tx-loops.yaml` | M400, M500, M600, M700 — names each runnable loop and its cost model. See Pending dependencies below. |

All 32 SLTs are now backed by at least one of the above sources. No SLT requires content to be reconstructed by the lesson author.

## Dependencies (resolved)

All external dependencies have been resolved as of 2026-04-06:

- **`tx-loops.yaml`** — landed 2026-04-06. 16 canonical loops with dotted names, steps, roles, costs. Lives at `reference/tx-loops.yaml`.
- **Cohort-scale cost math** — confirmed linear per student (~1.32 ADA × N). Reflected in `tx-loops.yaml` loop 13 (`course.credential.cohort`).
- **Cost-registry key rename** — `single-credential` → `course.credential`, `multi-assignment-credential` → `course.credential.with-updates`. Keys now match tx-loop names.
- **DB API PENDING_TX** — resolved in `andamio-db-api-go#181`. Module status can now be set to PENDING_TX via API.

**All 7 modules are unblocked and drafted.** M100–M700 lessons are complete and live in `courses/build-on-andamio/lessons/m{N}/`.
