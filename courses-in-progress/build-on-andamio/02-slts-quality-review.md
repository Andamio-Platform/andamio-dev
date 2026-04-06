# SLT Quality Review — Build on Andamio

**Date:** 2026-04-04
**Assessed by:** `/coach:teacher` → `assess-slts`
**Knowledge base consulted:** `quality-issues.yaml` (v1), `successful-rewrites.yaml` (v1), `slt-research-report.md`

## Summary

- **Total SLTs reviewed:** 35 initial, 32 final (3 removed during scope narrowing)
- **Initial distribution:** 4 Strong / 5 Acceptable / 26 Needs Work
- **Final distribution after rewrites and removals:** 32 Strong
- **Overall quality:** The underlying capabilities were sound; the wording needed to move details (assessment method, enumerated content, dual-capability chains) out of the SLT and into lesson/assignment criteria. Most fixes were mechanical.

## Flagged patterns found in initial draft

| Pattern | Occurrences | Knowledge-base frequency | Action taken |
|---|---|---|---|
| `by [verb]-ing` how-clause prescribing assessment method | 23 | 3 prior courses | Stripped across all 35 SLTs |
| Parenthetical/inline list prescribing content | 11 | 9 prior courses | Stripped; lists moved to lesson content |
| `and [second capability]` dual-capability | 13 | 3 prior courses | Merged or deleted the weaker half |
| `at least N` / `in N sentences` quantity prescription | 3 | 2 prior courses | Stripped; quantity moved to assignment criteria |

## SLTs removed during scope narrowing

Three SLTs were removed because the course scope was narrowed to gateway API + CLI + App Template only (Andamioscan, andamio-db-api, and andamio-atlas-api are out of scope as subjects).

| # | Original | Reason |
|---|---|---|
| 100.2 | I can describe the role of each service in the Andamio stack. | Internal architecture is no longer a subject — learners build the mental model through use. |
| 300.1 | I can explain the difference between the Andamio gateway API and andamioscan. | Andamioscan is no longer a subject. M300 still covers reading via the gateway alone. |
| 600.4 | I can explain the DenyProject indexer gap. | "Indexer" is internal vocabulary. The Deny limitation is a real warning for integrators but lives in the `/troubleshoot` skill as a known limitation, not in the curriculum. |

## Bloom's taxonomy distribution (32 final SLTs)

| Level | Count | Modules |
|---|---|---|
| Remember | 0 | — |
| Understand | 12 | M100, M200, M300, M400, M500, M600, M700 |
| Apply | 16 | M100, M200, M300, M400, M500, M600, M700 |
| Analyze | 3 | M400 (diagnose, explain reverts), M300 (interpret source) |
| Evaluate | 1 | M700.1 (choose strategy) |
| Create | 2 | M700.4 (ship integration), M700.5 (critique DX) |

Distribution is healthy: weighted toward Apply (appropriate for a "build on X" course), culminating in Evaluate/Create in the capstone. No clustering at low levels.

## Set-level observations

- **Prerequisite chain is clean.** M100 (setup) → M200 (identity) → M300 (read) → M400 (write mechanics) → M500 (course domain) → M600 (project domain) → M700 (integrate). Each module genuinely depends on the previous. Gating the curriculum with unlock-as-you-go is a natural fit.
- **No redundancy.** M500 and M600 mirror each other structurally (hierarchy → hash → lifecycle → full loop) but cover genuinely different on-chain mechanics. The symmetry is pedagogically helpful, not duplicative.
- **Ambition curve is right.** M100–M400 are 4–5 SLTs of Understand/Apply. M500–M600 pack the deepest Apply work (real on-chain TXs). M700 culminates at Evaluate/Create.
- **ADA cost for learners is real.** M500 ≈ 130 test ADA, M600 ≈ 395 test ADA (mostly recoverable, but requires the faucet to cooperate). Surface this in the M100 prerequisites.
- **Beachball candidates:** 100.2 (install CLI), 100.3 (fund wallet), 700.5 (critique DX) are intentionally lighter. They fit the `beachball_slt` pattern — early momentum, reflective close. Document the pedagogical purpose when writing lesson inputs.
- **App Template** is named as one of the three course pillars (gateway API, CLI, App Template) but is not a first-class SLT. It surfaces in M700 lessons as a concrete integration option, per the course author's decision.
