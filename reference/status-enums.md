# Andamio Status Enums — Canonical Reference

> The canonical status vocabulary emitted by the Andamio API. CLI, app, and custom integrations align to these values.

**Source of truth**: `andamio-api` Go code (paths in [Provenance](#provenance)). This doc is hand-curated against that source. If you see drift, the API code wins — file an issue.

**Last synced from API**: 2026-05-14

---

## Assignment commitment status

A student's commitment to a course assignment. Lives in `assignment_commitments_v2`.

| Value | Meaning | Transitions to | Retriable | Terminal | Driven by |
|-------|---------|----------------|-----------|----------|-----------|
| `AWAITING_SUBMISSION` | Student has committed but not yet submitted work | `SUBMITTED`, `PENDING_TX_LEAVE` | — | no | Student |
| `SUBMITTED` | Student has submitted; awaiting teacher assessment | `ACCEPTED`, `REFUSED` (via teacher TX) | — | no | Teacher |
| `ACCEPTED` | Teacher accepted the submission | `PENDING_TX_CLAIM` → `CREDENTIAL_CLAIMED` | — | no | Student (claim) |
| `REFUSED` | Teacher refused the submission | `SUBMITTED` (resubmit) | **yes** | no | Student (resubmit) |
| `CREDENTIAL_CLAIMED` | Student has claimed the credential NFT | — | — | **yes** | — |
| `LEFT` | Student left the course before completion | — | — | **yes** | — |
| `PENDING_TX_ASSESS` | Awaiting on-chain confirmation of teacher assessment | `ACCEPTED` or `REFUSED` | — | no | TX state machine |
| `PENDING_TX_CLAIM` | Awaiting on-chain confirmation of credential claim | `CREDENTIAL_CLAIMED` | — | no | TX state machine |
| `PENDING_TX_COMMIT` | Awaiting on-chain confirmation of initial commit | `AWAITING_SUBMISSION` | — | no | TX state machine |
| `PENDING_TX_LEAVE` | Awaiting on-chain confirmation of leave | `LEFT` | — | no | TX state machine |

**State machine** (forward-only, from `commitment_state_healer.go`):

```
AWAITING_SUBMISSION ──submit──> SUBMITTED ──accept──> ACCEPTED ──claim──> CREDENTIAL_CLAIMED
                                          ──refuse──> REFUSED ──resubmit──> SUBMITTED
AWAITING_SUBMISSION ──leave──> LEFT
```

Any state can have a `PENDING_TX_*` intermediate while a TX is in flight.

---

## Task commitment status

A contributor's commitment to a project task. Lives in `task_commitments`.

| Value | Meaning | Retriable | Terminal | Driven by |
|-------|---------|-----------|----------|-----------|
| `DRAFT` | Contributor is drafting commitment, not yet on-chain | — | no | Contributor |
| `COMMITTED` | Commit TX confirmed; contributor is working on the task | — | no | Contributor (submit) |
| `SUBMITTED` | Work submitted; awaiting manager assessment | — | no | Manager |
| `ACCEPTED` | Manager accepted; awaiting reward claim | — | no | Contributor (claim) |
| `REFUSED` | Manager refused; resubmission is allowed | **yes** | no | Contributor (resubmit) |
| `DENIED` | Refused **after deadline expired** — funds return to treasury | — | **yes** | — |
| `REWARDED` | Contributor claimed the reward | — | **yes** | — |
| `ABANDONED` | Contributor walked away (or deadline passed without submission) | — | **yes** | — |
| `PENDING_TX_*` | Intermediate state while TX is in flight | — | no | TX state machine |

`PENDING_TX_*` variants: `PENDING_TX_ASSESS`, `PENDING_TX_CLAIM`, `PENDING_TX_COMMIT`, `PENDING_TX_LEAVE`, `PENDING_TX_SUBMIT`.

**Key distinctions** (from `task_commitment_state_healer.go`):

- `REFUSED` is **not terminal** — resubmission re-enters the lifecycle (back to `COMMITTED`).
- `DENIED` is post-expiration terminal. Funds return to treasury.
- Terminal states (`DENIED`, `ACCEPTED`, `REWARDED`, `ABANDONED`) are not healed even if on-chain state differs.

---

## Project task status

A task published on a project. Lives in `project_tasks`.

| Value | Meaning | Driven by |
|-------|---------|-----------|
| `DRAFT` | Manager is drafting the task | Manager |
| `APPROVED` | Approved by manager; not yet on-chain | Manager |
| `PENDING_TX` | Awaiting confirmation of `tasks_manage` TX | TX state machine |
| `ON_CHAIN` | Task is live and accepting commitments | — |
| `COMPLETE` | Task is finished (all commitments resolved) | — |
| `EXPIRED` | Task deadline passed without completion | — |

> The earlier `CANCELLED` vs `PUBLISHED` ambiguity (CLI/app drift) is resolved: neither value exists in the canonical enum. The canonical set is `DRAFT`, `APPROVED`, `PENDING_TX`, `ON_CHAIN`, `COMPLETE`, `EXPIRED`. `BatchUpdateTaskStatusRequest` has a separate `CANCELLED` value but that is a **request input**, not a stored status.

---

## Course module status

A module published on a course. Lives in `course_modules_v2`.

| Value | Meaning | Driven by |
|-------|---------|-----------|
| `DRAFT` | Teacher is drafting the module | Teacher |
| `APPROVED` | Approved; not yet on-chain | Teacher |
| `PENDING_TX` | Awaiting confirmation of `modules_manage` TX | TX state machine |
| `ON_CHAIN` | Module is live and accepting enrollments | — |
| `ARCHIVED` | Module retired from active enrollment | Teacher |
| `DEPRECATED` | Module superseded but kept for historical records | Teacher |

State transition rules (from API request validators):
- `DRAFT ↔ APPROVED` is bidirectional (manager can revise an approved draft).
- `APPROVED → PENDING_TX` requires an `slt_hash` in the update request.
- Only `ON_CHAIN` is a valid post-confirmation target.

---

## TX lifecycle status

Transaction state machine — **not** a commitment status. Tracks pending Cardano TXs through Redis. Lives in `tx:state:*` Redis keys.

| Value | Meaning |
|-------|---------|
| `pending` | TX submitted; awaiting Andamioscan confirmation |
| `confirmed` | Confirmed on-chain by Andamioscan |
| `updated` | DB API updated with TX data (terminal happy path) |
| `failed` | TX failed (exceeded retries, or submission error) |
| `expired` | TX exceeded TTL (2h confirmation timeout) without confirmation |

Note: These are **lowercase**, distinct from the `UPPERCASE` commitment/module/task statuses.

**Timing constants** (from `tx_state_machine.go`):
- Pending TTL: 24 hours
- Confirmation timeout: 2 hours
- Poll interval: 5 seconds
- Max retries: 5

---

## Common confusion: TX state vs commitment state

Earlier planning notes referenced a "canonical chain" of `registered → submitted → confirmed → updated`. **That chain is not real.** It conflated two state machines:

- **TX lifecycle** (`pending`, `confirmed`, `updated`, `failed`, `expired`) tracks a single Cardano transaction.
- **Commitment status** (`AWAITING_SUBMISSION`, `SUBMITTED`, …) tracks the business state of a student/contributor commitment.

A single commitment may cycle through many TXs (commit, submit, assess, claim) — each with its own `pending → confirmed → updated` lifecycle. The commitment's status updates only after the relevant TX is `updated`.

---

## Provenance

Enums originate in `andamio-api` Go code:

| Enum | Source path |
|------|-------------|
| Assignment commitment | `internal/internal_api/andamio_db_client/client.go:162-174` |
| Task commitment | `internal/internal_api/andamio_db_client/client.go:546-560` |
| Project task | `internal/internal_api/andamio_db_client/client.go:498-506` |
| Course module | `internal/internal_api/andamio_db_client/client.go:232-239` |
| TX lifecycle | `internal/common/constants/tx_state_machine.go:8-19` |
| Assignment transitions | `internal/service/commitment_state_healer.go:55-92` |
| Task transitions | `internal/service/task_commitment_state_healer.go:70-100` |

**Drift mitigation**: This doc is hand-curated. v2 work to either auto-generate from API source at build time, or add a periodic sync check, is tracked separately.

## Cross-links

- CLI surfaces these values in `andamio user dashboard`, `andamio course owner`, `andamio project manager` — see [andamio-cli-context.md](./andamio-cli-context.md).
- App surfaces them in course/project dashboards.
- TX lifecycle is documented in detail in the API OpenAPI spec at `specs/andamio-api.yaml` under `/v2/tx/`.
