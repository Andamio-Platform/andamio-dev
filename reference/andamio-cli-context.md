# Andamio CLI — Agent Context

> Complete reference for developers and agents interacting with the Andamio Protocol via the CLI.
> CLI version: 0.11.0 | Last updated: 2026-04-06

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
| Mainnet | `https://mainnet.api.andamio.io` | `https://mainnet.app.andamio.io` |

Switch environment: `andamio config set-url https://mainnet.api.andamio.io`

**Always start on preprod.** Mainnet uses real ADA. Test ADA for preprod is free from the Cardano faucet.

## Authentication

Two auth methods coexist:

| Method | Command | Header Sent | Access Level |
|--------|---------|-------------|-------------|
| API Key | `andamio auth login --api-key <key>` | `X-API-Key` | Read-only |
| Wallet JWT | `andamio user login` | `Authorization: Bearer <jwt>` | Read + Write |
| Headless JWT | `andamio user login --skey <path> --alias <name> --address <addr>` | `Authorization: Bearer <jwt>` | Read + Write (no browser) |

- Config stored at `~/.andamio/config.json` (permissions 0600)
- Environment variable `ANDAMIO_JWT` overrides stored JWT (useful for CI/CD)
- Both headers are sent simultaneously when both credentials exist
- JWT lifetime is ~24 hours
- Headless login signs a CIP-8 nonce with the .skey file — for CI/CD, scripting, and agents

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

| Code | Meaning | When |
|------|---------|------|
| 0 | Success | Command completed normally |
| 1 | Generic error | Network, server, unexpected errors |
| 2 | Not found | Resource doesn't exist (404) |
| 3 | Auth required | No credentials or invalid credentials (401/403) |

## Composability Contract

- **stdout** = structured data only (JSON, CSV, tables)
- **stderr** = progress messages, status updates
- **No interactive prompts** — all commands work without a TTY
- **Required args are enforced** — omitting them returns an error with a hint

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
| `user login --skey <path> --alias <name> --address <addr>` | api-key | Headless CIP-8 login for CI/CD and agents |
| `user logout` | none | Clear stored JWT |
| `user status` | none | Show auth status (API key + JWT + session remaining) |
| `user me` | either | Current user dashboard |
| `user exists <alias>` | none | Check if alias is taken |

### course — Course content (read)

| Command | Auth | Description |
|---------|------|-------------|
| `course list` | either | List courses |
| `course get <id>` | either | Course details |
| `course modules <id>` | either | List modules (shows SLT/lesson counts with JWT) |
| `course slts <id> <module>` | either | List SLTs (shows lesson presence with JWT) |
| `course lesson <id> <module> <slt-index>` | either | Lesson content. slt-index is a positive integer |
| `course assignment <id> <module>` | either | Module assignment |
| `course intro <id> <module>` | either | Module introduction |

### course — Course content (write)

| Command | Auth | Description |
|---------|------|-------------|
| `course create-module [path] --course-id <id>` | jwt | Create a new module. With path, reads title/code from outline.md. Flags: `--code`, `--title`, `--sort-order`, `--slt` (repeatable), `--approve` (auto-computes slt_hash) |
| `course export [course-id] <module-code>` | jwt | Export module to local files. Alt: `--course "Name"` instead of course-id |
| `course import <path> --course-id <id>` | jwt | Import local files to update module. Computes SLT hash automatically. `--create` to create if missing. `--dry-run` supported. Alt: `--course "Name"` |
| `course import-all <dir> --course-id <id>` | jwt | Import all modules. Computes SLT hashes. `--create`, `--dry-run`, `--continue-on-error`, `--sort-order-start`. Alt: `--course "Name"` |

### course owner — Course administration (owner role)

| Command | Auth | Description |
|---------|------|-------------|
| `course owner list` | jwt | List courses you own |
| `course owner create --course-id <id> --pending-tx-hash <hash>` | jwt | Create off-chain record (fallback — normally `tx run` auto-registers) |
| `course owner register --course-id <id> --title <t>` | jwt | Register on-chain course with off-chain metadata |
| `course owner update --course-id <id>` | jwt | Update course metadata. Only changed flags sent. Flags: `--title`, `--description`, `--image-url`, `--video-url`, `--public`, `--live` |
| `course owner teachers --course-id <id>` | jwt | Add/remove teachers. `--add` and `--remove` (both repeatable) |

### course teacher — Module and assessment management (teacher role)

| Command | Auth | Description |
|---------|------|-------------|
| `course teacher commitments --course-id <id>` | jwt | List pending assignment reviews |
| `course teacher review --course-id <id> --module-code <code> --participant-alias <alias> --decision <accept/refuse>` | jwt | Accept or refuse a student submission |
| `course teacher register-module --course-id <id> --module-code <code> --slt-hash <hash>` | jwt | Register module from on-chain data |
| `course teacher publish-module --course-id <id> --module-code <code>` | jwt | Publish a module |
| `course teacher delete-module --course-id <id> --module-code <code>` | jwt | Delete a module |
| `course teacher update-module-status --course-id <id> --module-code <code> --status <status>` | jwt | Update module status. `--slt-hash` required for APPROVED. Valid statuses: DRAFT, APPROVED, PENDING_TX |

### course student — Enrollment and evidence (student role)

| Command | Auth | Description |
|---------|------|-------------|
| `course student courses` | jwt | List enrolled courses |
| `course student credentials` | jwt | List earned credentials |
| `course student commitments` | jwt | List assignment commitments |
| `course student commitment --course-id <id> --slt-hash <hash>` | jwt | Get a specific commitment. `--module-code` optional |
| `course student create --course-id <id> --module-code <code>` | jwt | Enroll in a module |
| `course student submit --course-id <id> --module-code <code>` | jwt | Submit evidence. `--evidence` or `--evidence-file` (Markdown). `--slt-hash` for chain-only modules |
| `course student update --course-id <id> --module-code <code>` | jwt | Update evidence. `--evidence` or `--evidence-file` (Markdown) |
| `course student claim --course-id <id> --module-code <code> --pending-tx-hash <hash>` | jwt | Claim credential |
| `course student leave --course-id <id> --module-code <code> --pending-tx-hash <hash>` | jwt | Leave a commitment |

### course credential — Verification and hash computation

| Command | Auth | Description |
|---------|------|-------------|
| `course credential verify-hash <course-id>` | either | Verify credential hashes match computed SLT hashes (Blake2b-256) |
| `course credential compute-hash` | none | Compute SLT hash from `--slt` flags (repeatable) or `--file` (outline.md). Local-only, no auth required |

### teacher — Top-level teacher operations

| Command | Auth | Description |
|---------|------|-------------|
| `teacher courses` | jwt | List courses where you are a teacher |
| `teacher assignments list` | jwt | List pending assignment commitments |
| `teacher assignments list --course <id>` | jwt | List commitments for a specific course (includes full submission) |
| `teacher assignments get <course> <module> <student>` | jwt | Get a specific student's commitment |

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
| `project owner update --project-id <id>` | jwt | Update project metadata. Only changed flags sent |

### project task — Task management (manager role)

| Command | Auth | Description |
|---------|------|-------------|
| `project task list <project-id>` | jwt | List tasks |
| `project task get <index> --project-id <id>` | jwt | Get task by index |
| `project task create <project-id>` | jwt | Create task. Flags: `--title`, `--lovelace`, `--expiration`, `--content`, `--content-file`, `--github-issue`, `--token` (repeatable: `"policy_id,asset_name,quantity"`) |
| `project task update <index> --project-id <id>` | jwt | Update task fields |
| `project task delete <index> --project-id <id>` | jwt | Delete draft task |
| `project task export <project-id>` | jwt | Export tasks to Markdown files |
| `project task import <project-id>` | jwt | Import tasks from Markdown. `--dry-run` supported |
| `project task verify-hash <project-id>` | either | Verify task hashes match computed hashes (diagnostic) |
| `project task compute-hash` | none | Compute task hash from `--content`, `--lovelace`, `--expiration`, `--token` flags or `--file`. Local-only, no auth required |

### project contributor — Task participation (contributor role)

| Command | Auth | Description |
|---------|------|-------------|
| `project contributor list` | jwt | List projects you contribute to |
| `project contributor commitments` | jwt | List task commitments |
| `project contributor commitment --project-id <id> --task-index <n>` | jwt | Get a specific commitment. `--task-hash` for chain-only tasks |
| `project contributor commit --project-id <id> --task-index <n>` | jwt | Commit to a task. `--task-hash` for chain-only tasks |
| `project contributor update --project-id <id> --task-index <n>` | jwt | Update evidence. `--evidence` or `--evidence-file`. `--task-hash` for chain-only tasks |
| `project contributor delete --project-id <id> --task-index <n>` | jwt | Withdraw commitment. `--task-hash` for chain-only tasks |

### project manager — Manager operations

| Command | Auth | Description |
|---------|------|-------------|
| `project manager commitments --project-id <id>` | jwt | List pending task assessments |

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
| `tx build <endpoint> --body <json>` | jwt | Build unsigned transaction. `--body-file` for file input |
| `tx sign --tx <hex> --skey <path>` | none | Sign with local .skey file. `--tx-file` for file input |
| `tx submit --tx <hex>` | none | Submit signed tx. `--submit-url`, `--submit-header` overrides |
| `tx register --tx-hash <hash> --tx-type <type>` | jwt | Register tx for tracking. `--instance-id` optional |
| `tx pending` | either | List pending transactions |
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
| `apikey usage` | api-key | Key usage stats |
| `apikey profile` | api-key | Key profile |

### spec — API discovery

| Command | Description |
|---------|-------------|
| `spec fetch` | Download OpenAPI spec to openapi.json |
| `spec paths [--filter <pattern>]` | List available API endpoints |

## Agent Workflow Examples

### Explore a course

```bash
COURSE=$(andamio course list --output json | jq -r '.data[0].course_id')
andamio course modules "$COURSE" --output json
andamio course slts "$COURSE" 100 --output json
andamio course lesson "$COURSE" 100 2 --output json | jq '.content_json'
```

### Full course lifecycle (student)

```bash
# 1. Enroll
andamio course student create --course-id "$COURSE" --module-code 100

# 2. Submit evidence
andamio course student submit --course-id "$COURSE" --module-code 100 \
  --evidence-file my-evidence.md

# 3. (Teacher accepts — see teacher workflow)

# 4. Claim credential (after on-chain tx)
andamio course student claim --course-id "$COURSE" --module-code 100 \
  --pending-tx-hash "$TX_HASH"
```

### Assess student assignments (teacher)

```bash
# List pending submissions
andamio teacher assignments list --course "$COURSE" --output json

# Get a specific submission
andamio teacher assignments get "$COURSE" "$MODULE" "$STUDENT" --output json

# Review (accept or refuse)
andamio course teacher review --course-id "$COURSE" --module-code "$MODULE" \
  --participant-alias "$STUDENT" --decision accept

# Build and run the on-chain assess transaction
andamio tx run /v2/tx/course/teacher/assignments/assess \
  --body '{"alias":"teacher-01","course_id":"...","assignment_decisions":[...]}' \
  --skey ./payment.skey \
  --tx-type assessment_assess
```

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

### Full project lifecycle (contributor)

```bash
# 1. Commit to a task
andamio project contributor commit --project-id "$PROJECT" --task-index 3

# 2. Submit evidence
andamio project contributor update --project-id "$PROJECT" --task-index 3 \
  --evidence-file my-work.md

# 3. (Manager assesses — on-chain tx)

# 4. Claim reward (after on-chain tx)
# Rewards are distributed by the on-chain validator after assessment
```

### Content round-trip (export, edit, import)

```bash
# Export a module to local files
andamio course export "$COURSE" 100
# Creates: compiled/<slug>/100/outline.md, lesson-N.md, introduction.md, assignment.md

# Edit locally
vim compiled/<slug>/100/lesson-1.md

# Re-import
andamio course import ./compiled/<slug>/100 --course-id "$COURSE"

# Bulk import all modules, creating any that are missing
andamio course import-all ./compiled/<slug> --course-id "$COURSE" --create
```

### Transaction lifecycle (step-by-step)

For advanced use when you need control over individual steps:

```bash
# 1. Build unsigned transaction
TX_HEX=$(andamio tx build /v2/tx/course/teacher/assignments/assess \
  --body-file assess-payload.json --output json | jq -r '.tx_hex')

# 2. Sign with local key
SIGNED=$(andamio tx sign --tx "$TX_HEX" --skey payment.skey --output json | jq -r '.tx_hex')

# 3. Submit to network
andamio tx submit --tx "$SIGNED"

# 4. Register for tracking
andamio tx register --tx-hash "$TX_HASH" --tx-type assess_assignments

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

Progress goes to stderr. Use `--output json` for the final result. Use `--no-wait` to skip confirmation polling.

**Terminal states:** `updated` (chain confirmed + DB synced), `failed` (chain confirmed but DB update failed), `expired` (never confirmed on-chain within 2h). When DB update fails, `tx run` prints recovery commands to stderr. See `andamio-cli/docs/TX-LIFECYCLE.md` for the full state machine and recovery procedures.

**Auto-metadata (v0.11.0+):** `tx run` automatically injects `task_hash` into registration metadata for project TX types (`project_join`, `task_submit`, `task_assess`, `project_credential_claim`). For `project_join`, it extracts from the request body. For `project_credential_claim`, it looks up the contributor's ACCEPTED commitment. Explicit `--metadata task_hash=<hash>` always takes precedence.

### Headless authentication (CI/CD, agents)

```bash
andamio user login --skey ./payment.skey --alias myalias --address $(cat wallet.addr)
andamio user status  # verify JWT is stored
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

### Course credential (student + teacher)

1. **Create off-chain commitment** → `course student create` (requires assignment content to exist)
2. **Enroll + submit evidence on-chain** → `tx run /v2/tx/course/student/assignment/commit`
3. **Teacher accepts on-chain** → `tx run /v2/tx/course/teacher/assignments/assess`
4. **Claim credential on-chain** → `tx run /v2/tx/course/student/credential/claim`

Task commits to a project require the contributor to hold a credential (step 4). Without it, Atlas returns 422.

### Project setup (owner + manager)

1. **Create project on-chain** → `tx run /v2/tx/instance/owner/project/create`
2. **Create draft task** → `project task create <id> --title "..." --lovelace 5000000 --expiration 2026-12-31`
3. **Fund treasury** → `tx run /v2/tx/project/user/treasury/add-funds` (required before contributors can join)
4. **Mint tasks on-chain** → `tx run /v2/tx/project/manager/tasks/manage`

### Project credential (contributor + manager)

1. **Join project** → `tx run /v2/tx/project/contributor/task/commit` (auto-injects task_hash metadata)
2. **Manager accepts** → `tx run /v2/tx/project/manager/tasks/assess`
3. **Claim credential + reward** → `tx run /v2/tx/project/contributor/credential/claim` (auto-looks up task_hash)

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
{"error": "error message here"}
```

Combined with exit codes: `0` = success, `1` = generic, `2` = not found, `3` = auth.

### Common nested fields

- Course data: `data[].course_id`, `data[].content.title`
- Module data: `data[].content.course_module_code`, `data[].content.title`, `data[].content.module_status`
- SLT data: `data[].slt_index`, `data[].slt_text`, `data[].lesson` (object if lesson exists)
- Task data: `data[].task_index`, `data[].content.title`, `data[].task_status`, `data[].lovelace_amount`
- Assignment commitments: `data[].student_alias`, `data[].course_module_code`, `data[].content.evidence`

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

The CLI converts between Markdown and Tiptap JSON for import/export. When using `--content-file` or `--evidence-file`, Markdown is automatically converted.

### Export/import file format

```
compiled/<course-slug>/<module-code>/
  outline.md          # No H1 — title from YAML frontmatter. Start with ## SLTs
  introduction.md     # H1 becomes intro title
  lesson-1.md         # H1 becomes lesson title
  lesson-N.md         # One file per SLT
  assignment.md       # H1 becomes assignment title
  assets/             # Images (auto-uploaded on import)
  .image-manifest.json  # Local filename → CDN URL mapping
```

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
