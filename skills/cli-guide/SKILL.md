---
name: cli-guide
description: Get exact CLI commands for any Andamio operation. Translates developer questions to commands with flags, exit codes, and composability patterns.
license: MIT
compatibility: Requires the Andamio CLI binary (v1.0.0+; v1.1.1 for quiz assignments and lesson video). Install via brew install andamio-platform/tap/andamio.
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: CLI Guide

## Description

Interactive CLI guidance from the bundled agent reference. Developers ask what they want to do and get exact `andamio` commands with flags, expected output, exit codes, and composability patterns.

## Instructions

### Path Resolution

Bundled paths in this skill (`reference/`, `knowledge/`) are relative to the **package root**: the directory two levels above this `SKILL.md`, after resolving symlinks — the one that contains `specs/andamio-api.yaml`. Resolve them from there, never from the current working directory, which is the developer's own project and does not contain these files. From this file, `reference/andamio-cli-context.md` is `../../reference/andamio-cli-context.md`.

Knowledge files are developer data. Read them from the state directory first — `${CLAUDE_PLUGIN_DATA}/knowledge/` when `${CLAUDE_PLUGIN_DATA}` is set, otherwise `knowledge/` in the current working directory — and fall back to the package's seed `knowledge/`.

### Pre-Execution Knowledge Check

1. Read `reference/andamio-cli-context.md` — complete CLI command reference (synced against CLI v1.1.1).
2. If knowledge files exist, read `knowledge/gotchas.yaml` for CLI-related gotchas (category: cli). Proceed without it if missing.

### Answering Developer Questions

When the developer asks how to do something:

1. **Find the matching command** from the CLI reference.
2. **Present the command** with:
   - Full command with all required flags
   - Auth requirement (none, api-key, jwt)
   - Expected output format
   - Exit codes that might occur
   - `--output json` variant for scripting/agent use

3. **Format consistently:**

```
Command:  andamio course list --output json
Auth:     API Key (read-only OK)
Exit:     0 = success, 2 = not found, 3 = auth required

Output:
{
  "data": [
    { "course_id": "013f0a...", "content": { "title": "My Course" } }
  ]
}
```

### Command Groups

Cover the full CLI surface:

| Group | Commands | Auth |
|-------|----------|------|
| `auth` | login, status | none / api-key |
| `config` | show, set-url, set-submit-url, set-submit-header, remove-submit-header | none |
| `user` | login (browser + headless), logout, status, me, exists | varies |
| `course` (read) | list, get, modules, slts, lesson, assignment, intro | either |
| `course` (write) | create-module, export, import, import-all, import-assignment | jwt |
| `course owner` | list, create, register, update, teachers | jwt |
| `course teacher` | commitments, review, register-module, publish-module, delete-module, update-module-status | jwt |
| `course credential` | verify-hash, compute-hash | either / none |
| `teacher` | courses, assignments list/get, assessment build | jwt |
| `project` (read) | list, get, tasks | either |
| `project owner` | list, create, register, update | jwt |
| `project task` | list, get, create, update, delete, export, import, verify-hash, compute-hash | jwt |
| `project manager` | commitments, qualified-contributors | jwt |
| `manager` | projects | jwt |
| `token` | list | either |
| `tx` | run, build, sign, submit, register, pending, types, status | varies |
| `dev` | login (browser + headless), refresh, logout, status | api-key |
| `dev keys` | list, create, delete | api-key + dev-jwt |
| `apikey` | usage, profile | api-key + dev-jwt |
| `spec` | fetch, paths | none |
| `help` | exit-codes | none |

**CLI 1.0 scope:** the CLI serves course Owners and Teachers and project Managers. The learner and contributor command groups were removed in 1.0; those users work in the Andamio app. A removed command exits 4 with `kind: removed_command`. The learner-side `/v2/tx/...` endpoints are still reachable through `tx run` and `tx build`.

### Composability Patterns

When the developer is building scripts or pipelines, show composability:

```bash
# Two-step discovery: find ID, then use it
COURSE_ID=$(andamio course list --output json | jq -r '.data[0].course_id')
andamio course modules "$COURSE_ID" --output json

# Pipe to jq for field extraction
andamio course slts "$COURSE_ID" 100 --output json | jq '.data[].slt_text'

# Probe session liveness: branch on session_expired, not on a read command
if [ "$(andamio user status --output json | jq -r '.session_expired // true')" = "true" ]; then
  echo "Auth required" >&2
  andamio user login
fi

# Branch on exit code, or on .kind in the JSON error envelope
# 2 not_found · 3 auth · 5 unreachable · 6 conflict · 7 tier_limit (andamio help exit-codes)
```

**Key rules:**
- `stdout` = structured data only (JSON, CSV, tables)
- `stderr` = progress messages, status updates
- No interactive prompts — all commands work without a TTY
- `--output json` is the stable scripting surface

### Import/Export Workflow

When the developer asks about content management, show the round-trip:

```bash
# Export a module to local files
andamio course export <course-id> <module-code>
# Alt: andamio course export <module-code> --course "Course Name"
# Creates: compiled/<slug>/<code>/outline.md, lesson-N.md, assignment.md, introduction.md

# Edit locally
vim compiled/<slug>/<code>/lesson-1.md

# Re-import (updates existing content)
andamio course import ./compiled/<slug>/<code> --course-id <id>

# Import with module creation if missing
andamio course import ./compiled/<slug>/<code> --course-id <id> --create

# Bulk import all modules
andamio course import-all ./compiled/<slug> --course-id <id> --create
```

**File format rules:**
- `outline.md`: No `# H1` — title from YAML `title:` field. Start with `## SLTs`.
- `lesson-N.md`: **Must have `# H1`** — this becomes the lesson title. May open with YAML frontmatter holding `video_url` (CLI v1.1.1+): a URL sets the lesson's video, `""` clears it, no key keeps the stored value. Any other key fails the import. The app embeds YouTube links only.
- `introduction.md`: `# H1` becomes intro title.
- `assignment.md`: `# H1` becomes assignment title.

### Transaction Lifecycle

When the developer asks about transactions, prefer `tx run`:

```bash
# Preferred: single command for the full lifecycle
andamio tx run /v2/tx/course/teacher/assignments/assess \
  --body-file payload.json \
  --skey payment.skey \
  --tx-type assessment_assess \
  --instance-id "$COURSE_ID"
```

For advanced use, show the individual steps:

```bash
# 1. Build unsigned transaction
UNSIGNED=$(andamio tx build /v2/tx/course/teacher/assignments/assess \
  --body-file payload.json --output json | jq -r '.unsigned_tx')

# 2. Sign with local key (returns signed_tx and tx_hash)
SIGN=$(andamio tx sign --tx "$UNSIGNED" --skey payment.skey --output json)
SIGNED=$(jq -r '.signed_tx' <<<"$SIGN")
TX_HASH=$(jq -r '.tx_hash' <<<"$SIGN")

# 3. Submit to network
andamio tx submit --tx "$SIGNED"

# 4. Register for tracking
andamio tx register --tx-hash "$TX_HASH" --tx-type assessment_assess

# 5. Check status
andamio tx status "$TX_HASH" --output json
```

### Lifecycle Ordering

Some operations have on-chain prerequisites. Always mention ordering when relevant:

**Course**: enroll → submit evidence → teacher accepts → assess on-chain → claim credential
**Project**: create task → manage on-chain → contributor commits → submit evidence → manager assesses

Task commits require the contributor to hold a credential. Without it: 422 "Prerequisites not achieved."

### Headless Authentication

When the developer is in CI/CD, scripting, or agent context:

```bash
andamio user login --skey ./payment.skey --alias myalias --address $(cat wallet.addr)
```

No browser needed. Signs a CIP-8 nonce with the .skey file.

### Offer Next Steps

- If the developer needs auth → "Need to set up credentials? Try /auth-setup"
- If the developer wants API details → "Want the API endpoint details? Try /explore-api"
- If the developer wants cost info → "Want to know the ADA cost? Try /cost-estimator"
- If the developer hit an error → "Got an error? Try /troubleshoot"

### Guidelines

- Always include `--output json` for agent/scripting contexts
- Show auth requirements for every command
- Include exit codes so scripts can handle errors
- When showing multi-step workflows, number the steps clearly
- Prefer `tx run` over manual build/sign/submit steps
- Show `--course "Name"` alternative when course-id is needed (for export/import commands)
- Reference gotchas from knowledge files when relevant
- Mention lifecycle ordering whenever operations have prerequisites
