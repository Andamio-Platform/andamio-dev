# Andamio CLI — Agent Context

> Complete reference for developers and agents interacting with the Andamio Protocol via the CLI.

**Who the CLI is for (1.0+)**: the people who author work and assess it — course Owners and Teachers, and project Managers. Learners and contributors use the [Andamio app](https://app.andamio.io), which signs and submits their work in one flow. The learner and contributor command groups were removed in 1.0 (see [Removed in 1.0](#removed-in-10)).

**Last synced**: 2026-09-21, against CLI v1.1.1 (`andamio --help` for every command, plus the CHANGELOG from 0.12.1 to 1.1.1).
**Requires Andamio API 2.5 or later** (CLI 1.0+). Preprod and mainnet both run 2.5. Against a gateway pinned to the 2.4 line, stay on CLI 0.13.x.
**Canonical CLI version**: run `andamio --version` (`--output json` emits `{version, commit, built}`). CLI release notes: `github.com/Andamio-Platform/andamio-cli/releases`. This doc is hand-curated; if commands here drift from what `andamio --help` shows, the CLI wins — file an issue.

## Quick Start

```bash
# Install (macOS/Linux)
brew install andamio-platform/tap/andamio

# Authenticate
andamio auth login --api-key <key>       # Read-only API access
andamio user login                       # Browser wallet signing (required for write operations)

# Check status
andamio user status
andamio config show
```

## Environments

| Environment | API Base URL | App URL |
|-------------|-------------|---------|
| Preprod (default) | `https://preprod.api.andamio.io` | `https://preprod.app.andamio.io` |
| Mainnet | `https://mainnet.api.andamio.io` (also `https://api.andamio.io`) | `https://app.andamio.io` (also `https://mainnet.app.andamio.io`) |

Switch environment: `andamio config set-url https://mainnet.api.andamio.io`

The CLI derives the app host from the API base URL for browser login and image upload. Both mainnet host shapes work as of 0.13.3. Non-`andamio.io` URLs need `ANDAMIO_ALLOW_ANY_URL=1`.

**Always start on preprod.** Mainnet uses real ADA. Test ADA for preprod is free from the Cardano faucet.

## Authentication

Four auth methods coexist:

| Method | Command | Header Sent | Access Level |
|--------|---------|-------------|-------------|
| API Key | `andamio auth login --api-key <key>` | `X-API-Key` | Read-only |
| Wallet JWT | `andamio user login` | `Authorization: Bearer <jwt>` | Read + Write |
| Headless JWT | `andamio user login --skey <path> --alias <name> --address <addr>` | `Authorization: Bearer <jwt>` | Read + Write (no browser) |
| Developer JWT (browser) | `andamio dev login` | `Authorization: Bearer <devJWT>` | Manage developer-portal API keys. Requires an API key first |
| Developer JWT (headless) | `andamio dev login --skey <path> --alias <name> --address <addr>` | `Authorization: Bearer <devJWT>` | Same, for CI/CD. All three flags or none |

- Config stored at `~/.andamio/config.json` (permissions 0600, atomic write — concurrent `Save` calls are safe as of 0.12.0)
- Env overrides: `ANDAMIO_JWT` (user JWT), `ANDAMIO_DEV_JWT` (dev JWT), `ANDAMIO_DEV_REFRESH_TOKEN` (dev refresh token). Env-sourced credentials are **not** persisted to disk on subsequent `Save` (0.12.0+) — rotation still works because rotated values differ from the env snapshot
- Non-secret env overrides `ANDAMIO_SUBMIT_URL` and `ANDAMIO_SUBMIT_HEADERS` are ordinary configuration and are persisted
- Both headers (`X-API-Key` + a JWT) are sent simultaneously when both are stored
- **Expired sessions (1.0+)**: the CLI decodes the stored JWT's `exp` locally and drops a known-expired token from requests. Either-auth reads (`course list`, `course get`, `course modules`, …) then succeed on the API key alone (exit 0) with a one-line stderr warning, and return the plain user-endpoint shape (no draft modules, no lesson-presence fields). JWT-required commands fail fast client-side with exit 3, the expiry time and the recovery command. `user login` works over an expired session; no `logout` first
- **Session-liveness probe**: `andamio user status --output json`, branch on `session_expired`. Also carries `session_expires_at` and `session_remaining_seconds`. `user_authenticated` is presence-based and blind to expiry. Do not use a read command as a probe
- User/wallet JWT lifetime is ~24 hours. Developer JWT lifetime is nominally 60 minutes with a 30-day single-use refresh token, issued at `dev login` and rotated on `dev refresh`. `dev login` and `dev status` print the actual lifetimes the gateway returned, so trust those over the nominal values
- Headless login signs a CIP-8 nonce with the .skey file — for CI/CD, scripting, and agents
- Wallet and developer JWTs live in separate config slots (`user_jwt` vs `dev_jwt`). The gateway's developer-JWT middleware rejects wallet/user JWTs and vice versa — they are not interchangeable

**Direct API usage from apps:** When building a web app that calls the Andamio API directly (without the CLI), proxy requests through a server-side gateway route that injects `X-API-Key` server-side — never ship the API key to the browser. The wallet JWT is obtained on the client via Mesh SDK signing and sent in the `Authorization: Bearer` header; the gateway adds `X-API-Key`. See the Midnight PBL site and `cardano-xp` for reference implementations.

## Output Formats

All data commands support `--output` (`-o`) flag:

```bash
andamio course list                    # text (default) — human-readable table
andamio course list --output json      # JSON — stable scripting surface
andamio course list --output csv       # CSV
andamio course list --output markdown  # Markdown table
```

**For agents: always use `--output json`**. This is the stable, machine-parseable interface.

## Exit Codes

Every failure carries an exit code and, under `--output json`, a `kind` field in the error envelope. Both come from the same classification, so they never disagree. Source of truth: `andamio help exit-codes`.

| Code | Kind | When |
|------|------|------|
| 0 | — | Success, including an empty but valid result set |
| 1 | `error` | Unexpected, or bad input |
| 1 | `server` | 5xx response |
| 1 | `backpressure` | 408 / 425 / 429 — retry later |
| 1 | `canceled` | Interrupted, or a `--timeout` expired |
| 1 | `verify` | The write was accepted but the read-back did not confirm it (1.1.0+, `course import-assignment`). The module **was** modified — inspect, don't retry blindly |
| 2 | `not_found` | Resource doesn't exist (404) |
| 3 | `auth` | No credentials, or 401 / 403 |
| 4 | `removed_command` | Command was retired in 1.0 |
| 5 | `unreachable` | The request never reached the service |
| 6 | `conflict` | Conflicts with existing state (409). **Breaking in 1.0**: was exit 1 |
| 7 | `tier_limit` | The plan does not permit the action (e.g. API-key cap on `dev keys create`). Remedy is revoke, upgrade or subscribe — not retry, not re-auth |

- Codes 0–3 are fixed. New kinds may be added; existing ones are not renamed.
- An empty result is exit 0 with an empty collection, which keeps "nothing found" apart from "not permitted" (3) and "could not reach the service" (5).
- An unrecognized command (or a typo like `course lst`) writes to stderr, leaves stdout clean and exits non-zero (1.0+). A group with no arguments (`andamio course`) still prints help and exits 0.
- A degraded gateway read (HTTP 206) is exit 0. `get`-style commands keep `meta.warning` in the JSON envelope; list commands keep their JSON shape and print the warning on stderr.

## Composability Contract

- **stdout** = structured data only (JSON, CSV, tables)
- **stderr** = progress messages, status updates
- **No interactive prompts** — all commands work without a TTY
- **Required args are enforced** — omitting them returns an error with a hint
- A few warnings print on stderr in **every** output mode, JSON included: expired-session fallback, `spec paths` serving a local `openapi.json`, and non-YouTube `video_url` on import. stdout stays parseable; pipe `2>/dev/null` to silence them

### Two-Step Discovery Pattern

```bash
# 1. Discover IDs
COURSE_ID=$(andamio course list --output json | jq -r '.data[0].course_id')

# 2. Use them
andamio course modules "$COURSE_ID" --output json
```

## Complete Command Reference

### auth — API key management

| Command | Description |
|---------|-------------|
| `auth login --api-key <key>` | Store API key |
| `auth status` | Check API key status |

### config — CLI configuration

| Command | Description |
|---------|-------------|
| `config show` | Show current config |
| `config set-url <url>` | Switch environment |
| `config set-submit-url <url>` | Set Cardano submit API URL |
| `config set-submit-header <key> <value>` | Persist a submit API header (e.g., Blockfrost project_id) |
| `config remove-submit-header <key>` | Remove a persisted submit header |

### user — Wallet auth and user info

| Command | Auth | Description |
|---------|------|-------------|
| `user login` | wallet | Authenticate via browser wallet signing |
| `user login --skey <path> --alias <name> --address <addr>` | api-key | Headless CIP-8 login for CI/CD and agents. `--output json` includes `expires_at` |
| `user logout` | none | Clear stored JWT |
| `user status` | none | Show auth status (API key + JWT + session remaining). JSON: `user_authenticated`, `session_expires_at`, `session_expired`, `session_remaining_seconds` — populated for browser, headless and `ANDAMIO_JWT` sessions |
| `user me` | either | Current user dashboard. Text mode no longer shows the Learning section (1.0); `--output json` passes the gateway payload through verbatim |
| `user exists <alias>` | none | Check if alias is taken |

### dev — Developer portal authentication

Parallel to `user` login but for the developer portal. Wallet and developer JWTs live in separate config slots and are not interchangeable on the gateway.

| Command | Auth | Description |
|---------|------|-------------|
| `dev login` | api-key | Browser-wallet flow (0.13.1+). Opens the app's dev-portal sign-in page and receives the JWT pair on an ephemeral localhost callback. Waits up to 5 minutes. JSON envelope omits `dev_id`, `tier`, `key_hash` — read them from `dev status --output json` |
| `dev login --skey <path> --alias <name> --address <addr>` | api-key | Headless CIP-8 nonce-signing flow — mints a developer JWT and a 30-day single-use refresh token. All three flags are required together; a partial set is an error naming the missing flags. 401 on `/complete` hints at wallet-address/`.skey` mismatch |
| `dev refresh` | none | Rotate the developer JWT using the stored refresh token (single-use server-side; CLI updates both stored tokens in lockstep). 401 clears the entire dev slot |
| `dev logout` | none | Clear the dev slot (JWT, refresh token, alias, ID, tier, key hash). Independent of `user logout`. Fires when **either** `dev_jwt` **or** `dev_refresh_token` is persisted |
| `dev status` | none | Show dev JWT and refresh-token expiry, tier, alias/ID. Both clocks surface separately in JSON (`jwt_expires_at`, `refresh_token_expires_at`, plus `*_expired` and `*_remaining_seconds`). Branch on `dev_authenticated` first |

### dev keys — Developer API key management

All commands require **both** an API key (`auth login --api-key <key>`) **and** a developer JWT (`dev login`). The gateway middleware on `/api/v2/keys` is dual: `V2AuthMiddleware` validates `X-API-Key` for app-level auth and billing, then `developerJWTAuth` validates the developer JWT for identity. Sending dev JWT alone returns 401. The wallet/user JWT slot is not used here.

| Command | Auth | Description |
|---------|------|-------------|
| `dev keys list` | dev-jwt | List your API keys across mainnet + preprod. Mainnet entries lack `last4` (legacy storage). Envelope: `{keys: [{id, name, environment, last4, created_at}]}` |
| `dev keys create` | dev-jwt | Create an API key. **Raw key is surfaced once on stdout** — gateway makes it unrecoverable. Text mode routes WARNING + metadata to stderr so `andamio dev keys create … \| pbcopy` captures the key alone. JSON envelope: `{id, name, environment, key, last4, created_at}` |
| `dev keys delete <id>` | dev-jwt | Revoke a key. Client-side validates UUID format before hitting the wire. 404 means "not found OR not owned by you" — gateway threat model collapses both. Envelope: `{id, deleted: true}` |

`dev keys create` flags: `--name` (3–64 chars) and `--environment` (`mainnet` or `preprod`), both required.

Stable error codes preserved verbatim in error messages: `tier_limit_exceeded` (exit 7, `kind: tier_limit`, classified by the code and not the HTTP status), `invalid_environment` (422), `preprod_routing_disabled` / `preprod_unavailable` (503). An expired developer JWT fails fast with a `dev refresh` hint.

### course — Course content (read)

| Command | Auth | Description |
|---------|------|-------------|
| `course list` | either | List courses |
| `course get <id>` | either | Course details |
| `course modules <id>` | either | List modules (shows SLT/lesson counts with JWT). Alt: `--course "Name"` |
| `course slts <id> <module>` | either | List SLTs (shows lesson presence with JWT). Alt: `--course "Name"` |
| `course lesson <id> <module> <slt-index>` | either | Lesson content. slt-index is a positive integer |
| `course assignment <id> <module>` | either | Module assignment |
| `course intro <id> <module>` | either | Module introduction |

### course — Course content (write)

| Command | Auth | Description |
|---------|------|-------------|
| `course create-module [path] --course-id <id>` | jwt | Create a new module. With path, reads title/code from outline.md. Flags: `--code`, `--title`, `--sort-order`, `--slt` (repeatable), `--approve` (auto-computes slt_hash; with `--output json` echoes `slt_hash` and `module_status: "APPROVED"`) |
| `course export [course-id] <module-code>` | jwt | Export module to local files. Writes `video_url` frontmatter for each lesson that has a video (v1.1.1+). A quiz assignment is written verbatim to `assignment.quiz.json` with no `assignment.md` (v1.1.0+). Flags: `--output-dir`, `--force` (overwrite; also removes a stale assignment file). Alt: `--course "Name"` instead of course-id |
| `course import <path> --course-id <id>` | jwt | Import local files to update module. Computes SLT hash automatically. Reads optional `video_url` frontmatter from each `lesson-N.md` (v1.1.1+, see [Lesson video frontmatter](#lesson-video-frontmatter)). Sends `assignment.quiz.json` verbatim after validating it (v1.1.0+, see [Quiz assignments](#quiz-assignments)). `--create` to create if missing, `--sort-order`. `--dry-run` prints a summary; add `--show-payload` for the full API payload. Alt: `--course "Name"` |
| `course import-all <dir> --course-id <id>` | jwt | Import all modules. Computes SLT hashes. `--create`, `--dry-run`, `--show-payload`, `--continue-on-error`, `--sort-order-start`. Alt: `--course "Name"` |
| `course import-assignment <course-id> <module-code> <file.json>` | jwt | Publish a quiz envelope as the module's assignment, verbatim, and verify it by read-back (v1.1.0+). Sends only the assignment. Works in any module status. Flags: `--title` (required when the module has no assignment yet), `--description`, `--dry-run`, `--show-payload`. Alt: `--course "Name"`. See [Quiz assignments](#quiz-assignments) |

### course owner — Course administration (owner role)

| Command | Auth | Description |
|---------|------|-------------|
| `course owner list` | jwt | List courses you own |
| `course owner create --course-id <id> --pending-tx-hash <hash>` | jwt | Create off-chain record (fallback — normally `tx run` auto-registers) |
| `course owner register --course-id <id> --title <t>` | jwt | Register on-chain course with off-chain metadata. Optional: `--tx-hash`, `--description`, `--image-url`, `--video-url`, `--category`, `--public` |
| `course owner update --course-id <id>` | jwt | Update course metadata. Only changed flags sent. Flags: `--title`, `--description`, `--image-url`, `--video-url`, `--public`, `--live` |
| `course owner teachers --course-id <id> --alias <owner-alias> --skey <path>` | jwt | Add/remove teachers with `--add` / `--remove` (both repeatable). **Breaking in 1.0**: this is an on-chain transaction (`teachers_update`) and runs build → sign → submit → register → poll, so `--alias`, `--skey` and a configured submit URL are required. Pass-throughs match `tx run`: `--no-wait`, `--timeout`, `--submit-url`, `--submit-header`, `--metadata`. `--output json` emits the `tx run` result envelope |

### course teacher — Module and assessment management (teacher role)

| Command | Auth | Description |
|---------|------|-------------|
| `course teacher commitments --course-id <id>` | jwt | List pending assignment reviews |
| `course teacher review --course-id <id> --module-code <code> --participant-alias <alias> --decision <accept/refuse>` | jwt | Accept or refuse a student submission |
| `course teacher register-module --course-id <id> --module-code <code> --slt-hash <hash>` | jwt | Register module from on-chain data. Idempotent on `slt_hash` match (DRAFT advances to APPROVED; APPROVED/PENDING_TX/ON_CHAIN no-ops; mismatch errors and points at `delete-module`). **Breaking in 0.12.0 (`--output json` consumers):** response is now wrapped — `{action, status, slt_hash, advanced_from, response}`. Branch on `.action` (`registered` / `advanced` / `already_registered`); gateway fields nest under `.response` |
| `course teacher publish-module --course-id <id> --module-code <code>` | jwt | Publish a module. Warns only when the response shows the module is not linked (`module_status` / `slt_hash`) |
| `course teacher delete-module --course-id <id> --module-code <code>` | jwt | Delete a module |
| `course teacher update-module-status --course-id <id> --module-code <code> --status <status>` | jwt | Update module status. `--slt-hash` required for APPROVED. Valid statuses: DRAFT, APPROVED, PENDING_TX |

### course credential — Verification and hash computation

| Command | Auth | Description |
|---------|------|-------------|
| `course credential verify-hash <course-id>` | either | Verify credential hashes match computed SLT hashes (Blake2b-256) |
| `course credential compute-hash` | none | Compute SLT hash from `--slt` flags (repeatable) or `--file` (outline.md). Local-only, no auth required |

### teacher — Top-level teacher operations

| Command | Auth | Description |
|---------|------|-------------|
| `teacher courses` | jwt | List courses where you are a teacher |
| `teacher assignments list` | jwt | Lightweight summary of pending commitments across all courses. No nested `content`, so the text-mode Status column shows `—` |
| `teacher assignments list --course <id>` | jwt | Full merged history for one course. Status comes from `content.commitment_status`, shown verbatim: `AWAITING_SUBMISSION`, `SUBMITTED`, `ACCEPTED`, `REFUSED`, `CREDENTIAL_CLAIMED`, `LEFT`, transient `PENDING_TX_*` |
| `teacher assignments get <course> <module> <student>` | jwt | Get a specific student's commitment. Exit 2 (`not_found`) when the course has no commitments or no matching student |
| `teacher assessment build --course-id <id> --alias <teacher-alias>` | jwt | Build an assessment transaction and stop — nothing is signed or submitted (1.0+). Decisions: `--decision <student-alias>=<accept\|refuse>` (repeatable) or `--decisions-file <path>` (`[{"alias":"…","outcome":"accept"}]`). Duplicate aliases are rejected. JSON: `{unsigned_tx, course_id, teacher_alias, decisions[], decision_count}` |

`content.evidence_text` (1.0+) on `teacher assignments list --course` / `get` is the submission rendered as Markdown. Read it for the prose; read `content.evidence` (the raw Tiptap document) to verify a commitment hash.

`teacher assessment build` exists to keep a person in the loop: the decision set and the unsigned transaction come from one command, so a reviewer sees both before signing. The echoed decisions are the request the CLI sent, not a decode of the returned transaction.

### project — Project data (read)

| Command | Auth | Description |
|---------|------|-------------|
| `project list` | either | List projects |
| `project get <id>` | either | Project details |
| `project tasks <project-id>` | either | List tasks (public view) |

### project owner — Project administration (owner role)

| Command | Auth | Description |
|---------|------|-------------|
| `project owner list` | jwt | List projects you own |
| `project owner create --project-id <id> --pending-tx-hash <hash>` | jwt | Create off-chain record. Flags: `--title`, `--description`, `--image-url`, `--video-url`, `--category`, `--public` |
| `project owner register --project-id <id> --title <t>` | jwt | Register on-chain project with off-chain metadata |
| `project owner update --project-id <id>` | jwt | Update project metadata. Only changed flags sent. Flags: `--title`, `--description`, `--image-url`, `--video-url`, `--public` |

### project task — Task management (manager role)

| Command | Auth | Description |
|---------|------|-------------|
| `project task list <project-id>` | jwt | List tasks |
| `project task get <index> --project-id <id>` | jwt | Get task by index |
| `project task create <project-id>` | jwt | Create task. Flags: `--title`, `--lovelace`, `--expiration`, `--content`, `--content-file`, `--github-issue`, `--token` (repeatable: `"policy_id,asset_name,quantity"`) |
| `project task update <index> --project-id <id>` | jwt | Update task fields. Flags: `--title`, `--lovelace`, `--expiration`, `--content`, `--content-file`, `--token` |
| `project task delete <index> --project-id <id>` | jwt | Delete draft task |
| `project task export <project-id>` | jwt | Export tasks to Markdown files |
| `project task import <project-id>` | jwt | Import tasks from Markdown. `--dry-run` supported |
| `project task verify-hash <project-id>` | either | Verify task hashes match computed hashes (diagnostic) |
| `project task compute-hash` | none | Compute task hash from `--content`, `--lovelace`, `--expiration`, `--token` flags or `--file`. Local-only, no auth required |

### project manager — Manager operations

| Command | Auth | Description |
|---------|------|-------------|
| `project manager commitments --project-id <id>` | jwt | List **all** task commitments (pending + already-assessed with evidence, evidence hash, assessor, decision). Pre-v2.3 returned only pending. Filter with `jq` on `content.commitment_status`, `source`, or `task_outcome`. Text-mode columns (0.12.0): `submitted_by` + `task_hash` |
| `project manager qualified-contributors --project-id <id>` | jwt | List aliases qualified to commit to the project (one per line in text mode). Server-capped at 500 — text mode emits a stderr warning when `truncated=true`. `--output json` passes the gateway payload through in snake_case: `{project_id, aliases, total_count, truncated, status}`. `status` explains an empty list (`ok` vs `no_prerequisites_configured`) |

### manager — Top-level manager operations

| Command | Auth | Description |
|---------|------|-------------|
| `manager projects` | jwt | List projects where you are a manager |

### token — Native asset registry

| Command | Auth | Description |
|---------|------|-------------|
| `token list` | either | List registered native asset tokens available as task rewards |

### tx — Cardano transactions

| Command | Auth | Description |
|---------|------|-------------|
| `tx run <endpoint> --skey <path> --tx-type <type>` | jwt | Full lifecycle: build, sign, submit, register, poll. Flags below |
| `tx build <endpoint> --body <json>` | jwt | Build unsigned transaction. `--body-file` for file input. Returns the full API response including `unsigned_tx`. `initiator_data` is a WalletData object (`{change_address, used_addresses}`), not an address string |
| `tx sign --tx <hex> --skey <path>` | none | Sign with local .skey file. `--tx-file` for file input. JSON: `{signed_tx, tx_hash}` |
| `tx submit --tx <hex>` | none | Submit signed tx. `--submit-url`, `--submit-header` overrides |
| `tx register --tx-hash <hash> --tx-type <type>` | jwt | Register tx for tracking. `--instance-id` optional |
| `tx pending` | either | List pending transactions. Exit 0 with an empty list when nothing is pending |
| `tx types` | either | List transaction types |
| `tx status <hash>` | either | Get transaction status |

#### tx run flags

| Flag | Description |
|------|-------------|
| `--body <json>` | Inline JSON request body |
| `--body-file <path>` | Path to JSON file (mutually exclusive with --body) |
| `--skey <path>` | Path to Cardano .skey file for signing |
| `--tx-type <type>` | Transaction type for registration (see `andamio tx types`) |
| `--instance-id <id>` | Course or project ID for registration |
| `--metadata key=value` | Metadata for registration (repeatable) |
| `--submit-url <url>` | Override submit API URL |
| `--submit-header "Key: Value"` | Additional submit headers (repeatable) |
| `--no-wait` | Exit after registration without polling |
| `--timeout <duration>` | Max time to wait for confirmation (default 10m) |

### apikey — API key info

| Command | Auth | Description |
|---------|------|-------------|
| `apikey usage` | api-key + dev-jwt | Key usage stats |
| `apikey profile` | api-key + dev-jwt | Key profile |

Dual-credential since 0.13.0, the same as `dev keys`: both `auth login --api-key <key>` and `dev login` are required. The wallet/user JWT is not accepted here.

### spec — API discovery

| Command | Description |
|---------|-------------|
| `spec fetch` | Download OpenAPI spec to openapi.json (from `/openapi/swagger.json`) |
| `spec paths [--filter <pattern>]` | List available API endpoints. When a local `openapi.json` exists it is used instead of fetching, and the file's date and age are printed on stderr in every output mode. Delete it or re-run `spec fetch` to avoid reading a stale spec |

### help topics

| Command | Description |
|---------|-------------|
| `help exit-codes` | The exit-code and error-kind contract, from the binary |

### Removed in 1.0

The learner group (`student`, under `course`) and the contributor group (`contributor`, under `project`) were removed, with every subcommand. Learners and contributors use the [Andamio app](https://app.andamio.io). Running a removed command, in any invocation shape, says where the operation lives now and exits 4 with `kind: removed_command`. This is a CLI change only: the gateway routes are unaffected, and the learner-side transaction endpoints are still reachable through `tx run` / `tx build`.

## Agent Workflow Examples

### Explore a course

```bash
COURSE=$(andamio course list --output json | jq -r '.data[0].course_id')
andamio course modules "$COURSE" --output json
andamio course slts "$COURSE" 100 --output json
andamio course lesson "$COURSE" 100 2 --output json | jq '.content_json'
```

### Assess student assignments (teacher)

```bash
# Read every submitted assignment as Markdown
andamio teacher assignments list --course "$COURSE" --output json \
  | jq -r '.data[] | select(.content.commitment_status=="SUBMITTED")
           | "\(.student_alias): \(.content.evidence_text)"'

# Get a specific submission
andamio teacher assignments get "$COURSE" "$MODULE" "$STUDENT" --output json

# Build the assessment transaction and STOP. One transaction carries every
# decision — include the refuses as well as the accepts.
andamio teacher assessment build --course-id "$COURSE" --alias teacher-01 \
  --decision student-01=accept --decision student-02=refuse \
  --output json > assessment.json

# A person reviews .decisions[] in assessment.json, then signs and submits
SIGNED=$(andamio tx sign --tx "$(jq -r .unsigned_tx assessment.json)" \
  --skey ./payment.skey --output json)
andamio tx submit --tx "$(jq -r .signed_tx <<<"$SIGNED")"
andamio tx register --tx-hash "$(jq -r .tx_hash <<<"$SIGNED")" \
  --tx-type assessment_assess --instance-id "$COURSE"
```

An assessment decision should not be automated end to end: an agent can recommend one, but a person approves it. `teacher assessment build` is the supported path for that. `tx run` on `/v2/tx/course/teacher/assignments/assess` still does build, sign, submit and confirm in one step; its body uses `assignment_decisions: [{"alias": "...", "outcome": "accept"}]`.

### Manage project tasks

```bash
PROJECT=$(andamio project list --output json | jq -r '.data[0].project_id')

# List tasks
andamio project task list "$PROJECT" --output json

# Create a task
andamio project task create "$PROJECT" \
  --title "Build API endpoint" \
  --lovelace 5000000 \
  --expiration 2026-06-01

# Create with rich content and token reward
andamio project task create "$PROJECT" \
  --title "Design system" \
  --lovelace 5000000 \
  --expiration 2026-06-01 \
  --content-file task-description.md \
  --token "policyid...,XP,50"

# Export/import tasks as Markdown
andamio project task export "$PROJECT"
andamio project task import "$PROJECT" --dry-run
```

### Content round-trip (export, edit, import)

```bash
# Export a module to local files
andamio course export "$COURSE" 100
# Creates: compiled/<slug>/100/outline.md, lesson-N.md, introduction.md,
#          assignment.md (or assignment.quiz.json for a quiz)

# Edit locally
vim compiled/<slug>/100/lesson-1.md

# Preview, then re-import
andamio course import ./compiled/<slug>/100 --course-id "$COURSE" --dry-run
andamio course import ./compiled/<slug>/100 --course-id "$COURSE"

# Bulk import all modules, creating any that are missing
andamio course import-all ./compiled/<slug> --course-id "$COURSE" --create
```

### Transaction lifecycle (step-by-step)

For advanced use when you need control over individual steps:

```bash
# 1. Build unsigned transaction
UNSIGNED=$(andamio tx build /v2/tx/course/teacher/assignments/assess \
  --body-file assess-payload.json --output json | jq -r '.unsigned_tx')

# 2. Sign with local key (returns signed_tx and tx_hash)
SIGN=$(andamio tx sign --tx "$UNSIGNED" --skey payment.skey --output json)
SIGNED=$(jq -r '.signed_tx' <<<"$SIGN")
TX_HASH=$(jq -r '.tx_hash' <<<"$SIGN")

# 3. Submit to network
andamio tx submit --tx "$SIGNED"

# 4. Register for tracking (type names: andamio tx types)
andamio tx register --tx-hash "$TX_HASH" --tx-type assessment_assess --instance-id "$COURSE"

# 5. Check status
andamio tx status "$TX_HASH" --output json
```

### Transaction lifecycle (tx run — preferred)

`tx run` wraps all five steps into one command:

```bash
andamio tx run /v2/tx/course/teacher/assignments/assess \
  --body-file assess-payload.json \
  --skey payment.skey \
  --tx-type assessment_assess \
  --instance-id "$COURSE"
```

Progress goes to stderr. Use `--output json` for the final result: `{tx_hash, tx_type, state, step, build_response, error}`. Use `--no-wait` to skip confirmation polling.

**Terminal states:** `updated` (chain confirmed + DB synced), `failed` (chain confirmed but DB update failed), `expired` (never confirmed on-chain within 2h). When DB update fails, `tx run` prints recovery commands to stderr. See `andamio-cli/docs/TX-LIFECYCLE.md` for the full state machine and recovery procedures.

**Auto-metadata (v0.11.0+):** `tx run` automatically injects `task_hash` into registration metadata for project TX types (`project_join`, `task_submit`, `task_assess`, `project_credential_claim`). For `project_join`, it extracts from the request body. For `project_credential_claim`, it looks up the contributor's ACCEPTED commitment. Explicit `--metadata task_hash=<hash>` always takes precedence.

### Headless authentication (CI/CD, agents)

```bash
andamio user login --skey ./payment.skey --alias myalias --address $(cat wallet.addr)

# Session-liveness probe: branch on session_expired, not on a read command
andamio user status --output json | jq '{session_expired, session_remaining_seconds}'
```

### Discover API endpoints

```bash
andamio spec paths --filter teacher
andamio spec paths --filter assignment
andamio spec fetch  # download full OpenAPI spec
```

## Lifecycle Ordering

Some operations have on-chain prerequisites. Attempting them out of order returns errors.

### Course setup (owner + teacher)

1. **Create course on-chain** → `tx run /v2/tx/instance/owner/course/create`
2. **Draft module with SLTs** → `course create-module --slt "..." --slt "..." --approve`
3. **Set PENDING_TX** → `course teacher update-module-status --status PENDING_TX`
4. **Mint module on-chain** → `tx run /v2/tx/course/teacher/modules/manage`
5. **Import content** → `course import <path> --course-id <id>` (must include assignment)

To appoint teachers after step 1: `course owner teachers --course-id <id> --alias <owner> --skey <path> --add <alias>` (on-chain).

### Course credential (student + teacher)

Learner steps happen in the Andamio app. The CLI has no learner commands as of 1.0; the transaction endpoints remain reachable through `tx run` for testing.

1. **Learner enrolls and submits evidence on-chain** → app, or `tx run /v2/tx/course/student/assignment/commit` (requires assignment content to exist)
2. **Teacher reviews and assesses on-chain** → `teacher assignments list --course <id>`, then `teacher assessment build` + `tx sign` + `tx submit`, or `tx run /v2/tx/course/teacher/assignments/assess`
3. **Learner claims credential on-chain** → app, or `tx run /v2/tx/course/student/credential/claim`

Task commits to a project require the contributor to hold a credential (step 3). Without it, Atlas returns 422.

### Project setup (owner + manager)

1. **Create project on-chain** → `tx run /v2/tx/instance/owner/project/create`
2. **Create draft task** → `project task create <id> --title "..." --lovelace 5000000 --expiration 2026-12-31`
3. **Fund treasury** → `tx run /v2/tx/project/user/treasury/add-funds` (required before contributors can join)
4. **Mint tasks on-chain** → `tx run /v2/tx/project/manager/tasks/manage`

### Project credential (contributor + manager)

Contributor steps happen in the Andamio app. The CLI has no contributor commands as of 1.0; the transaction endpoints remain reachable through `tx run` for testing.

1. **Contributor joins project** → app, or `tx run /v2/tx/project/contributor/task/commit` (auto-injects task_hash metadata)
2. **Manager reviews and accepts** → `project manager commitments --project-id <id>`, then `tx run /v2/tx/project/manager/tasks/assess`
3. **Contributor claims credential + reward** → app, or `tx run /v2/tx/project/contributor/credential/claim` (auto-looks up task_hash)

## API Response Shapes

### List responses

All list endpoints return:
```json
{
  "data": [
    { "field": "value" },
    { "field": "value" }
  ]
}
```

Empty lists return `{"data": []}`.

### Error responses (--output json)

```json
{"error": "API error 404: ...", "kind": "not_found"}
```

`kind` (1.0+) is a stable machine-readable name: `error`, `server`, `backpressure`, `canceled`, `verify`, `not_found`, `auth`, `removed_command`, `unreachable`, `conflict`, `tier_limit`. It maps to the exit code per the [Exit Codes](#exit-codes) table. Text mode prints the message on stderr and carries no `kind`.

### Degraded reads (206)

When one backend is unavailable the gateway returns the normal `data` plus `meta.warning`. The CLI treats this as success (exit 0). `get`-style commands keep `meta.warning` in the JSON envelope; list commands keep their bare shape and print `warning: …` on stderr.

### Common nested fields

- Course data: `data[].course_id`, `data[].content.title`
- Module data: `data[].content.course_module_code`, `data[].content.title`, `data[].content.module_status`
- SLT data: `data[].slt_index`, `data[].slt_text`, `data[].lesson` (object if lesson exists)
- Task data: `data[].task_index`, `data[].content.title`, `data[].task_status`, `data[].lovelace_amount`
- Assignment commitments: `data[].student_alias`, `data[].course_module_code`, `data[].content.commitment_status`, `data[].content.evidence` (Tiptap, hash-bearing), `data[].content.evidence_text` (Markdown, added by the CLI)
- Task commitments: `data[].task_hash`, `data[].submitted_by`, `data[].source`, `data[].content.commitment_status`, `data[].content.task_outcome` (`null` until assessed)

## Content Formats

### Tiptap JSON (content_json)

Rich content (lessons, assignments, task descriptions) uses Tiptap JSON format:

```json
{
  "type": "doc",
  "content": [
    {
      "type": "heading",
      "attrs": {"level": 1},
      "content": [{"type": "text", "text": "Title"}]
    },
    {
      "type": "paragraph",
      "content": [{"type": "text", "text": "Body text"}]
    }
  ]
}
```

The CLI converts between Markdown and Tiptap JSON for import/export. When using `--content-file`, Markdown is automatically converted.

### Export/import file format

```
compiled/<course-slug>/<module-code>/
  outline.md          # No H1 — YAML frontmatter holds title and code only. Start with ## SLTs
  introduction.md     # H1 becomes intro title
  lesson-1.md         # H1 becomes lesson title. Optional video_url frontmatter
  lesson-N.md         # One file per SLT
  assignment.md       # H1 becomes assignment title (Tiptap doc assignment)
  assignment.quiz.json  # Quiz assignment instead of assignment.md — never both
  assets/             # Images only: PNG, JPG, GIF, WebP, 5MB each (auto-uploaded on import)
  .image-manifest.json  # Local filename → CDN URL mapping
```

### Lesson video frontmatter

Requires CLI v1.1.1 or later. A `lesson-N.md` may open with a YAML frontmatter block. `video_url` is the only supported key:

```markdown
---
video_url: "https://www.youtube.com/watch?v=<id>"
---

# Lesson title
```

| Frontmatter | On import |
|---|---|
| `video_url: "<url>"` | Sets the lesson's video, replacing the stored one |
| `video_url: ""` | Clears the lesson's video |
| no `video_url` key, or no frontmatter | Leaves the stored video unchanged |

- The value must be an absolute `http` or `https` URL. Any other key, or an invalid URL, fails the import before any request and names the file.
- The Andamio app embeds YouTube links only (`youtube.com`, `youtu.be`, `youtube-nocookie.com`). Import warns on stderr for any other URL, in every output mode including `--output json`, and still sends it.
- `course export` writes the block for every lesson that has a video, so export followed by import leaves the module unchanged.
- A lesson that opens with a `---` thematic break is still read as Markdown. A leading `---` … `---` block counts as frontmatter only when it parses as YAML keys.
- This is a URL, not an upload. The CLI does not upload video files; `assets/` accepts images only.
- Module and assignment `video_url` have no CLI input. Import preserves whatever is stored.

### Quiz assignments

Requires CLI v1.1.0 or later. A quiz assignment is a JSON envelope the Andamio app grades client-side, stored verbatim as the assignment's `content_json`:

```json
{"type": "quiz", "version": 1, "passThreshold": 2, "questions": [ ... ]}
```

| Path | Use |
|------|-----|
| `course import-assignment <course-id> <module-code> quiz.json` | Publish a quiz without a module directory. Sends only the assignment, in any module status |
| `assignment.quiz.json` in a module directory | `course import` sends it verbatim and preserves the existing assignment title |
| `course export` | Writes a quiz to `assignment.quiz.json` and produces no `assignment.md` |

- Validated before any request, with every violated rule listed and no bypass flag: `type` and `version`, a non-empty `questions` array, unique question ids, non-blank prompts, at least two options per question with unique non-empty values and non-blank labels, a `correctValue` matching one option, `passThreshold` in `1..len(questions)`, and an `intro` that is a Tiptap doc if present.
- A directory holding both `assignment.md` and `assignment.quiz.json` is refused. So is `course import --create` with a quiz file for a module that does not exist yet: a quiz file carries no title, so create the module first, then run `import-assignment --title`.
- `import-assignment` keeps the existing title, description, image and video URLs unless `--title` / `--description` override them. A module with no assignment yet requires `--title`.
- After the write, `import-assignment` re-fetches the module and deep-compares the stored value. A mismatch, a degraded read-back or a failed read-back exits 1 with `kind: verify` — the update **was** applied.
- JSON: `import-assignment` emits `{course_id, module_code, module_status, assignment: {title, title_source, question_count, pass_threshold, question_ids}, verified}`; `course import` gains an `assignment_quiz` summary object.

## Key Identifiers

| Identifier | Format | Example / Notes |
|-----------|--------|---------|
| course_id | 56-char hex | `013f0ac76f0e1ac4c878070ccc44e84bf296d84b047e4de4932137e4` (LocalStateNFT policy ID, minted at course creation) |
| project_id | 56-char hex | `cb72d1a86ae046df8c200b2cefdadf1322bfcfe72d1787b4662d1587` (LocalStateNFT policy ID, minted at project creation) |
| contributor_state_id | 56-char hex | ContributorState minting policy ID (one per project, minted at project creation). Required in every project TX body. |
| alias | string, 1-31 chars | User-chosen on-chain identity, e.g. `test-admin-001`, `contrib22`. Canonical field name in all TX request bodies. Response payloads may disambiguate via `student_alias` / `contributor_alias`. |
| course_module_code | numeric string | `100`, `200`, `300` — off-chain only; NEVER appears in TX bodies. |
| slt_index | integer | `1`, `2`, `3` — position of an SLT within a module. |
| task_index | integer | `0`, `1`, `2` — position of a task within a project. |
| slt_hash | 64-char hex | Blake2b-256 of PlutusTx-serialized SLT byte string list (NOT Plutus Data encoding). Module token name on-chain. |
| task_hash | 64-char hex | Blake2b-256 of Plutus Data `Constr 0 [content, expiration, lovelace, native_assets]` (CBOR tag 121). Different encoding from `slt_hash`. |
| tx_hash | 64-char hex | `cfd58c772c21a6a281b207d6999595b81771e911cb8450a34cf323af61a61b4e` (Cardano transaction hash) |
| evidence_hash | string | Evidence hash. **Request inputs** use `evidence_hash`. **Response outputs** disambiguate with `assignment_evidence_hash` (courses) or `task_evidence_hash` (projects). |

### Global Access Token Policy IDs

Andamio issues a global access-token NFT policy, one per Cardano network. These policy IDs are **protocol constants** — stable, shared across all Andamio courses and apps, and will not change. Every learner holds an access token under the policy ID matching the network their course is published on. Use these when detecting access tokens in a wallet (via CIP-30 UTxO scanning) or building wallet auth flows.

| Network | Policy ID |
|---------|-----------|
| Preprod | `aa1cbea2524d369768283d7c8300755880fd071194a347cf0a4e274f` |
| Mainnet | `ff5d0640b5a2717646d3f3151d100d57d194fdfa88cacf03f9edc568` |
