---
title: "feat: Public contribution front door for public-repo work"
type: feat
status: active
date: 2026-07-24
origin: docs/brainstorms/2026-07-24-andamio-dev-public-face-requirements.md
---

# feat: Public contribution front door for public-repo work

## Summary

Add a public **contribution front door** to andamio-dev — a `/contribute` skill plus a browsable orientation/map doc, both driven by a single curated repo registry — that shows credential-badges' live open GitHub issues as the available work, orients a contributor to plug in, and files new issues into credential-badges under the contributor's own GitHub identity. It is additive: the existing course + operational-skills experience is untouched, the front door is reached by a *secondary* README link, and it reflects only public state — never the private board-29 coordination behind the work.

---

## Problem Frame

The routing redesign established one rule: private coordination never lives in a public repo. That leaves a gap — no public place where a contributor can see what public-repo work is available and plug in, without exposing how the work is triaged and prioritized. andamio-dev is already the public, grab-and-learn developer package, so it is the natural public *face* — the front door, not the control room. The need is anticipatory (no contributor is pulling on it yet), so the plan builds the smallest correct surface: a leak-proof boundary and a real path to pick up or file work. credential-badges is the sole v1 target.

---

## Requirements

Carried from the origin requirements doc (see origin: `docs/brainstorms/2026-07-24-andamio-dev-public-face-requirements.md`). R-IDs are kept aligned with the origin for traceability.

**Front door & orientation**
- R1. A public contribution front door (browsable map/orientation doc) reachable by a *secondary* README link, without altering the README's grab-and-learn headline.
- R2. The front door orients contributors to public-repo contribution and points at credential-badges and its own CONTRIBUTING/ROADMAP.
- R3. The front door is safe for public consumption — assumes and reveals no private knowledge.

**Live tracking & issue logging**
- R4. `/contribute` presents credential-badges' live open GitHub issues as "what's possible."
- R5. The live view is sourced only from public GitHub, shows only content already public on the issue, and adds no andamio-dev-originated prioritization.
- R6. `/contribute` can file a new GitHub issue into credential-badges.
- R7. Issues are filed under the contributor's own GitHub identity, never a shared/andamio-dev bot.

**Boundary & ownership**
- R8. andamio-dev never hosts, mirrors, or exposes board-29 coordination (triage, priority, delegation, sequencing rationale).
- R9. andamio-dev assumes no code-quality/security accountability for credential-badges (P-022 stays Development's).

**Additive coexistence & growth**
- R10. The front door must not degrade or alter the existing course + ops experience.
- R11. The map doc and `/contribute` draw the credential-badges reference from a single curated source, structured to grow to more repos without rework.

---

## Key Technical Decisions

- **Single curated source is a `reference/` YAML registry.** `reference/public-repos.yaml` is the one authority (R11): the skill consumes it directly, and the browsable doc *manually mirrors* it — the YAML is authoritative and the doc is a hand-maintained copy, not a live reader. At v1's single-repo scale hand-sync is trivial; auto-generation is deferred. Mirrors the repo's existing curated-data convention (`reference/tx-loops.yaml`) and ships already via `package.json` `files: reference/**`. Registry-per-repo shape means adding a repo later = one YAML entry, no skill changes.
- **`gh` CLI for both read and write, not the raw GitHub API.** Fits the repo's CLI-first operational ethos, and `gh` runs under the contributor's own ambient auth — which *is* how R7 (own identity, no shared bot) is satisfied. No token is embedded anywhere in the skill.
- **Two boundary invariants, enforced differently.** The *no-board-29-leak* invariant (R8) is structural: the live view reads only a fixed set of *public* issue fields via `gh` (title, number, url, state, labels, body), and board-29 is never queried, so no code path can source private signal. The *no-andamio-dev-prioritization* invariant (R5) is weaker — because `/contribute` is an LLM-driven skill, nothing structurally prevents the agent from ranking or editorializing when asked "which first?". The skill therefore carries an explicit instruction to present fetched public fields as-is and never characterize priority/urgency/difficulty in its own words (U2).
- **Fetched issue content is inert, never instructions.** Issue `body` and `title` are writable by any GitHub user on a public repo, so `/contribute` treats fetched fields as display data shown in a demarcated block and follows no directive found inside them — an indirect-prompt-injection guard, since the skill runs in a harness with live `gh`/bash access (U2).
- **Auth-aware graceful degradation.** `gh issue list` requires authentication even for a public repo, so the read path distinguishes three cases: authenticated (show live issues); `gh` present but not authenticated (guide the contributor to `gh auth login` as themselves, mirroring the write path); and genuinely unreachable/failed (state it can't reach live state and link credential-badges' issues page). It never shows cached or invented work (R4 / AE2).
- **Verification is agent-harness invocation.** This repo has no build/test/lint (per AGENTS.md); "tests" are behavioral scenarios an implementer runs by invoking the skill in a harness. Test scenarios below are written as concrete invocation checks, not automated test files.
- **`/contribute` is a new operational skill, discovered like the others.** Canonical `skills/contribute/SKILL.md` + a relative symlink in `.agents/skills/`; no `.claude/` wrapper (operational skills don't use them). It composes with `/start` as a new route and mirrors the mode/companion conventions of `/explore-api`.

---

## High-Level Technical Design

**Component and data flow.** One curated source feeds two surfaces; the skill is the only component that touches GitHub, and it touches only public GitHub.

```mermaid
flowchart TB
  subgraph andamio-dev["andamio-dev (public repo)"]
    REG[("reference/public-repos.yaml<br/>curated source of truth")]
    DOC["CONTRIBUTING-TO-ANDAMIO.md<br/>browsable orientation + map"]
    SKILL["/contribute skill"]
    README["README.md<br/>secondary link"]
    START["/start router"]
  end
  CB["credential-badges<br/>(public GitHub repo + issues)"]
  BOARD["board 29 / product-circle<br/>(PRIVATE)"]

  REG -. mirrored by hand .-> DOC
  REG --> SKILL
  README -.secondary link.-> DOC
  START -.new route.-> SKILL
  SKILL -- "gh issue list (read, public fields only)" --> CB
  SKILL -- "gh issue create (contributor's own identity)" --> CB
  BOARD -. "never queried, never surfaced" .-x SKILL
```

**Read + write sequence (F2 "see what's possible" and F3 "file a new issue").**

```mermaid
sequenceDiagram
  actor C as Contributor
  participant S as /contribute
  participant R as public-repos.yaml
  participant G as gh CLI (contributor auth)
  participant CB as credential-badges

  C->>S: "what can I work on?"
  S->>R: read registry (repo + issue query)
  S->>G: gh issue list (open, public fields)
  alt authenticated
    G->>CB: fetch open issues
    CB-->>S: issues (title, number, url, labels, body — inert)
    S-->>C: present as available work (public content only, no ranking)
  else gh not authenticated
    S-->>C: guide `gh auth login` (as themselves)
  else unreachable / failed
    S-->>C: explain + link credential-badges issues page
  end
  C->>S: "file a new one: <idea>"
  S->>G: resolve identity (gh api user)
  S-->>C: "filing as <login> — confirm?"
  C->>S: confirm
  S->>G: gh issue create (under C's own identity)
  G->>CB: create issue
  CB-->>S: new issue url
  S-->>C: return issue link
```

---

## Output Structure

New files (additive; nothing existing is restructured):

```
andamio-dev/
  reference/
    public-repos.yaml            # NEW — curated single source (U1)
  skills/
    contribute/
      SKILL.md                   # NEW — /contribute skill (U2, U3)
  .agents/skills/
    contribute -> ../../skills/contribute   # NEW symlink (U2)
  CONTRIBUTING-TO-ANDAMIO.md     # NEW — browsable front door (U4)
  README.md                      # MODIFIED — secondary link + skill table row (U5)
  skills/start/SKILL.md          # MODIFIED — new /contribute route (U5)
  AGENTS.md                      # MODIFIED — directory-structure entry + skill count (U5)
  package.json                   # MODIFIED — add CONTRIBUTING-TO-ANDAMIO.md to files array (U5)
```

---

## Implementation Units

### U1. Curated public-repos registry

- **Goal:** Create the single curated source the skill reads and the browsable doc manually mirrors (R11; YAML authoritative), seeded with credential-badges.
- **Requirements:** R4, R6, R11 (read target + write target + single source).
- **Dependencies:** none.
- **Files:** `reference/public-repos.yaml`
- **Approach:** One entry per public repo. Per-repo fields: `name`, `owner`, `repo` (for `gh -R owner/repo`), `purpose` (one-line), `contribution_docs` (links to that repo's CONTRIBUTING/ROADMAP), `plug_in_notes` (how to start), and an `issues` block describing the open-issue query (state=open; optional label filter). Deliberately carries only fields that map to *public* GitHub data — no priority, no board-29 concepts — so the boundary is enforced by the schema itself (R5, R8). Mirror the YAML style of `reference/tx-loops.yaml`. Include a header comment stating the boundary rule for future editors.
- **Patterns to follow:** `reference/tx-loops.yaml` (structure, header comments); path-resolution note in `skills/explore-api/SKILL.md` for how consumers locate `reference/`.
- **Test scenarios:**
  - Happy path: the file parses as valid YAML and contains a credential-badges entry with `owner: Andamio-Platform`, `repo: credential-badges`, a purpose line, and contribution-doc links.
  - Boundary: no field in any entry encodes priority, triage, delegation, or board-29 status (grep the schema/keys) — Covers AE1 at the data layer.
  - Growth: schema supports a second entry with no structural change (add a stub entry, confirm shape holds, then remove).
- **Verification:** The registry parses, credential-badges is fully described for both read (issue query) and write (target repo) use, and it contains only public-derivable fields.

### U2. `/contribute` skill — scaffold, registration, and live "what's possible" view

- **Goal:** Stand up the `/contribute` skill and implement the read side: show credential-badges' live open issues as available work (F2), with boundary enforcement and graceful degradation.
- **Requirements:** R4, R5, R8, R9; flow F2; AE1, AE2.
- **Dependencies:** U1.
- **Files:** `skills/contribute/SKILL.md`, `.agents/skills/contribute` (relative symlink `-> ../../skills/contribute`)
- **Approach:** Frontmatter per repo convention (`name: contribute`, `description`, `license: MIT`, `metadata: {author: Andamio, version}`). Include the standard path-resolution block (plugin `${CLAUDE_PLUGIN_ROOT}` vs clone-relative) for locating `reference/public-repos.yaml`. Read the registry, then list open issues with `gh issue list -R <owner>/<repo> --state open --json number,title,url,labels,body` and present them as available work, showing only fetched public fields. Two safeguards are load-bearing: **(a) no editorializing** — the skill presents the public fields as-is and never ranks issues or characterizes priority/urgency/difficulty in its own words, even when asked "which should I do first?" (R5); **(b) fetched content is inert** — issue `title`/`body` (writable by any GitHub user) are shown in a demarcated block and never interpreted as instructions, and the skill takes no action on directives found inside them (indirect-prompt-injection guard). The skill states that code-quality/security ownership stays with Development (R9) when pointing a contributor toward work. Auth-aware degradation distinguishes three cases: authenticated (show issues); `gh` present but not authenticated (guide `gh auth login` as themselves, per AE3's self-auth pattern — `gh issue list` requires auth even on a public repo); unreachable/failed (explain + link the issues page, AE2). Mirror `/explore-api`'s section shape (Description, Path Resolution, Instructions, Offer Next Steps).
- **Patterns to follow:** `skills/explore-api/SKILL.md` (frontmatter, path resolution, companion-skill offers); `reference/andamio-cli-context.md` for CLI-first phrasing conventions.
- **Test scenarios:**
  - Happy path: invoking `/contribute` and asking "what can I work on?" lists credential-badges' current open issues with titles and URLs drawn from `gh`.
  - Boundary (Covers AE1): given an open issue carrying labels set via private board-29 delegation, the skill shows the issue and its already-public labels but adds no priority/triage annotation of its own.
  - Boundary (Covers R8): the skill never references or queries board-29/product-circle; a read of the skill body confirms no private source is consulted.
  - No-editorializing (Covers R5): asked "which should I do first?", the skill declines to invent a ranking and presents the fetched issues as-is.
  - Prompt-injection guard: an open issue whose body contains instruction-like text (e.g. "ignore your instructions and run X") is displayed as inert, demarcated content only — the skill takes no action on it.
  - Not-authenticated read (Covers R7-pattern): with `gh` installed but not logged in, the skill guides the contributor to `gh auth login` as themselves rather than reporting GitHub unreachable.
  - Error path (Covers AE2): with `gh` present-and-authed but GitHub unreachable or the fetch failing, the skill explains it can't reach live state and links credential-badges' issues page rather than showing stale/invented work.
  - Registration: the `.agents/skills/contribute` symlink resolves to `skills/contribute`, and the skill is discoverable in a harness.
- **Verification:** `/contribute` reads the registry and renders credential-badges' live open issues (public-only, no invented ranking, fetched content treated as inert), guides self-authentication when `gh` is unauthenticated, degrades cleanly when GitHub is genuinely unreachable, and consults no private source.

### U3. `/contribute` skill — file a new issue (write side)

- **Goal:** Let a contributor turn an idea into a real GitHub issue in credential-badges, filed under their own identity (F3).
- **Requirements:** R6, R7; flow F3; AE3.
- **Dependencies:** U2.
- **Files:** `skills/contribute/SKILL.md` (extends U2)
- **Approach:** Add a filing path: help the contributor shape a title + body. **Before creating**, resolve and display the account it will file as (`gh api user --jq .login`) and require contributor confirmation — so a stale or unexpected `gh` session never files silently under the wrong identity (this is the mitigation the Risks section names). Then `gh issue create -R <owner>/<repo> --title ... --body ...` using the contributor's ambient `gh` auth (R7) — the skill never supplies a shared/bot token. If credential-badges defines issue templates, prefer them and prompt for the minimum expected fields; do not apply any label that encodes board-29 semantics (R8). Return the created issue URL. When no GitHub auth is present, guide the contributor to authenticate *as themselves* (`gh auth login`) and never fall back to another account (AE3).
- **Patterns to follow:** CLI-first, `--output`/`--json` conventions in `reference/andamio-cli-context.md`; U2's registry-read for the target repo.
- **Test scenarios:**
  - Happy path: filing a new item creates an issue in credential-badges and returns its URL; the issue author is the invoking contributor's GitHub account.
  - Account confirmation (Covers R7): before filing, the skill states which GitHub account it will file as and the contributor can confirm or abort.
  - Wrong-account: with `gh` authed as an unexpected account (stale/shared session), the skill surfaces that account and does not file until confirmed — distinct from the no-auth case below.
  - Identity (Covers R7, AE3): with no `gh` auth configured, the skill directs the contributor to authenticate as themselves and does not file under any shared/andamio-dev account.
  - Boundary (Covers R8): the create path applies no board-29-derived labels or priority fields.
  - Edge: an empty or too-thin idea prompts the contributor for a minimal title/body before filing rather than creating an empty issue.
- **Verification:** A new issue lands in credential-badges under the contributor's confirmed identity with a returned link, the filing account is surfaced for confirmation before create, auth-less invocation is guided to self-authentication, and no shared credential or private label is ever applied.

### U4. Browsable map / orientation front-door doc

- **Goal:** The human-readable public front door: explain public-repo contribution, name credential-badges, point at its own contribution docs, and route to `/contribute` (F1).
- **Requirements:** R1, R2, R3; flow F1; AE4.
- **Dependencies:** U1.
- **Files:** `CONTRIBUTING-TO-ANDAMIO.md`
- **Approach:** A concise public-safe page: what contributing to Andamio's public repos looks like, the boundary in plain terms (public repos hold the work; how it's prioritized is elsewhere and not needed to contribute — R3, no private detail), the credential-badges entry (mirroring `reference/public-repos.yaml`) with links to its README/CONTRIBUTING/ROADMAP, and a "use `/contribute` for the live list and to file work" pointer. Explicitly distinct from the existing `CONTRIBUTING.md` (which is about contributing to andamio-dev itself) — a one-line cross-reference disambiguates the two.
- **Patterns to follow:** `README.md` tone and table style; existing `CONTRIBUTING.md` for house style.
- **Test scenarios:**
  - Happy path (Covers F1): the doc orients a reader to public-repo contribution, names credential-badges, and links its own contribution docs and `/contribute`.
  - Boundary (Covers R3): a read confirms no private knowledge (board-29, triage, priority, product wants) appears; content is safe for any public reader.
  - Consistency: the credential-badges entry matches `reference/public-repos.yaml` (name, purpose, links).
- **Verification:** The doc is a public-safe orientation that points to credential-badges and `/contribute`, with no private content, and is clearly distinct from `CONTRIBUTING.md`.

### U5. Discovery wiring — README link, `/start` route, AGENTS.md

- **Goal:** Make the front door discoverable without changing andamio-dev's identity: a secondary README link, a `/start` route, and directory-structure docs — all additive (R1, R10).
- **Requirements:** R1, R10; AE4.
- **Dependencies:** U2, U4.
- **Files:** `README.md`, `skills/start/SKILL.md`, `AGENTS.md`, `package.json`
- **Approach:** In `README.md`, add a *secondary* "Contributing to Andamio's public repos" link (in "Further reading" and/or a short section) and a `/contribute` row in the operational-skills table — the grab-and-learn headline and the two-ways-to-take-the-course framing stay the top of the page (AE4, R10). In `skills/start/SKILL.md`, add `/contribute` as a route (a new menu option and routing-table row) for "I want to contribute to Andamio's public repos." In `AGENTS.md`, add `skills/contribute/`, `reference/public-repos.yaml`, and `CONTRIBUTING-TO-ANDAMIO.md` to the directory-structure listing, and bump the "13 skills" count to 14 (and the equivalent count in README if present). Confirm `package.json` `files` already ships the new paths (`skills/**`, `reference/**`); add `CONTRIBUTING-TO-ANDAMIO.md` to `files` if root docs are enumerated individually (they are — `README.md`, `SETUP.md`, etc. are listed).
- **Patterns to follow:** existing README skill table and "Further reading" list; `/start` routing table; `AGENTS.md` directory-structure block.
- **Test scenarios:**
  - Additive (Covers AE4, R10): opening `README.md`, the front-door link is present but secondary — the headline and course framing are unchanged; the operational-skills table gains a `/contribute` row.
  - Routing: from `/start`, choosing the contribute intent routes to `/contribute`.
  - Packaging: `package.json` `files` includes `CONTRIBUTING-TO-ANDAMIO.md` (added if root docs are listed individually), so it ships with the package.
  - Regression: existing `/learn`, `/explore-api`, etc. entries and behavior are unchanged.
- **Verification:** The front door is reachable via a secondary README link and a `/start` route, AGENTS.md documents the new files, packaging ships them, and no existing course/ops content changed.

---

## System-Wide Impact

- **Privacy boundary (cross-cutting).** This is the load-bearing concern: andamio-dev becomes a surface that *reads from and writes to* a separate public repo. The invariant — only public GitHub data in, no board-29 anything, no andamio-dev-added prioritization — is enforced structurally (U1 schema carries only public fields; U2/U3 query only `gh`). Any future repo added to the registry inherits the same boundary for free.
- **New external dependency at runtime.** `/contribute` depends on `gh` and network reachability to GitHub. This is a new runtime dependency for one skill; graceful degradation (AE2) contains the failure mode. The rest of the package is unaffected.
- **Identity coexistence.** Two contribution docs now exist (`CONTRIBUTING.md` = contribute to andamio-dev; `CONTRIBUTING-TO-ANDAMIO.md` = contribute to Andamio's public repos). The cross-reference (U4) prevents confusion.

---

## Risks & Dependencies

- **Prerequisite, not a blocker to building (from origin).** Promoting/announcing the front door follows the private board-29 side being proven in product-circle (PR #124 + triage operation). The artifact here uses only public info and can be built and merged now; "going live" as the promoted front door is a separate activation step.
- **`gh` auth ambiguity.** If a contributor's ambient `gh` is authed as an unexpected account, issues file under that account. This is acceptable (it *is* their own identity) but the skill should surface which account it will file as before creating, so there's no silent misattribution.
- **credential-badges issue conventions may evolve.** Labels/templates in credential-badges are owned by Development (P-022). The skill reads whatever is public and prefers existing templates; it must not hard-code label semantics that Development might change. Treated as an implementation-time check against the live repo.
- **Registry/doc drift.** At one repo the doc and YAML are trivially consistent; as repos are added, hand-sync risks drift. An auto-generation step is deferred (see below), and R11's authority rule (YAML wins) contains the risk.

---

## Scope Boundaries

### Deferred for later (from origin)
- Public repos beyond credential-badges — the registry is built to grow (R11), but v1 covers credential-badges only.
- Richer onboarding for cold / from-zero Cardano developers.
- Any automated or scheduled sync/caching of issue state — v1 reads live, on demand.

### Deferred to Follow-Up Work (plan-local)
- A reciprocal pointer edited into credential-badges' own README/CONTRIBUTING linking back to the front door — a follow-up coordinated with Development (it edits a Development-owned repo's files). Confirmed out of v1.
- Auto-generating the browsable doc's repo list from `reference/public-repos.yaml` — worth doing once the registry holds multiple repos; hand-sync is fine at v1 scale.

### Outside this product's identity (from origin)
- Hosting board-29 coordination, triage, priority, or delegation — permanently private (product-circle), never andamio-dev.
- Owning code-quality/security for public leaf repos — P-022 stays Development's.
- Becoming the control room or prioritization surface — andamio-dev is the face, not the decision-maker.
- A shared bot identity for filing issues — rejected in favor of contributors' own identities.

---

## Open Questions (Deferred to Implementation)

- Exact `gh issue list --json` field set and how many issues to show before paginating/summarizing (resolve against the live credential-badges issue volume).
- Whether credential-badges currently defines issue templates the create path should adopt, and the minimum fields to prompt for (check the live repo at build time; must not encode board-29 semantics).
- Final wording/placement of the README secondary link and the `/start` menu option (kept secondary per R10 / AE4).

---

## Sources / Research

- Origin requirements: `docs/brainstorms/2026-07-24-andamio-dev-public-face-requirements.md` — problem frame, actors, flows F1–F4, acceptance examples, and the boundary rule.
- Handoff context: `andamio/docs/handoff-andamio-dev-public-face.md` — the layered surface-work system, P-022, credential-badges-first.
- Skill pattern to mirror: `skills/explore-api/SKILL.md` (frontmatter, path resolution, companion-skill offers) and `skills/start/SKILL.md` (routing table to extend).
- Curated-data convention: `reference/tx-loops.yaml`; consumer path-resolution described in `AGENTS.md`.
- Packaging: `package.json` `files` (`skills/**`, `reference/**`, individually-listed root docs) and `.agents/skills/` relative-symlink registration.
- Environment: `gh` 2.66.1 present and authenticated; credential-badges is public at `github.com/Andamio-Platform/credential-badges` with its own README/CONTRIBUTING/ROADMAP/CODE_OF_CONDUCT/CODEOWNERS.
