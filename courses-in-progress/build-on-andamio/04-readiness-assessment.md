# Coaching Readiness Assessment — Build on Andamio

> **Note (2026-04-05):** This document reflects the pre-combine SLT numbering. After this assessment was produced, M200.1 (exploration) and M200.2 (dev doc) were merged into a single "Mint your access token" lesson, and M200.3–M200.5 were renumbered to M200.2–M200.4. Current authoritative SLT list is in `01-slts.md`.

**Date:** 2026-04-04 (initial) · updated 2026-04-05 (research pass) · updated 2026-04-05 (pedagogy brief landed)
**Assessed by:** `/coach:teacher` → `self-assess-readiness`
**Context:** Assessment performed immediately after a full SYSTEM_REFERENCE.md drift audit against `andamio-dev`, so protocol-mechanics knowledge is maximally fresh and verified.

## Summary

- **Total SLTs assessed:** 32
- **Current distribution:** **32 Ready · 0 Needs Context · 0 Needs Human**
- **Initial distribution:** 20 Ready · 12 Needs Context · 0 Needs Human
- **After research pass:** 31 Ready · 1 Needs Context (100.1) · 0 Needs Human
- **After pedagogy brief:** 32 Ready (100.1 unblocked by `andamio-ai-context/02-strategy/contribution-centered-learning.md`)
- **Overview:** Strong on protocol mechanics, FSMs, and body shapes (just audited). Weaker on specific CLI flag syntax and app template internals at first pass — closed during research. Zero SLTs require human expert review.

## Honesty calibration results

| Check | Result |
|---|---|
| API Signature Test | **Strong** for gateway TX body shapes (17 endpoints just verified); **Partial** for CLI flag specifics |
| Version Test | **Current** — SYSTEM_REFERENCE.md dated 2026-04-04, CLI v0.10.2, knowledge is fresh |
| Niche Library Test | **Flag applied** — Andamio is small-user-base; defaulting Code Demo to Partial unless explicit evidence from this session |
| Confabulation Test | **Low risk** for body shapes (verified); **moderate risk** for CLI flags; **higher risk** for attestation JWT claim schema |
| Assessment Test | **Strong** for body-shape drift (just did that work); **Partial** for Cardano-specific subtleties (CBOR edges, slot math) |
| Explanation Depth Test | **Three-deep** on Andamio protocol (SYSTEM_REFERENCE.md provides rationale); thinning on underlying Cardano design decisions |

## Readiness by module

| Module | Ready | Needs Context | Needs Human | Notes |
|--------|-------|---------------|-------------|-------|
| M100 Foundations | 3 | 1 | 0 | Only the contribution-centered pedagogy framing is thin |
| M200 Identity | 2 | 3 | 0 | Auth CLI specifics + attestation JWT schema |
| M300 Reading | 3 | 1 | 0 | Credentials endpoint response shape |
| M400 TX State Machine | 3 | 2 | 0 | Manual step CLI flags + error response shapes |
| M500 Courses | 4 | 1 | 0 | Strongest module — drift audit just covered it |
| M600 Projects | 3 | 1 | 0 | task_hash computation CLI path |
| M700 Build Something Real | 2 | 3 | 0 | App template internals + idiomatic failure-handling |

## Per-SLT assessment

| # | SLT | Conceptual | Code | Assessment | Currency | Overall |
|---|---|---|---|---|---|---|
| 100.1 | explain contribution-centered learning | Partial | N/A | Partial | Current | **Needs Context** |
| 100.2 | install the Andamio CLI | Strong | Strong | Strong | Current | **Ready** |
| 100.3 | fund a preprod wallet from faucet | Strong | N/A | Strong | Current | **Ready** |
| 100.4 | distinguish Learning vs Ops mode | Strong | N/A | Strong | Current | **Ready** |
| 200.1 | explain why writes need access token | Strong | N/A | Strong | Current | **Ready** |
| 200.2 | mint an access token on preprod | Strong | Partial | Strong | Current | **Needs Context** |
| 200.3 | distinguish API key from JWT | Strong | N/A | Strong | Current | **Ready** |
| 200.4 | log in headlessly with .skey | Strong | Partial | Strong | Current | **Needs Context** |
| 200.5 | verify an Attestation JWT offline | Strong | Partial | Partial | Current | **Needs Context** |
| 300.1 | interpret `source` field | Strong | Strong | Strong | Current | **Ready** |
| 300.2 | navigate OpenAPI spec | Strong | Strong | Strong | Current | **Ready** |
| 300.3 | query user credentials | Strong | Partial | Partial | Current | **Needs Context** |
| 300.4 | map tx_types to endpoints | Strong | Strong | Strong | Current | **Ready** |
| 400.1 | describe TX state machine steps | Strong | N/A | Strong | Current | **Ready** |
| 400.2 | explain why `updated` is safe | Strong | N/A | Strong | Current | **Ready** |
| 400.3 | execute TX through full SM | Strong | Partial | Strong | Current | **Needs Context** |
| 400.4 | diagnose + respond to TX failures | Strong | Partial | Partial | Current | **Needs Context** |
| 400.5 | explain expiry revert rules | Strong | N/A | Strong | Current | **Ready** |
| 500.1 | explain how courses are structured | Strong | N/A | Strong | Current | **Ready** |
| 500.2 | compute slt_hash for a module | Strong | Partial | Partial | Current | **Needs Context** |
| 500.3 | publish a course module on-chain | Strong | Strong | Strong | Current | **Ready** |
| 500.4 | explain assignment commitment FSM | Strong | N/A | Strong | Current | **Ready** |
| 500.5 | run full course lifecycle | Strong | Strong | Strong | Current | **Ready** |
| 600.1 | explain projects vs courses | Strong | N/A | Strong | Current | **Ready** |
| 600.2 | compute task_hash for a task | Strong | Partial | Partial | Current | **Needs Context** |
| 600.3 | explain task commitment FSM | Strong | N/A | Strong | Current | **Ready** |
| 600.4 | run full project lifecycle | Strong | Strong | Strong | Current | **Ready** |
| 700.1 | choose integration strategy | Strong | N/A | Partial | Current | **Needs Context** |
| 700.2 | estimate ADA cost | Strong | Strong | Strong | Current | **Ready** |
| 700.3 | handle TX failures in code | Strong | Partial | Partial | Current | **Needs Context** |
| 700.4 | ship a minimal integration | Strong | Partial | Partial | Current | **Needs Context** |
| 700.5 | critique Andamio DX | Strong | N/A | Strong | Current | **Ready** |

## Gap analysis (12 Needs Context SLTs)

### 100.1 — explain contribution-centered learning
- **Weak/Partial dimensions:** Conceptual (Partial), Assessment (Partial)
- **What I would need:** Brief framing content distinguishing "contribution-centered" from "credential-centered" learning specifically in Andamio's context. Currently my understanding is high-level / reconstructed.
- **Risk if coached without context:** Plausible but generic philosophy content that doesn't capture what makes Andamio distinct.

### 200.2 — mint an access token on preprod
- **Weak/Partial dimensions:** Code (Partial)
- **What I would need:** Exact CLI command for minting an access token via `andamio tx run`. I know the endpoint (`/v2/tx/global/user/access-token/mint`), the body shape, and that `initiator_data` is required (no alias yet). I don't know the exact CLI flag for passing the body.
- **Risk if coached without context:** Wrong flag name; confused positional vs keyword arguments.

### 200.4 — log in headlessly with .skey
- **Weak/Partial dimensions:** Code (Partial)
- **What I would need:** Verified syntax for `andamio user login --skey <path>` and confirmation of its return shape (does it print the JWT to stdout? store in config?).
- **Risk if coached without context:** Command name drift between CLI versions; wrong output handling.

### 200.5 — verify an Attestation JWT offline
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** Andamio's specific attestation JWT claim schema and a real example token. Generic JWT verification patterns I know well; Andamio's specific claims I'd confabulate.
- **Risk if coached without context:** Fabricated claim names; pattern that technically verifies but misses Andamio-specific fields.

### 300.3 — query user credentials
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** Exact gateway endpoint path and field-by-field example response. I saw credential-related endpoints in `andamio-api.yaml` during the drift audit but didn't read each response schema in depth.
- **Risk if coached without context:** Wrong endpoint path; fabricated response fields.

### 400.3 — execute a TX through full state machine
- **Weak/Partial dimensions:** Code (Partial)
- **What I would need:** Exact CLI flags for each of the five manual steps (`tx build`, `tx sign`, `tx submit`, `tx register`, `tx status`). The examples scripts use some; I'd want to verify the full set.
- **Risk if coached without context:** Flag drift across CLI versions; missing required flags.

### 400.4 — diagnose + respond to TX failures
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** Real API error response payloads for each of the five failure modes (build error, sign error, submit rejection, chain expiry, DB sync failure). I know the statuses; I don't know the exact error field shapes.
- **Risk if coached without context:** Fabricated error field names; error-handling code that doesn't match the real API surface.

### 500.2 — compute slt_hash for a module
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** Verified `andamio course credential compute-hash --slt "..."` syntax and output format. I used it in the fixed `course-lifecycle.sh` but haven't verified the exact flag or output shape.
- **Risk if coached without context:** Wrong flag; wrong assumption about output format (JSON vs plain hex).

### 600.2 — compute task_hash for a task
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** Determine whether a `task_hash` CLI helper exists. If not, document the alternative (fetch from andamioscan or compute manually).
- **Risk if coached without context:** Recommending a CLI command that doesn't exist.

### 700.1 — choose integration strategy
- **Weak/Partial dimensions:** Assessment (Partial)
- **What I would need:** Read the `andamio-app-template` repo (path: `~/projects/01-projects/andamio-platform/andamio-app-template/`) to understand its structure and capabilities, so my trade-off analysis between CLI / direct API / app template is complete.
- **Risk if coached without context:** Missing a real option; misstating what the template provides.

### 700.3 — handle TX failures in code
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** Sample failure-handling code from existing Andamio integrations. Generic retry/backoff patterns I can write; Andamio-idiomatic patterns I'd confabulate.
- **Risk if coached without context:** Non-idiomatic code recommended as best practice.

### 700.4 — ship a minimal integration
- **Weak/Partial dimensions:** Code (Partial), Assessment (Partial)
- **What I would need:** App template repo read (same as 700.1). Depends on #700.1 context being gathered first.
- **Risk if coached without context:** Scaffolding that doesn't match real app template structure.

## Lesson prioritization

### Tier 1: Build first (20 SLTs — Ready)

| # | SLT | Module | Rationale |
|---|---|---|---|
| 100.2 | install the Andamio CLI | M100 | Pure procedural, well-documented |
| 100.3 | fund a preprod wallet from faucet | M100 | External UI, stable process |
| 100.4 | distinguish Learning vs Ops mode | M100 | Plugin design I just defined |
| 200.1 | explain why writes need access token | M200 | SYSTEM_REFERENCE.md §2 covers this |
| 200.3 | distinguish API key from JWT | M200 | AUTH.md covers this |
| 300.1 | interpret `source` field | M300 | Just verified in drift audit |
| 300.2 | navigate OpenAPI spec | M300 | Literally did this in drift audit |
| 300.4 | map tx_types to endpoints | M300 | SYSTEM_REFERENCE.md §5 memorized |
| 400.1 | describe TX state machine steps | M400 | SYSTEM_REFERENCE.md §4 fully documented |
| 400.2 | explain why `updated` is safe | M400 | SYSTEM_REFERENCE.md §4.4/4.5 |
| 400.5 | explain expiry revert rules | M400 | SYSTEM_REFERENCE.md §7.3/8.3 |
| 500.1 | explain how courses are structured | M500 | Matches proven `andamio-for-contributors` classification |
| 500.3 | publish a course module on-chain | M500 | Body shape just fixed in drift audit |
| 500.4 | explain assignment commitment FSM | M500 | SYSTEM_REFERENCE.md §7 |
| 500.5 | run full course lifecycle | M500 | `course-lifecycle.sh` (post-fix) is the reference |
| 600.1 | explain projects vs courses | M600 | SYSTEM_REFERENCE.md §8/§10/§11 |
| 600.3 | explain task commitment FSM | M600 | SYSTEM_REFERENCE.md §8 |
| 600.4 | run full project lifecycle | M600 | `project-lifecycle.sh` (post-fix) is the reference |
| 700.2 | estimate ADA cost | M700 | `cost-registry.json` just verified |
| 700.5 | critique Andamio DX | M700 | I have opinions from this session's work |

### Tier 2: Build with context (12 SLTs — Needs Context)

Unlocked by the context shopping list below.

### Tier 3: Defer (0 SLTs — Needs Human)

None.

## Context shopping list (deduplicated, priority-ordered)

| # | Resource | Type | SLTs unlocked | Priority |
|---|---|---|---|---|
| 1 | **Andamio CLI command reference** — verified flags for `user login --skey`, `course credential compute-hash`, `tx build/sign/submit/register/status`, `project task list`, `tx run` | CLI reference | 200.2, 200.4, 400.3, 500.2, 600.2 | **HIGH** (5 SLTs) |
| 2 | **Andamio app template read-through** — `andamio-app-template` repo (alias `template` from global CLAUDE.md): scaffold, routes, auth wiring, integration points | Code read | 700.1, 700.4 | **HIGH** (2 SLTs) |
| 3 | **TX error response captures** — real gateway/Atlas error payloads for each of the 5 failure modes | API captures | 400.4, 700.3 | **MEDIUM** (2 SLTs) |
| 4 | **User credentials endpoint response** — exact path + field-by-field example | API reference | 300.3 | MEDIUM (1 SLT) |
| 5 | **Attestation JWT claim schema** — structure + example token | Spec + sample | 200.5 | LOW (1 SLT) |
| 6 | **Contribution-centered pedagogy framing** — brief content distinguishing from credential-centered | Conceptual content | 100.1 | LOW (1 SLT) |
| 7 | **Andamio-idiomatic failure-handling code** — sample implementations | Code examples | 700.3 | MEDIUM — depends on #2 |

## Set-level observations

- **Strength cluster:** Modules 500 and 600 — directly mirrored in SYSTEM_REFERENCE.md, which I just audited. Every body shape, FSM, and invariant is fresh and verified. These modules could be built immediately.
- **Weakness cluster:** Modules 200 and 700. Both depend on artifacts outside SYSTEM_REFERENCE.md — CLI syntax lives in CLI help/docs, and app template internals live in a separate repo (`andamio-app-template`).
- **Critical path:** Shopping list item #1 (CLI command reference) unlocks 5 SLTs across 4 modules. It's a single focused research task — reading `andamio --help` for each relevant subcommand, or re-reading `reference/andamio-cli-context.md` with fresh eyes (I edited this file in the drift audit).
- **Sequencing implication:** Module readiness does not suggest reordering — the pedagogical order (auth → read → write → domain → integrate) is required even though M300 is more Ready than M200.
- **Confabulation risk zones:** CLI flag names, TX error response shapes, app template internals, attestation JWT claims. All are one focused research session away from being resolved — none require a human expert.
- **Meta-observation:** Much of the "Needs Context" gap could be closed by reading more files in this working directory and sibling repos. A follow-up pass after the readiness artifact is saved could move several SLTs from Needs Context to Ready.
