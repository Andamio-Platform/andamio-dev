---
name: explore-api
description: Search Gateway and Andamioscan API endpoints by natural language. Find endpoints, params, auth requirements, and example responses.
license: MIT
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Explore API

## Description

Natural-language search across the Andamio Gateway API and Andamioscan specs. Developers ask questions like "How do I list courses?" and get matching endpoints with params, auth requirements, and example responses.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read specs from `${CLAUDE_PLUGIN_ROOT}/specs/`.
- **Clone/symlink context** (default): Read specs at `specs/` relative to project root.

### Pre-Execution Knowledge Check

1. Read `specs/andamio-api.yaml` — the Andamio Gateway API spec (Swagger 2.0, 111 endpoints).
2. Read `specs/andamioscan.yaml` — the Andamioscan on-chain observer spec (Swagger 2.0, 34 endpoints).
3. If knowledge files exist, read `knowledge/endpoint-usage.yaml` for previously discovered patterns. Proceed without it if the file is empty or missing.

### Endpoint Filtering

**Exclude from results** (internal/admin endpoints that external developers cannot use):
- `/v1/admin/*` — Admin-only endpoints
- `/v2/billing/webhook` — Internal webhook receiver
- Endpoints tagged with `x-rate-limit-tier: admin`

**Include everything else.** When an endpoint requires specific auth, note it clearly.

### Answering Developer Questions

When the developer asks a question:

1. **Search both specs** for matching endpoints by path, operation summary, tags, and parameter names.

2. **Present matches** with clear source labels:

```
Gateway API: GET /v2/course/user/courses/list
  Auth: API Key (read-only OK)
  Params: none
  Returns: { data: [{ course_id, content: { title, description }, ... }] }

Andamioscan: GET /api/v2/courses
  Auth: None (public)
  Params: none
  Returns: On-chain course data indexed from Cardano
```

3. **Include for each endpoint:**
   - HTTP method and full path
   - Source (Gateway API or Andamioscan)
   - Auth requirement (None, API Key, API Key + JWT)
   - Required and optional parameters
   - Response shape (summarize from spec definitions)
   - Rate limit tier if applicable

4. **When endpoints overlap** between Gateway and Andamioscan (e.g., course listings), explain the difference:
   - **Gateway API**: Application data, includes off-chain metadata, supports write operations
   - **Andamioscan**: On-chain verified data, read-only, useful for auditing and analytics

### Content Format Notes

When endpoints return or accept rich content fields (lessons, assignments, task descriptions), note:

> Content fields use **Tiptap JSON format**. The CLI converts between Markdown and Tiptap JSON automatically during import/export. For direct API usage, you'll need to construct Tiptap JSON documents. See the `content_json` field structure in the spec.

### Example Interactions

**Developer asks: "How do I enroll a student in a course?"**

```
This is a multi-step process:

1. Student creates a commitment (draft):
   Gateway API: POST /v2/course/student/commitment/create
   Auth: API Key + JWT
   Body: { course_id, course_module_code }

2. Student submits the commitment:
   Gateway API: POST /v2/course/student/commitment/submit
   Auth: API Key + JWT
   Body: { course_id, course_module_code, evidence: <Tiptap JSON> }

3. Build the enrollment transaction:
   Gateway API: POST /v2/tx/course/student/assignment/commit
   Auth: API Key + JWT
   Body: { alias, course_id, slt_hash, assignment_info }

Note: Enrollment involves a Cardano transaction (~2.14 ADA).
Use /cost-estimator for a full cost breakdown.
```

**Developer asks: "How do I check if a user completed a course?"**

```
Two options:

Gateway API: GET /v2/course/student/credentials/list
  Auth: API Key + JWT (as the student)
  Returns: List of earned credential NFTs

Andamioscan: GET /api/v2/users/{alias}/courses/completed
  Auth: None (public)
  Returns: Courses where the user has claimed credentials on-chain

Use Andamioscan for public verification without user authentication.
```

### Offer Next Steps

After answering, offer related skills:

- If the developer needs auth → "Want me to walk you through authentication? Try /auth-setup"
- If the developer is exploring costs → "Want to estimate ADA costs for this? Try /cost-estimator"
- If the developer wants CLI commands → "Want the CLI equivalent? Try /cli-guide"
- If the developer wants to do the operation → "Ready to do this? Try /course-ops or /project-ops"

### Guidelines

- Always label the source (Gateway API vs Andamioscan) for every endpoint
- Show auth requirements prominently — developers waste time on 401s without this
- Include response shapes, not just endpoint paths
- When multiple endpoints could answer a question, show all of them with trade-offs
- Note Tiptap JSON format whenever content fields are involved
- If a question has no matching endpoint, say so clearly and suggest alternatives
