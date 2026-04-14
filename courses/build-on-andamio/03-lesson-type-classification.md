# Lesson Type Classification — Build on Andamio

> **Note (2026-04-05):** This document reflects the pre-combine SLT numbering. After this classification was produced, M200.1 (exploration) and M200.2 (dev doc) were merged into a single "Mint your access token" lesson, and M200.3–M200.5 were renumbered to M200.2–M200.4. Current authoritative SLT list is in `01-slts.md`.

**Date:** 2026-04-04
**Classified by:** `/coach:teacher` → `classify-lesson-types`
**Knowledge base consulted:** `lesson-types/heuristics.yaml` (v1)

## Summary

| Lesson Type | Count | Share | Modules it covers |
|---|---|---|---|
| Developer Documentation | 16 | 50% | All seven |
| Exploration | 13 | 41% | All seven |
| How To Guide | 2 | 6% | M100 (install), M200 (login) |
| Product Demo | 1 | 3% | M100 (faucet) |
| Organization Onboarding | 0 | 0% | — |

**Total:** 32 SLTs classified.

**Key decision factor:** This course is API/CLI-driven, not UI-driven. Per the `interface_determines_type` meta-heuristic, verbs like "mint" and "publish" that map to Product Demo in UI-first Andamio courses flip to Developer Documentation here because the learner is writing code against the API, not clicking through a platform.

## Classifications

### Module 100 — Foundations

#### SLT 100.1: "I can explain Andamio's contribution-centered learning model."
- **Lesson Type:** Exploration
- **Key Factors:** "explain" + conceptual worldview. High-confidence verb pattern from knowledge base.
- **Inputs Needed:** Framing questions about what "contribution-centered" means vs. "credential-centered."

#### SLT 100.2: "I can install the Andamio CLI."
- **Lesson Type:** How To Guide
- **Key Factors:** "install" is a high-confidence HTG verb. Terminal procedure; no UI, minimal conceptual depth.
- **Inputs Needed:** macOS/Linux/Windows install instructions, version verification, common install failures.

#### SLT 100.3: "I can fund a preprod wallet from the Cardano testnet faucet."
- **Lesson Type:** Product Demo
- **Key Factors:** External web UI walkthrough (Cardano faucet). The only Product Demo in the course.
- **Edge Notes:** Could shift to How To Guide if we'd rather use prose + a link instead of screenshots. Hybrid case — flagged during classification.
- **Inputs Needed:** Screenshots of the faucet flow, troubleshooting for faucet rate limits.

#### SLT 100.4: "I can distinguish Learning Mode from Ops Mode in this plugin."
- **Lesson Type:** Exploration
- **Key Factors:** "distinguish" + conceptual distinction about plugin design philosophy.
- **Inputs Needed:** Framing questions about when each mode is right.

### Module 200 — Identity

#### SLT 200.1: "I can explain why every Andamio write operation requires an access token."
- **Lesson Type:** Exploration
- **Key Factors:** "explain why" → design rationale. Textbook Exploration pattern.
- **Inputs Needed:** Framing around self-sovereign identity and what the token actually secures.

#### SLT 200.2: "I can mint an Andamio access token on preprod."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Override of knowledge-base default (Product Demo). Here the interface is CLI + raw API, not a UI. Learner sees the `access_token_mint` TX body, the `tx run` wrapping, and the returned tx_hash.
- **Inputs Needed:** CLI command, API body shape, tx_hash inspection example.

#### SLT 200.3: "I can distinguish the `X-API-Key` auth method from the User JWT."
- **Lesson Type:** Exploration
- **Key Factors:** `why_vs_how` heuristic. The real competency is trade-off understanding (when to reach for each), not syntax. Borderline with Dev Doc.
- **Inputs Needed:** Framing questions about read-only vs read+write access, and lifetime trade-offs.

#### SLT 200.4: "I can log in headlessly with a `.skey` file and receive a User JWT."
- **Lesson Type:** How To Guide
- **Key Factors:** Procedural CLI operation with a single happy path. Not conceptually rich, not especially code-heavy.
- **Inputs Needed:** Step-by-step CLI flow, JWT decode example.

#### SLT 200.5: "I can verify an Attestation JWT offline."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Developers write code for offline JWT verification (fetch jwks.json, decode, verify signature).
- **Inputs Needed:** Node/Python snippet for JWKS fetch + RS256 verification.

### Module 300 — Reading Andamio

#### SLT 300.1: "I can interpret the `source` field on Andamio course and project responses."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Reading and interpreting an API response field.
- **Inputs Needed:** Example responses showing `db_only`, `chain_only`, `merged` with annotation.

#### SLT 300.2: "I can navigate the Andamio gateway OpenAPI spec to find the right endpoint for a task."
- **Lesson Type:** Developer Documentation
- **Key Factors:** "Navigate" in knowledge base = Product Demo, but the surface here is a YAML spec file, not a UI. `interface_determines_type` override.
- **Inputs Needed:** Walkthrough of finding an endpoint in `andamio-api.yaml` via grep, jq, or a spec viewer.

#### SLT 300.3: "I can query a user's Andamio credentials and interpret the response."
- **Lesson Type:** Developer Documentation
- **Key Factors:** API call + response interpretation. Clear Dev Doc.
- **Inputs Needed:** CLI/API call example, field-by-field annotation of the response payload.

#### SLT 300.4: "I can map each Andamio `tx_type` to its build endpoint."
- **Lesson Type:** Developer Documentation
- **Key Factors:** API reference work; the artifact is a lookup table.
- **Inputs Needed:** `andamio tx types` output + the mapping table from SYSTEM_REFERENCE.md §5.

### Module 400 — The Transaction State Machine

#### SLT 400.1: "I can describe each step of the Andamio TX state machine."
- **Lesson Type:** Exploration
- **Key Factors:** "describe" + conceptual pattern.
- **Inputs Needed:** Framing: "Why does Andamio split writes into five steps?"

#### SLT 400.2: "I can explain why `updated` is the only safe TX status for refetching data."
- **Lesson Type:** Exploration
- **Key Factors:** "explain why" + design rationale (chain confirmation vs DB sync).
- **Inputs Needed:** A concrete bug scenario showing what happens if you refetch on `confirmed`.

#### SLT 400.3: "I can execute an Andamio transaction through its full state machine."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Procedure involves API calls + CLI + code. Dev Doc captures the full surface under the CLI.
- **Edge Notes:** Hybrid with How To Guide. Chose Dev Doc because the lesson should expose the API bodies that `tx run` wraps.
- **Inputs Needed:** Manual step-by-step TX execution + `tx run` equivalent side by side.

#### SLT 400.4: "I can diagnose and respond to Andamio TX failures."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Error handling in code; each failure mode needs a code example of the right response.
- **Inputs Needed:** Sample implementation covering the five failure modes (build, sign, submit, expiry, DB sync).

#### SLT 400.5: "I can explain which commitment states revert on TX expiry."
- **Lesson Type:** Exploration
- **Key Factors:** State-machine semantics are conceptual. Understanding the PENDING_TX_COMMIT and PENDING_TX_LEAVE exceptions is about protocol design, not procedure.
- **Inputs Needed:** Framing question: "What commitment state would be lost if PENDING_TX_COMMIT reverted?"

### Module 500 — Courses End-to-End

#### SLT 500.1: "I can explain how Andamio courses are structured."
- **Lesson Type:** Exploration
- **Key Factors:** Literal match to `andamio-for-contributors` classification in the knowledge base.
- **Inputs Needed:** Framing: "Why does a course need modules *and* SLTs *and* lessons?"

#### SLT 500.2: "I can compute an `slt_hash` for a course module."
- **Lesson Type:** Developer Documentation
- **Key Factors:** CLI command with concrete output; the hash encoding is a developer-facing concept.
- **Inputs Needed:** `andamio course credential compute-hash` example with input/output.

#### SLT 500.3: "I can publish a course module on-chain."
- **Lesson Type:** Developer Documentation
- **Key Factors:** CLI/API-driven publish. Involves the `modules_manage` TX body shape.
- **Inputs Needed:** Canonical `modules_manage` TX body (already in the drift-audit fixes) + discovery steps for slt_hash.

#### SLT 500.4: "I can explain the course assignment commitment lifecycle."
- **Lesson Type:** Exploration
- **Key Factors:** FSM conceptual understanding — design rationale, not procedure.
- **Inputs Needed:** Framing: "Why do assignments have fewer states than tasks?"

#### SLT 500.5: "I can run a full course lifecycle on Andamio."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Integration tutorial — chained API calls end-to-end. `course-lifecycle.sh` (post-drift-fix) becomes the teaching artifact.
- **Inputs Needed:** The fixed `course-lifecycle.sh` walkthrough, with each TX explained.

### Module 600 — Projects End-to-End

#### SLT 600.1: "I can explain how Andamio projects differ from courses."
- **Lesson Type:** Exploration
- **Key Factors:** Conceptual comparison; Bloom: Analyze.
- **Inputs Needed:** Side-by-side framing of course vs project mechanics (treasury, escrow, three-way outcomes).

#### SLT 600.2: "I can compute a `task_hash` for a project task."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Parallel to 500.2 — CLI command + encoding concept (contrast with slt_hash).
- **Inputs Needed:** Task hash computation example + comparison to slt_hash encoding.

#### SLT 600.3: "I can explain the project task commitment lifecycle."
- **Lesson Type:** Exploration
- **Key Factors:** Parallel to 500.4.
- **Inputs Needed:** Framing: "Why three outcomes for tasks but only two for assignments?"

#### SLT 600.4: "I can run a full project lifecycle on Andamio."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Parallel to 500.5 — `project-lifecycle.sh` becomes the teaching artifact.
- **Inputs Needed:** The fixed `project-lifecycle.sh` walkthrough with contributor_state_id + task_hash discovery steps.

### Module 700 — Build Something Real

#### SLT 700.1: "I can choose the right Andamio integration strategy for a use case."
- **Lesson Type:** Exploration
- **Key Factors:** Decision-making, Bloom: Evaluate. Trade-off analysis between CLI, gateway API, and app template.
- **Inputs Needed:** Framing: "What drives the choice between CLI, direct API, and app template?"

#### SLT 700.2: "I can estimate the ADA cost of an Andamio user flow."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Uses `cost-registry.json` as a machine-readable reference. Calculation against a spec file.
- **Inputs Needed:** Cost estimation script example reading `cost-registry.json`.

#### SLT 700.3: "I can handle Andamio TX failure modes gracefully in code."
- **Lesson Type:** Developer Documentation
- **Key Factors:** "in code" is explicit. Code-first capability.
- **Inputs Needed:** Sample implementation with retry/rollback/surface-to-user for each failure mode.

#### SLT 700.4: "I can ship a minimal working Andamio integration."
- **Lesson Type:** Developer Documentation
- **Key Factors:** Capstone — the whole point is producing code. App template surfaces here as a concrete starting point.
- **Inputs Needed:** Integration template or scaffold; the app template is the natural fit.

#### SLT 700.5: "I can critique the Andamio developer experience after building on it."
- **Lesson Type:** Exploration
- **Key Factors:** Reflective, Bloom: Evaluate. Invites open-ended critique of the learner's own experience.
- **Inputs Needed:** Framing question: "What would you change about building on Andamio?" Ties into the `/compound` skill.

## Heuristics developed (feed back into knowledge base)

### New verb patterns observed

- **verb: "map"** → Developer Documentation (high confidence in API-reference contexts). Seen in 300.4. Previously not in heuristics.
- **verb: "interpret"** → Developer Documentation when subject is API response data. Seen in 300.1, 300.3.
- **verb: "critique"** → Exploration (Bloom: Evaluate). Seen in 700.5. Previously not in heuristics.
- **verb: "compute"** → Developer Documentation when the subject is a hash or other code-produced artifact. Seen in 500.2, 600.2.

### New meta-heuristic: developer courses

**Pattern name:** `developer_course_distribution`
**Description:** Courses where the learner is building on top of an API/CLI typically distribute ~50% Developer Documentation + ~40% Exploration + small minorities of How To Guide (setup) and Product Demo (external tools). Product Demo is near-zero because there's no platform UI to demo. Organization Onboarding is zero unless the course is org-specific.
**Confidence:** Medium (based on this single course; validates with more data)
**Courses seen in:** build-on-andamio
**Date:** 2026-04-04

### Verb override: interface determines type (reconfirmed)

The `interface_determines_type` meta-heuristic held strongly across this classification:
- "mint" flipped Product Demo → Developer Documentation (200.2)
- "publish" flipped Product Demo → Developer Documentation (500.3)
- "navigate" flipped Product Demo → Developer Documentation (300.2)

The common cause: all three verbs were mapped to Product Demo in Andamio's UI-first courses, but this course's interface is CLI + API + code. The verb alone does not determine the type — the interface does.

## Context shopping list

### Code examples needed (Developer Documentation — 16 SLTs)

- [ ] **200.2** — `andamio tx run /v2/tx/global/user/access-token/mint` minimal body + tx_hash inspection
- [ ] **200.5** — JWKS fetch + RS256 verification snippet (Node or Python)
- [ ] **300.1** — Example API responses showing `source: db_only`, `chain_only`, `merged` with interpretation
- [ ] **300.2** — Walkthrough of locating an endpoint in `andamio-api.yaml` via grep + jq
- [ ] **300.3** — `andamio user credentials list` + field-by-field annotation
- [ ] **300.4** — `andamio tx types --output json` + mapping table
- [ ] **400.3** — Single TX executed manually step-by-step vs `tx run` comparison
- [ ] **400.4** — Error-handling snippet covering the 5 failure modes
- [ ] **500.2** — `andamio course credential compute-hash --slt "..."` with input/output
- [ ] **500.3** — Full `modules_manage` TX body (canonical shape from the drift audit)
- [ ] **500.5** — End-to-end course lifecycle (fixed `course-lifecycle.sh` is the reference)
- [ ] **600.2** — `task_hash` computation + encoding comparison to `slt_hash`
- [ ] **600.4** — End-to-end project lifecycle (fixed `project-lifecycle.sh` is the reference)
- [ ] **700.2** — Cost-estimation script reading `cost-registry.json`
- [ ] **700.3** — Sample failure-handling implementation
- [ ] **700.4** — Capstone integration template (likely leveraging the app template)

### Framing questions needed (Exploration — 13 SLTs)

- [ ] **100.1** — What makes "contribution-centered" different from "credential-centered" learning?
- [ ] **100.4** — When should a developer reach for Learning vs Ops mode?
- [ ] **200.1** — Why self-sovereign identity, and what does "access token" actually secure?
- [ ] **200.3** — When is a long-lived read key acceptable vs when do you need the user's JWT?
- [ ] **400.1** — Why does Andamio split writes into five steps?
- [ ] **400.2** — What bug could be caused by refetching too early?
- [ ] **400.5** — What commitment state would be lost if `PENDING_TX_COMMIT` reverted?
- [ ] **500.1** — Why does a course need modules *and* SLTs *and* lessons?
- [ ] **500.4** — Why do assignments have fewer states than tasks?
- [ ] **600.1** — Why does Andamio need two separate domains (course vs project)?
- [ ] **600.3** — Why three outcomes (accept/refuse/deny) for tasks but only two for assignments?
- [ ] **700.1** — CLI vs API vs app template — what drives the choice?
- [ ] **700.5** — What would you change about building on Andamio?

### How-to procedures needed (How To Guide — 2 SLTs)

- [ ] **100.2** — CLI install on macOS / Linux / Windows (brew + alternatives)
- [ ] **200.4** — Headless login flow with `andamio user login --skey`

### Screenshots needed (Product Demo — 1 SLT)

- [ ] **100.3** — Cardano preprod faucet flow (paste address → receive ADA) — or convert to HTG if we prefer prose
