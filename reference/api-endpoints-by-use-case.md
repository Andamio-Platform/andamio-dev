<!-- GENERATED FILE — DO NOT EDIT BY HAND.
     Regenerate with: python3 scripts/gen-endpoint-index.py
     Source: specs/andamio-api.yaml (the public API contract). -->

# Andamio API endpoints by use case

> "I want to ___" → endpoint. Generated from the public contract in `specs/andamio-api.yaml`, so it cannot drift from it.

**78 operations across 77 paths.** All paths are relative to `/api`. This is the public surface only — administrative and internal operations are not part of the contract and do not appear here.

For full request and response schemas, read the spec directly or use the `/explore-api` skill.

## Platform Auth

### User Auth

End-users authenticate to Andamio apps by signing a message from a wallet that holds an Andamio Access Token. Once authenticated, end-users can edit content and make commitments.

| I want to... | Endpoint | Auth |
|---|---|---|
| Initiate login session | `POST /v2/auth/login/session` | API key |
| Validate wallet signature | `POST /v2/auth/login/validate` | API key |

### User Profile

User profile and account management - view profile, usage stats, and account settings.

| I want to... | Endpoint | Auth |
|---|---|---|
| Get dashboard | `POST /v2/user/dashboard` | API key + JWT |

## Courses

### Course Discovery

Course discovery and enrollment - browse courses, view details, and check enrollment status.

| I want to... | Endpoint | Auth |
|---|---|---|
| Get assignment | `GET /v2/course/user/assignment/{course_id}/{course_module_code}` | API key |
| Get course detail | `GET /v2/course/user/course/get/{course_id}` | API key |
| List courses | `GET /v2/course/user/courses/list` | API key |
| Get introduction | `GET /v2/course/user/introduction/{course_id}/{course_module_code}` | API key |
| Get lesson | `GET /v2/course/user/lesson/{course_id}/{course_module_code}/{slt_index}` | API key |
| List course modules | `GET /v2/course/user/modules/{course_id}` | API key |
| List SLTs | `GET /v2/course/user/slts/{course_id}/{course_module_code}` | API key |

### Student Actions

Student course actions - enroll, submit assignments, track progress, and view grades.

| I want to... | Endpoint | Auth |
|---|---|---|
| Get commitment | `POST /v2/course/student/assignment-commitment/get` | API key + JWT |
| List my commitments | `POST /v2/course/student/assignment-commitments/list` | API key + JWT |
| Submit commitment | `POST /v2/course/student/commitment/submit` | API key + JWT |
| Update commitment evidence | `POST /v2/course/student/commitment/update` | API key + JWT |
| List my courses | `POST /v2/course/student/courses/list` | API key + JWT |
| List my credentials | `POST /v2/course/student/credentials/list` | API key + JWT |

### Teacher Actions

Teacher course actions - grade assignments, manage students, and view course analytics.

| I want to... | Endpoint | Auth |
|---|---|---|
| Review commitment | `POST /v2/course/teacher/assignment-commitment/review` | API key + JWT |
| List pending reviews | `POST /v2/course/teacher/assignment-commitments/list` | API key + JWT |
| Create course module | `POST /v2/course/teacher/course-module/create` | API key + JWT |
| Delete course module | `POST /v2/course/teacher/course-module/delete` | API key + JWT |
| Publish course module | `POST /v2/course/teacher/course-module/publish` | API key + JWT |
| Register course module from chain | `POST /v2/course/teacher/course-module/register` | API key + JWT |
| Update course module | `POST /v2/course/teacher/course-module/update` | API key + JWT |
| Update course module status | `POST /v2/course/teacher/course-module/update-status` | API key + JWT |
| List course modules | `POST /v2/course/teacher/course-modules/list` | API key + JWT |
| List my courses | `POST /v2/course/teacher/courses/list` | API key + JWT |

### Course Management

Course owner operations - create courses, manage content, configure settings, and manage teachers.

| I want to... | Endpoint | Auth |
|---|---|---|
| Create course | `POST /v2/course/owner/course/create` | API key + JWT |
| Register course | `POST /v2/course/owner/course/register` | API key + JWT |
| Update course | `POST /v2/course/owner/course/update` | API key + JWT |
| List my courses | `POST /v2/course/owner/courses/list` | API key + JWT |

## Projects

### Project Discovery

Project discovery and membership - browse projects, view details, and check membership status.

| I want to... | Endpoint | Auth |
|---|---|---|
| Get project detail | `GET /v2/project/user/project/{project_id}` | API key |
| List projects | `GET /v2/project/user/projects/list` | API key |
| List tasks | `POST /v2/project/user/tasks/list` | API key |

### Contributor Actions

Contributor project actions - commit to tasks, submit work, and claim rewards.

| I want to... | Endpoint | Auth |
|---|---|---|
| Delete commitment | `POST /v2/project/contributor/commitment/delete` | API key + JWT |
| Get commitment | `POST /v2/project/contributor/commitment/get` | API key + JWT |
| Submit commitment | `POST /v2/project/contributor/commitment/submit` | API key + JWT |
| Update commitment | `POST /v2/project/contributor/commitment/update` | API key + JWT |
| List my commitments | `POST /v2/project/contributor/commitments/list` | API key + JWT |
| List my projects | `POST /v2/project/contributor/projects/list` | API key + JWT |

### Manager Actions

Project manager actions - assign tasks, review submissions, and manage contributors.

| I want to... | Endpoint | Auth |
|---|---|---|
| List project commitments (manager view) | `POST /v2/project/manager/commitments/list` | API key + JWT |
| Get qualified contributors | `GET /v2/project/manager/contributors/get-qualified` | API key + JWT |
| List my projects | `POST /v2/project/manager/projects/list` | API key + JWT |
| Create task | `POST /v2/project/manager/task/create` | API key + JWT |
| Delete task | `POST /v2/project/manager/task/delete` | API key + JWT |
| Update task | `POST /v2/project/manager/task/update` | API key + JWT |
| List tasks | `POST /v2/project/manager/tasks/list` | API key + JWT |

### Project Management

Project owner operations - create projects, manage treasury, and configure settings.

| I want to... | Endpoint | Auth |
|---|---|---|
| Create project | `POST /v2/project/owner/project/create` | API key + JWT |
| Register project | `POST /v2/project/owner/project/register` | API key + JWT |
| Update project | `POST /v2/project/owner/project/update` | API key + JWT |
| List my projects | `POST /v2/project/owner/projects/list` | API key + JWT |

## Transactions

### Tx State

Transaction state management - track pending transactions and handle confirmations.

| I want to... | Endpoint | Auth |
|---|---|---|
| Get pending transactions | `GET /v2/tx/pending` | API key |
| Register pending transaction | `POST /v2/tx/register` | API key |
| Get transaction status | `GET /v2/tx/status/{tx_hash}` | API key |
| Stream transaction status | `GET /v2/tx/stream/{tx_hash}` | API key |
| Get valid transaction types | `GET /v2/tx/types` | API key |

### Global TX

Global transaction operations - mint access tokens and manage global state.

| I want to... | Endpoint | Auth |
|---|---|---|
| Mint access token | `POST /v2/tx/global/user/access-token/mint` | API key |

### Instance TX

Instance-level transactions - initialize and configure Andamio instances.

| I want to... | Endpoint | Auth |
|---|---|---|
| Create course | `POST /v2/tx/instance/owner/course/create` | API key |
| Create project | `POST /v2/tx/instance/owner/project/create` | API key |

### Course TX

Course transactions - on-chain course creation, enrollment, and assignment management.

| I want to... | Endpoint | Auth |
|---|---|---|
| Manage teachers | `POST /v2/tx/course/owner/teachers/manage` | API key |
| Commit to assignment | `POST /v2/tx/course/student/assignment/commit` | API key |
| Update assignment | `POST /v2/tx/course/student/assignment/update` | API key |
| Claim course credential | `POST /v2/tx/course/student/credential/claim` | API key |
| Assess assignments | `POST /v2/tx/course/teacher/assignments/assess` | API key |
| Manage course modules | `POST /v2/tx/course/teacher/modules/manage` | API key |

### Project TX

Project transactions - on-chain project creation, task commits, and reward distribution.

| I want to... | Endpoint | Auth |
|---|---|---|
| Claim project credential | `POST /v2/tx/project/contributor/credential/claim` | API key |
| Task action | `POST /v2/tx/project/contributor/task/action` | API key |
| Commit to task | `POST /v2/tx/project/contributor/task/commit` | API key |
| Assess tasks | `POST /v2/tx/project/manager/tasks/assess` | API key |
| Manage tasks | `POST /v2/tx/project/manager/tasks/manage` | API key |
| Manage contributor blacklist | `POST /v2/tx/project/owner/contributor-blacklist/manage` | API key |
| Manage managers | `POST /v2/tx/project/owner/managers/manage` | API key |
| Add funds to treasury | `POST /v2/tx/project/user/treasury/add-funds` | API key |

## Public

### User Lookup

Public user lookup - search and view public user profiles.

| I want to... | Endpoint | Auth |
|---|---|---|
| Check alias exists | `GET /v2/user/exists/{alias}` | API key |

## Other

### Keys

| I want to... | Endpoint | Auth |
|---|---|---|
| List API keys | `GET /v2/keys` | JWT |
| Create API key | `POST /v2/keys` | JWT |
| Delete API key | `DELETE /v2/keys/{id}` | JWT |

### Verify

| I want to... | Endpoint | Auth |
|---|---|---|
| Complete verification | `POST /v2/verify/complete` | API key |
| Start verification session | `POST /v2/verify/session` | API key |
