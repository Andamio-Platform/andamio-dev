---
name: course-ops
description: Course lifecycle guidance — create courses, add modules, manage teachers, import content, and publish. CLI-first with API alternatives.
license: MIT
compatibility: Requires the Andamio CLI for most operations. Install via brew install andamio-platform/tap/andamio.
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Course Ops

## Description

Guides developers through the complete course lifecycle on Andamio. Defaults to CLI-based workflows (simpler), with API alternatives for each step.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read specs from `${CLAUDE_PLUGIN_ROOT}/specs/`, reference from `${CLAUDE_PLUGIN_ROOT}/reference/`.
- **Clone/symlink context** (default): Read from `specs/` and `reference/` relative to project root.

### Pre-Execution Check

1. Read `specs/andamio-api.yaml` for course endpoint details.
2. Read `reference/andamio-cli-context.md` for CLI command reference.
3. Check authentication:

```bash
andamio user status 2>/dev/null
```

If no JWT is detected, redirect: "Course operations require wallet authentication (JWT). Let me walk you through that first." Then execute `/auth-setup` inline.

### Course Lifecycle

#### 1. Create Course

A Cardano transaction. Costs ~130 ADA for 1 teacher (see /cost-estimator).

**Via API** (Gateway):
```
POST /v2/tx/instance/owner/course/create
Auth: API Key + JWT
Body: { alias, teachers: [alias1, alias2], ... }
```

The API returns an unsigned transaction. The developer must sign and submit it (see Transaction Flow below).

**Planning tip:** Set all initial teachers at creation — adding teachers later costs ~10.3 ADA each.

#### 2. Add Modules

Each module is a Cardano transaction. Costs ~1.86 ADA each (no service fee).

**Via CLI:**
```bash
# Create module shell
andamio course create-module <course-id> \
  --code 101 \
  --title "Introduction to Andamio" \
  --sort-order 1
```

**Module statuses:**
- **DRAFT** — Can create/update/delete SLTs and lessons
- **APPROVED** — SLTs are locked, can only update lesson content
- **ON_CHAIN** — Fully locked, content hashes committed on-chain

#### 3. Import Content

The CLI handles Markdown-to-Tiptap conversion automatically.

**Export existing module (to edit):**
```bash
andamio course export <course-id> 101
# Creates: compiled/<slug>/101/outline.md, lesson-N.md, assignment.md, introduction.md
```

**Edit locally, then re-import:**
```bash
andamio course import <course-id> 101
```

**Bulk import all modules:**
```bash
andamio course import-all <course-id>
```

**File format rules:**
- `outline.md`: Title from YAML frontmatter, SLTs listed as numbered items
- `lesson-N.md`: Must start with `# H1` title, content below
- `introduction.md`: `# H1` becomes intro title
- `assignment.md`: `# H1` becomes assignment title

**SLT hash workflow:** As of v0.10.2, `course import` automatically computes the SLT hash (Blake2b-256) and includes it in the API payload. This means the recommended workflow is:

1. Import content with `--create` flag (creates DRAFT module with SLTs and computed hash)
2. Mint modules on-chain via `tx run` (gateway matches DB record by hash)
3. Register module if needed: `andamio course teacher register-module --course-id <id> --module-code <code> --slt-hash <hash>`
4. Publish module: `andamio course teacher publish-module --course-id <id> --module-code <code>`

You can pre-compute the hash without importing:
```bash
andamio course credential compute-hash --slt "Learner can explain..." --slt "Learner can demonstrate..."
andamio course credential compute-hash --file ./compiled/my-course/101/outline.md
```

See `andamio-cli/docs/COURSE-LIFECYCLE.md` for the complete step-by-step workflow.

**Status gotcha:** `register-module` sets status to APPROVED, which locks SLTs. If you need to re-import SLTs after registering, first run: `andamio course teacher update-module-status --course-id <id> --module-code <code> --status DRAFT`

#### 4. Manage Teachers

**Via API:**
```
POST /v2/tx/course/owner/teachers/manage
Auth: API Key + JWT
Body: { alias, course_id, teachers_to_add: [alias], teachers_to_remove: [alias] }
```

Costs ~10.3 ADA per update transaction. The governance token tracks the teacher roster on-chain.

#### 5. Student Enrollment Flow

Students interact through the app or API:

1. **Create commitment** (draft): `POST /v2/course/student/commitment/create`
2. **Submit commitment**: `POST /v2/course/student/commitment/submit`
3. **Build enrollment tx**: `POST /v2/tx/course/student/assignment/commit` (~2.14 ADA)
4. **Update evidence**: `POST /v2/course/student/commitment/update` (~0.33 ADA per update)
5. **Teacher assesses**: `POST /v2/tx/course/teacher/assignments/assess` (~0.21 ADA)
6. **Claim credential**: `POST /v2/tx/course/student/credential/claim` (nets +1.03 ADA)

#### 6. Publish Module

Status transitions: DRAFT → APPROVED → PENDING_TX → ON_CHAIN (→ DEPRECATED / ARCHIVED)

- **DRAFT → APPROVED**: Teacher action. Locks SLTs but allows lesson content updates.
- **APPROVED → PENDING_TX**: Teacher submits the `modules_manage` TX; the DB marks the module pending, awaiting on-chain confirmation.
- **PENDING_TX → ON_CHAIN**: Gateway batch-confirms once andamioscan sees the minted module token. Fully immutable after this point. **Important:** the batch confirm endpoint requires the module to be in `PENDING_TX` before it will set `ON_CHAIN` — the off-chain flow must advance to `PENDING_TX` first.
- **ON_CHAIN → DEPRECATED / ARCHIVED**: Optional terminal states for removing a module from active use without deleting it.

```bash
# Check module status
andamio course modules <course-id> --output json | jq '.data[] | {code: .content.course_module_code, status: .content.module_status}'
```

### Transaction Flow

Course operations that modify on-chain state require Cardano transactions:

```bash
# 1. Build (returns unsigned tx hex)
TX_HEX=$(andamio tx build /v2/tx/instance/owner/course/create \
  --body '{"alias":"my-alias","teachers":["teacher1"]}' \
  --output json | jq -r '.tx_hex')

# 2. Sign
SIGNED=$(andamio tx sign --tx "$TX_HEX" --skey payment.skey \
  --output json | jq -r '.tx_hex')

# 3. Submit
andamio tx submit --tx "$SIGNED"

# 4. Register for tracking
andamio tx register --tx-hash "$TX_HASH" --tx-type course_create

# 5. Monitor status
andamio tx status "$TX_HASH" --output json
```

### Offer Next Steps

- "Want to estimate costs before proceeding?" → `/cost-estimator`
- "Need to set up authentication?" → `/auth-setup`
- "Want to manage a project instead?" → `/project-ops`
- "Hit an error?" → `/troubleshoot`

### Guidelines

- Default to CLI workflows — they're simpler and handle Tiptap conversion
- Show API alternatives for developers building custom integrations
- Always mention costs before operations that involve Cardano transactions
- Warn about SLT locking before module status changes
- Check auth before any write operation
