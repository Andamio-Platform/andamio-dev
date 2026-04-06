---
name: cli-guide
description: Get exact CLI commands for any Andamio operation. Translates developer questions to commands with flags, exit codes, and composability patterns.
license: MIT
compatibility: Requires the Andamio CLI binary (v0.10.1+). Install via brew install andamio-platform/tap/andamio.
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: CLI Guide

## Description

Interactive CLI guidance from the bundled agent reference. Developers ask what they want to do and get exact `andamio` commands with flags, expected output, exit codes, and composability patterns.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read reference from `${CLAUDE_PLUGIN_ROOT}/reference/`.
- **Clone/symlink context** (default): Read reference at `reference/` relative to project root.

### Pre-Execution Knowledge Check

1. Read `reference/andamio-cli-context.md` — complete CLI command reference (v0.10.1).
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
| `course` (write) | create-module, export, import, import-all | jwt |
| `course owner` | list, create, register, update, teachers | jwt |
| `course teacher` | commitments, review, register-module, publish-module, delete-module, update-module-status | jwt |
| `course student` | courses, credentials, commitments, commitment, create, submit, update, claim, leave | jwt |
| `course credential` | verify-hash | either |
| `teacher` | courses, assignments list/get | jwt |
| `project` (read) | list, get, tasks | either |
| `project owner` | list, create, register, update | jwt |
| `project task` | list, get, create, update, delete, export, import, verify-hash | jwt |
| `project contributor` | list, commitments, commitment, commit, update, delete | jwt |
| `project manager` | commitments | jwt |
| `manager` | projects | jwt |
| `token` | list | either |
| `tx` | run, build, sign, submit, register, pending, types, status | varies |
| `apikey` | usage, profile | api-key |
| `spec` | fetch, paths | none |

### Composability Patterns

When the developer is building scripts or pipelines, show composability:

```bash
# Two-step discovery: find ID, then use it
COURSE_ID=$(andamio course list --output json | jq -r '.data[0].course_id')
andamio course modules "$COURSE_ID" --output json

# Pipe to jq for field extraction
andamio course slts "$COURSE_ID" 100 --output json | jq '.data[].slt_text'

# Check exit codes in scripts
if ! andamio user status >/dev/null 2>&1; then
  echo "Auth required" >&2
  andamio user login
fi
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
- `lesson-N.md`: **Must have `# H1`** — this becomes the lesson title.
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
TX_HEX=$(andamio tx build /v2/tx/course/teacher/assignments/assess \
  --body-file payload.json --output json | jq -r '.tx_hex')

# 2. Sign with local key
SIGNED=$(andamio tx sign --tx "$TX_HEX" --skey payment.skey --output json | jq -r '.tx_hex')

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
