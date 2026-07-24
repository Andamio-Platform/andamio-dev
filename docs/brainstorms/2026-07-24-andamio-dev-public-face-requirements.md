---
date: 2026-07-24
topic: andamio-dev-public-face
---

# Andamio-dev public face — contribution front door for public-repo work

## Summary

Add a public **contribution front door** to andamio-dev — a `/contribute` skill plus a browsable orientation/map doc — that shows the live open GitHub issues in credential-badges as the available work, helps a contributor pick one up, and can file new issues into credential-badges under the contributor's own GitHub identity. It sits *alongside* the existing course + operational-skills experience without changing it, and reflects only public state — never the private coordination behind the work.

---

## Problem Frame

The routing redesign that moved surface coordination into the private coordination workspace established one hard rule: **private coordination never lives in a public repo.** That leaves a gap — there is no public place where someone who wants to contribute to Andamio's public repos can see what work is available and plug in, without exposing how the work is triaged and prioritized.

andamio-dev is already the public, grab-and-learn developer package, so it is the natural public *face* for that work — the front door, not the control room. Today no such front door exists. The need is **anticipatory**: no external contributor is pulling on this yet. We are defining the boundary and the smallest useful surface now, before contributors arrive, so the public face is correct when they do. credential-badges is the first public leaf repo and the sole v1 test target.

---

## Key Decisions

- **Additive, not a reframe.** The front door is a new surface layered onto andamio-dev; the existing course + operational skills and the README's grab-and-learn identity stay untouched. It is reached by a *secondary* README link, never the front page's headline.
- **Primary audience is semi-internal contributors.** v1 is designed for Andamio circle/ecosystem members who already contribute across repos and need a shared public map — not from-zero onboarding of cold Cardano developers. A cold visitor should not be actively misled, but is not the design target.
- **Two surfaces, one model.** A browsable orientation/map doc is the human-readable artifact; the `/contribute` skill is the interactive surface that reads live GitHub state and files issues. Both are native to andamio-dev's Agent Skills identity.
- **Live "what's open" from public GitHub only.** The available-work view reflects credential-badges' open GitHub issues, read via public GitHub. the private coordination is never a source, and andamio-dev adds no prioritization signal of its own — it shows only what is already public on the issue.
- **credential-badges' issues are the work queue; anybody executes.** Work is logged as public GitHub issues and picked up by anybody — James via compound-engineering directly in the repo, or a new contributor. the private coordination triages and prioritizes privately, *after* an issue exists.
- **Issue filing under the contributor's own identity.** New issues are created under the contributor's own GitHub account (their `gh` auth), not a shared andamio-dev bot — clean attribution, and it keeps code-quality/security ownership unambiguous.
- **Code-quality/security ownership stays Development's.** Being the public face does not make andamio-dev accountable for credential-badges' code quality or security; that stays Development's.

---

## Actors

- A1. Contributor (semi-internal) — an Andamio circle/ecosystem member who wants to find and take on public-repo work.
- A2. andamio-dev front door — the map doc + `/contribute` skill; orients, shows live open work, files new issues.
- A3. credential-badges — the public leaf repo; its GitHub issues are the work queue; owns its own CONTRIBUTING/ROADMAP and its code.
- A4. Development — owns code-quality/security accountability on public repos; coordinates the private triage.
- A5. Private coordination side (private) — where triage, priority, and delegation happen; never surfaced by A2.

---

## Key Flows

- F1. Discover and orient
  - **Trigger:** A contributor lands in andamio-dev (or follows a link) wanting to help.
  - **Actors:** A1, A2
  - **Steps:** Secondary README link → contribution front door → explains what public-repo contribution looks like and points at credential-badges and its own CONTRIBUTING/ROADMAP.
  - **Covered by:** R1, R2, R3

- F2. See what's possible (live)
  - **Trigger:** Contributor asks "what can I work on?" via `/contribute`.
  - **Actors:** A1, A2, A3
  - **Steps:** Skill reads credential-badges' open GitHub issues (public) → presents them as available work → links each to its GitHub issue. Shows only public content; adds no priority annotation.
  - **Covered by:** R4, R5, R8

- F3. File a new issue
  - **Trigger:** Contributor has a new piece of work not yet tracked.
  - **Actors:** A1, A2, A3
  - **Steps:** Skill helps shape the idea into an issue → files it into credential-badges under the contributor's own GitHub identity → returns the issue link. the private coordination triage happens privately afterward, outside andamio-dev.
  - **Covered by:** R6, R7, R8

- F4. Pick up and execute (leaves andamio-dev)
  - **Trigger:** Contributor chooses an open issue.
  - **Actors:** A1, A3, A4
  - **Steps:** Work happens in credential-badges' own compound-engineering flow; code-quality/security accountability stays Development's. andamio-dev's role ends at orientation, tracking, and logging.
  - **Covered by:** R9

---

## Requirements

**Front door & orientation**

- R1. andamio-dev hosts a public contribution front door (a browsable map/orientation doc) reachable by a *secondary* link from the README, without altering the README's existing grab-and-learn headline identity.
- R2. The front door orients a contributor to how public-repo contribution works and points at credential-badges and that repo's own contribution docs (CONTRIBUTING/ROADMAP).
- R3. The front door is written for public consumption — safe for anyone to read — even though its primary audience is semi-internal contributors; it assumes and reveals no private knowledge.

**Live tracking & issue logging**

- R4. A `/contribute` skill presents the live open GitHub issues in credential-badges as the available work ("what's possible").
- R5. The live view is sourced only from public GitHub; it reflects only content already public on the issue and adds no andamio-dev-originated prioritization signal.
- R6. The `/contribute` skill can file a new GitHub issue into credential-badges.
- R7. Issues are filed under the contributor's own GitHub identity (their `gh` auth), never a shared/andamio-dev bot account.

**Boundary & ownership**

- R8. andamio-dev never hosts, mirrors, or exposes the private coordination (triage, priority, delegation, or sequencing rationale) — those stay in the private coordination workspace.
- R9. andamio-dev assumes no code-quality or security accountability for credential-badges (that ownership stays Development's); its role is limited to orientation, live tracking, and issue logging.

**Additive coexistence & growth**

- R10. Adding the front door must not degrade or alter the existing course and operational-skills experience; the two coexist.
- R11. The map doc and the `/contribute` skill draw the credential-badges reference from a single curated source, so the two surfaces stay consistent and the model can grow to more public repos later without rework.

---

## Acceptance Examples

- AE1. **Covers R5, R8.** Given a credential-badges issue that carries labels or status set privately through the private coordination delegation, When `/contribute` shows the live view, Then it shows the issue and whatever is already public on it and adds no priority/triage annotation of its own.
- AE2. **Covers R4.** Given public GitHub is unreachable or the issue list cannot be fetched, When a contributor asks what's possible, Then the skill degrades gracefully — it explains it cannot reach live state and points to credential-badges' issues page — rather than presenting stale or invented work.
- AE3. **Covers R6, R7.** Given a contributor without GitHub auth configured, When they try to file a new issue, Then the skill guides them to authenticate as themselves and files under their identity — never falling back to a shared or andamio-dev account.
- AE4. **Covers R1, R10.** Given a first-time visitor who grabbed the repo for the course, When they open the README, Then the front-door link is present but secondary — the grab-and-learn path remains the headline and is unchanged.

---

## Scope Boundaries

**Deferred for later**

- Public repos beyond credential-badges — the model is built to grow (R11), but v1 covers credential-badges only.
- A reciprocal pointer edited into credential-badges' own README/CONTRIBUTING linking back to the front door — a follow-up, coordinated with Development (it touches a Development-owned repo's files).
- Richer onboarding for cold / from-zero Cardano developers.
- Any automated or scheduled sync/caching of issue state — v1 reads live, on demand.

**Outside this product's identity**

- Hosting the private coordination, triage, priority, or delegation — permanently private (the private coordination workspace), never andamio-dev.
- Owning code-quality or security for public leaf repos — code-quality/security ownership stays Development's.
- Becoming the control room or prioritization surface for public-repo work — andamio-dev is the face, not the decision-maker.
- A shared bot identity for filing issues — rejected in favor of contributors' own identities.

---

## Dependencies / Assumptions

- **Anticipatory build.** No external contributor is currently pulling on this; the need is expected, not yet observed. v1 optimizes for a correct boundary and the smallest useful surface, not scale.
- **Private side is a prerequisite to activation, not to building.** Promoting/announcing the front door follows the private coordination in the private coordination workspace being proven (the private-side coordination work + the triage operation). The public artifact itself can be built now — it uses only public information.
- **credential-badges is a usable public leaf repo.** It is public and already carries README, CONTRIBUTING, ROADMAP, CODE_OF_CONDUCT, and CODEOWNERS; its GitHub issues are usable as the public work queue.
- **Contributors can authenticate as themselves.** Filing issues assumes a contributor has (or can set up) their own GitHub auth (`gh`).
- **Public GitHub is the only integration surface.** Reading and writing issues uses public GitHub; no private API or board access is involved.

---

## Outstanding Questions (Deferred to Planning)

- Where the front-door doc lives in the repo, and how the single curated source (R11) is shaped so both the doc and the skill read it.
- How the skill reads live issues (gh CLI vs GitHub API) and how it authenticates the contributor for filing.
- What issue template or fields (if any) are applied on filing, and how to prompt for credential-badges' minimum expected fields — without encoding any the private coordination semantics.
- The exact graceful-degradation behavior when GitHub is unreachable (AE2 names the requirement; planning picks the handling).

---

## Sources / Research

- `andamio/docs/handoff-andamio-dev-public-face.md` — the layered surface-work system, the one rule (no private coordination in a public repo), the code-quality/security-ownership rule, and credential-badges-first scope.
- `andamio-dev/README.md` and `andamio-dev/AGENTS.md` — current identity (course + ops Agent Skills package), skills conventions, and the two-mode learning/operational model the front door must coexist with.
- credential-badges (public: `github.com/Andamio-Platform/credential-badges`) — already has README/CONTRIBUTING/ROADMAP/CODE_OF_CONDUCT/CODEOWNERS and its own workflows, confirming leaf repos own their own contribution flow; the front door routes to it rather than replacing it.
- Private context (not to be surfaced publicly): `the private coordination workspace` (the private coordination references and triage operation) and `the private coordination workspace's routing-redesign decision doc`.
