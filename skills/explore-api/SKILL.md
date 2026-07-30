---
name: explore-api
description: Search Andamio Gateway API endpoints by natural language. Find endpoints, params, auth requirements, and example responses.
license: MIT
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: Explore API

## Description

Natural-language search across the Andamio Gateway API spec. Developers ask questions like "How do I list courses?" and get matching endpoints with params, auth requirements, and example responses.

The Gateway API is the single entry point for all Andamio operations. It proxies to backend services (DB API, Atlas TX builder, Andamioscan indexer) and merges their data into unified responses. Developers never call backend services directly.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read specs from `${CLAUDE_PLUGIN_ROOT}/specs/`.
- **Clone/symlink context** (default): Read specs at `specs/` relative to project root.

### Pre-Execution Knowledge Check

1. Read `specs/andamio-api.yaml` — the Andamio Gateway API public contract (Swagger 2.0, 77 paths). It is the public surface only; administrative and internal operations are absent by design, so their absence is not a gap.
2. If knowledge files exist, read `knowledge/endpoint-usage.yaml` for previously discovered patterns. Proceed without it if the file is empty or missing.

### Endpoint Filtering

**None needed.** The bundled spec is already the filtered public surface, so present everything in it.

### Answering Developer Questions

When the developer asks a question:

1. **Search the spec** for matching endpoints by path, operation summary, tags, and parameter names.

2. **Present matches** with clear structure:

```
Gateway API: GET /v2/course/user/courses/list
  Auth: API Key (read-only OK)
  Params: none
  Returns: { data: [{ course_id, content: { title, description }, ... }] }
```

3. **Include for each endpoint:**
   - HTTP method and full path
   - Auth requirement (None, API Key, API Key + JWT)
   - Required and optional parameters
   - Response shape (summarize from spec definitions)
   - Rate limit tier if applicable

4. **For read endpoints**, note that responses merge on-chain and off-chain data:
   - `source: "merged"` — both on-chain and off-chain data present
   - `source: "chain_only"` — on-chain only, no off-chain metadata yet
   - `source: "db_only"` — off-chain only, not yet confirmed on-chain

### Known Schema Gaps

Three TX request schemas have underspecified array fields in the spec. When a developer asks about these endpoints, provide the correct format from `reference/tx-loops.yaml`:

| Schema | Field | Spec says | Actual format |
|--------|-------|-----------|---------------|
| `CreateProjectTxRequest` | `course_prereqs` | `[][]any` | `[["<56-hex-course-id>", ["<64-hex-slt-hash>", ...]]]` |
| `AddFundsTxRequest` | `deposit_value` | `[]any` | `[["lovelace", <amount>]]` |
| `ManageTasksTxRequest` | `deposit_value` | `[]any` | `[["lovelace", <amount>]]` |

### Content Format Notes

When endpoints return or accept rich content fields (lessons, assignments, task descriptions), note:

> Content fields use **Tiptap JSON format**. The CLI converts between Markdown and Tiptap JSON automatically during import/export. For direct API usage, you'll need to construct Tiptap JSON documents. See the `content_json` field structure in the spec.

### Example Interactions

**Developer asks: "How do I enroll a student in a course?"**

```
This is a multi-step process:

1. Build the enrollment transaction:
   Gateway API: POST /v2/tx/course/student/assignment/commit
   Auth: API Key + JWT
   Body: { alias, course_id, slt_hash, assignment_info }

2. Student submits evidence off-chain:
   Gateway API: POST /v2/course/student/commitment/submit
   Auth: API Key + JWT
   Body: { course_id, slt_hash, evidence: <Tiptap JSON>, evidence_hash }

NOTE: POST /v2/course/student/commitment/create is gone. It was removed from the
API in the 2026-07-30 contract sync, so it is absent from specs/andamio-api.yaml
and calls to it fail — the tx builder above is the sole supported path. The CLI
has not caught up: `andamio course student create` still targets the removed
route, so it fails today. That command group is already slated for retirement in
CLI 1.0 (see reference/cli-retirements.yaml), so use the API path rather than
waiting on a CLI fix. The same applies to the project side —
POST /v2/project/contributor/commitment/create was removed in the same sync, and
`andamio project contributor commit` still targets it.

Note: Enrollment involves a Cardano transaction (~2.14 ADA).
Use /cost-estimator for a full cost breakdown.
```

**Developer asks: "How do I check if a user completed a course?"**

```
Gateway API: POST /v2/course/student/credentials/list
  Auth: API Key + JWT (as the student)
  Returns: List of earned credentials with course_id, slt_hashes, enrollment_status

The response merges on-chain credential NFTs with off-chain course metadata.
Entries with source: "chain_only" have credentials but no off-chain course record.
```

### Offer Next Steps

After answering, offer related skills:

- If the developer needs auth → "Want me to walk you through authentication? Try /auth-setup"
- If the developer is exploring costs → "Want to estimate ADA costs for this? Try /cost-estimator"
- If the developer wants CLI commands → "Want the CLI equivalent? Try /cli-guide"
- If the developer wants to do the operation → "Ready to do this? Try /course-ops or /project-ops"

### Guidelines

- Show auth requirements prominently — developers waste time on 401s without this
- Include response shapes, not just endpoint paths
- When multiple endpoints could answer a question, show all of them with trade-offs
- Note Tiptap JSON format whenever content fields are involved
- If a question has no matching endpoint, say so clearly and suggest alternatives
- For tx body schemas with underspecified types, always check `reference/tx-loops.yaml` for the correct format
