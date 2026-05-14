# Andamio API Endpoints by Use Case

> "I want to ___" → endpoint(s). Quick navigator into the OpenAPI spec at `specs/andamio-api.yaml`.

For full request/response schemas, query the spec directly with the `/explore-api` skill or open it in your editor. This doc indexes use cases to v2 endpoint groups, not every endpoint.

**Last updated**: 2026-05-14

---

## Auth & API keys

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Register a developer account | `POST /v2/auth/developer/account/register` | Public |
| Log in as a developer | `POST /v2/auth/developer/account/login` | Public |
| Refresh a JWT | `POST /v2/auth/developer/token/refresh` | JWT |
| Verify my email | `POST /v2/auth/developer/verify-email` | JWT |
| Request a new API key | `POST /v2/apikey/developer/key/request` | JWT |
| Rotate my API key | `POST /v2/apikey/developer/key/rotate` | JWT |
| Get my developer profile | `GET /v2/apikey/developer/profile/get` | JWT |
| Get my API usage | `GET /v2/apikey/developer/usage/get` | JWT or API key |
| Delete my developer account | `POST /v2/apikey/developer/account/delete` | JWT |

## User identity & access token

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Get the current user | `GET /v2/user/me` | API key + user JWT |
| Get my daily usage | `GET /v1/user/usage/daily` | API key |
| Delete a user | `POST /v1/user/delete` | API key |
| Mint a user's access token | (TX type `access_token_mint`) — `POST /v2/token/access/mint` | API key + wallet sig |

## Course creation & management

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Create a new course | `POST /v2/course/create` | API key + wallet sig |
| Add or update modules | `POST /v2/course/modules/manage` | API key + wallet sig |
| Update a module's status (DRAFT ↔ APPROVED → PENDING_TX) | `POST /v2/course/module/status` | API key + wallet sig |
| Update teachers | `POST /v2/course/teachers/manage` | API key + wallet sig |
| List my courses | `GET /v2/course/list` | API key |
| Get a course by ID | `GET /v2/course/{course_id}` | API key |

## Student enrollment & credentials

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Enroll a student in a course | `POST /v2/course/enroll` | API key + wallet sig |
| Commit to an assignment | `POST /v2/course/assignment/commit` | API key + wallet sig |
| Submit an assignment | `POST /v2/course/assignment/submit` | API key + wallet sig |
| Assess (accept/refuse) a submission | `POST /v2/course/assessment/assess` | API key + wallet sig (teacher) |
| Claim a credential NFT | `POST /v2/course/credential/claim` | API key + wallet sig |
| Leave a course | `POST /v2/course/leave` | API key + wallet sig |

## Project creation & management

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Create a project | `POST /v2/project/create` | API key + wallet sig |
| Update managers | `POST /v2/project/managers/manage` | API key + wallet sig |
| Add/update/cancel tasks | `POST /v2/project/tasks/manage` (uses `BatchUpdateTaskStatusRequest`) | API key + wallet sig |
| Fund the project treasury | `POST /v2/project/treasury/fund` | API key + wallet sig |
| List my projects | `GET /v2/project/list` | API key |

## Project contribution & rewards

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Join a project as a contributor | `POST /v2/project/join` | API key + wallet sig |
| Commit to a task | `POST /v2/project/task/commit` | API key + wallet sig |
| Submit task work | `POST /v2/project/task/submit` | API key + wallet sig |
| Assess a task submission | `POST /v2/project/task/assess` | API key + wallet sig (manager) |
| Claim a project credential | `POST /v2/project/credential/claim` | API key + wallet sig |
| Update the project blacklist | `POST /v2/project/blacklist/update` | API key + wallet sig |

## Transaction lifecycle

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Get the state of a pending TX | `GET /v2/tx/{tx_hash}` | API key |
| List my pending TXs | `GET /v2/tx/list` | API key |
| Subscribe to TX state events (SSE) | `GET /v2/tx/events/{tx_hash}` | API key |
| Submit a signed TX | `POST /v2/tx/submit` | API key + wallet sig |

State machine: `pending → confirmed → updated` (happy path); `failed` or `expired` (failure paths). See [status-enums.md](./status-enums.md#tx-lifecycle-status).

## Billing (Stripe)

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Get my subscription tier | `GET /v2/billing/subscription` | JWT |
| Start a checkout session | `POST /v2/billing/checkout` | JWT |
| Manage billing portal | `POST /v2/billing/portal` | JWT |

## Verification (third-party)

| I want to... | Endpoint(s) | Auth |
|--------------|-------------|------|
| Verify an on-chain credential | `POST /v2/verify/credential` | Public or API key |
| Verify a task commitment | `POST /v2/verify/task-commitment` | Public or API key |

## Admin / internal

These require admin role on the API key — used for ops, not for app integrations.

- `GET /v2/admin/tx/stats` — aggregate TX state machine stats.
- `POST /v1/admin/set-user-role` — promote/demote user roles.
- `GET /v2/admin/users/orphan-cleanup/candidates` — orphaned user cleanup.
- `GET /v1/admin/usage/any-user-daily-api-usage` — per-user usage for billing audits.

---

## Authentication summary

Most endpoints accept one or more of:

- **API key** (`Authorization: Bearer <key>`): grants read + write-on-behalf of the developer account. Required for almost all v2 endpoints.
- **User JWT** (`Authorization: Bearer <jwt>`): identifies a developer account. Used for billing, key management, and account admin.
- **Wallet signature**: required for any TX-emitting endpoint. Submitted as part of the request body alongside the unsigned TX.

The `andamio-app-template` (path 2) holds the API key server-side and exposes only the user-side flows to the browser. Path 3 (custom apps) should follow the same pattern.

---

## Cross-links

- Full OpenAPI spec: `specs/andamio-api.yaml` (123 endpoints).
- [Integration paths](./integration-paths.md) — CLI / app-template / custom.
- [Status enums](./status-enums.md) — return values you'll encounter.
- [TX loops](./tx-loops.yaml) — composed workflows that chain these endpoints.

> **Note on freshness**: This index is hand-maintained and covers all 12 v2 resource groups. If an endpoint is missing, check `specs/andamio-api.yaml` directly — that file is regenerated from API source and is always canonical.
