# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- `auth-setup` (0.2.0) revised against the first-run friction log (#32): API keys come from `app.andamio.io/api-setup` and need a mainnet Access Token, said up front; key prefixes `ant_pp_`/`ant_mn_`; the free tier's one-key limit (pick preprod, delete in the portal to switch); the Access Token, the two wallets and the submit endpoint explained before any on-chain step; secrets never printed (the pre-check no longer `cat`s the config file); CI no longer relies on an `ANDAMIO_API_KEY` variable the CLI doesn't read; checks only reported when run.

### Changed
- `auth-setup` runs everything after the API key on a `.skey`: `wallet create` (or an existing key), faucet, a submit endpoint (Blockfrost preprod, full `/tx/submit` path), headless `user login`, the Access Token minted with `tx run`, then a second login that carries the alias. No browser wallet signing after the developer portal, so it works the same in containers and CI.

### Added
- `auth-setup` picks up a returning developer (expired JWT, no alias yet, existing content, network mismatch) and checks the app template's `.env` against the CLI's network and key.

### Changed
- CLI reference resynced against andamio-cli 1.1.2: `teacher assignments` reads prompts answers (`content.evidence_answers`), writes real CSV and Markdown, and gains `--module-code` and `--wide`. Prompts publishing and export/import are not supported yet (andamio-cli#171).

## [0.2.0] — 2026-09-24

### Added
- `/contribute` skill — a public front door to Andamio's public repos (#8).
- Codex and other Agent Skills hosts: portable skills in `skills/`, discovery through `.agents/skills/`, and a Windows/WSL/Codex setup guide (#2). Skills resolve bundled files relative to each `SKILL.md`, so they work outside a clone (#24).
- CI runs the endpoint-index and CLI-retirement drift checks on every PR (#22).
- Gotchas for a submit URL missing `/tx/submit` and for `create-module`'s `--course-id` flag.

### Changed
- Public API contract synced to the current public artifact: 77 paths; `modules_manage` bodies use `prereq_credential_hashes` (#5, #13, #23).
- CLI reference resynced against andamio-cli 1.1.1, including the CLI 1.0 retirement of the learner and contributor command groups (#4, #10, #20, #21). Lessons no longer teach the retired commands (#26).
- Costs describe the service fees preprod charges, each tied to a measured transaction: 100 ADA to create a course or project, 10 ADA per teacher or manager added, and a commission of max(1 ADA, 5% × reward) at project credential claim (#25).
- Transaction loops 1, 2, 3, 4 and 12 re-validated end to end on preprod; commitment statuses, deposits and fees now match the chain (#15, #25, #27).
- `CLAUDE.md` describes marketplace and clone distribution; the package is not published to npm.

### Fixed
- `examples/course-lifecycle.sh` and `examples/project-lifecycle.sh` run end to end against CLI 1.1.1 and the live API (#27).
- `project-ops` request bodies for add-funds, managers and blacklist; the access-token mint `initiator_data` shape in lessons (#6, #27).
- Reference docs acknowledge that one wallet can hold several access tokens (#19).

### Removed
- The off-chain commitment `create` step from every loop, lesson and example — the API no longer has it, and enrollment creates the commitment (#13, #15, #27).
- A branch README committed by mistake, an empty `.codex` file, and an unreferenced copy of the progress schema under `.claude/skills/learn/`.

## [0.1.0] — 2026-04-14

### Added
- Initial plugin scaffold with 10 skills
- Bundled Gateway API spec (v2), Andamioscan spec (v0.3.0), CLI agent reference
- Cost registry with real transaction cost data
- Seed knowledge base (gotchas, FAQ)
- Skills: orientation, start, explore-api, cli-guide, auth-setup, cost-estimator, course-ops, project-ops, troubleshoot, compound
- "Build on Andamio" course harness (`/learn` skill + instructor/assessor agents); lessons drafted for modules 100–400
