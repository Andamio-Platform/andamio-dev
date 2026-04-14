# Research Pass — Context for Needs-Context SLTs

> **Note (2026-04-05):** This document reflects the pre-combine SLT numbering. After this research pass was produced, M200.1 (exploration) and M200.2 (dev doc) were merged into a single "Mint your access token" lesson, and M200.3–M200.5 were renumbered to M200.2–M200.4. Current authoritative SLT list is in `01-slts.md`.

**Date:** 2026-04-05
**Method:** Three parallel Explore agents across local Andamio repos (`andamio-cli`, `andamio-app-template`, `andamio-app-v2`, `andamio-api`, `andamio-ai-context`)
**Goal:** Collect tangible examples that help a learner understand each SLT, and cross-check source code against SYSTEM_REFERENCE.md

## Summary

| # | SLT | Previous | After research |
|---|---|---|---|
| 100.1 | explain contribution-centered learning | Needs Context | **Ready** — unblocked 2026-04-05 by `andamio-ai-context/02-strategy/contribution-centered-learning.md` |
| 200.2 | mint an access token | Needs Context | **Ready** |
| 200.4 | log in headlessly with `.skey` | Needs Context | **Ready** |
| 200.5 | verify Attestation JWT offline | Needs Context | **Ready** |
| 300.3 | query user credentials | Needs Context | **Ready** |
| 400.3 | execute TX through state machine | Needs Context | **Ready** |
| 400.4 | diagnose TX failures | Needs Context | **Ready** |
| 500.2 | compute `slt_hash` for a module | Needs Context | **Ready** |
| 600.2 | compute `task_hash` for a task | Needs Context | **Ready** |
| 700.1 | choose integration strategy | Needs Context | **Ready** |
| 700.3 | handle TX failures in code | Needs Context | **Ready** |
| 700.4 | ship a minimal integration | Needs Context | **Ready** |

**New readiness totals:** 32 Ready · 0 Blocked · 0 Needs Human *(updated 2026-04-05 after pedagogy brief landed)*

**Drift against SYSTEM_REFERENCE.md:** Zero real inconsistencies. The CLI, the gateway API, and the production app's TX handling all align with SYSTEM_REFERENCE.md as of 2026-04-04. The only pending-release observation is stalled confirmed-state handling (GitHub issue #449) where the app's polling is defensively more graceful than the spec currently requires — expected to resolve with Monday's backend deployment.

## SLT 100.1 — resolved 2026-04-05

**Status:** Ready. Unblocked by a pedagogy brief authored directly into the team's shared AI context repo.

**Source:** `andamio-ai-context/02-strategy/contribution-centered-learning.md` (full path on James's machine: `~/projects/02-areas/andamio-circles/andamio-ai-context/02-strategy/contribution-centered-learning.md`)

**What the brief covers:**

- Definition of contribution-centered learning alongside the two alternatives it replaces (completion-centered, credential-centered).
- Concrete failure modes of each alternative.
- Two practical shapes for contribution-centered learning on Andamio: the course loop (lesson → evidence → teacher review → credential) and the project loop (funded task → escrow → contributor → manager review → paid + credentialed).
- A third shape currently in pilot: **feedback-as-contribution**. Evidence can be feedback on the lesson itself. Running in Cardano XP and the Midnight project-based learning work. Turns a course from a fixed artifact into a shared one.
- Why the model requires blockchain infrastructure: portability (credentials belong to the learner, outlive the institution) + composability (credentials can be prerequisites for other credentials on an open network).
- Who it's for: skill acquisition, professional credentialing, open-source onboarding. Plus a reframing of the obvious counterexample (compliance training) that shows the model changes *what the credential is for* rather than not applying.
- Closing thesis: *"A credential should prove you did the work, not that you showed up for it."*

**Quotable lines the M100 lesson author can use verbatim:**

1. *"A credential should mean that someone did the work and a qualified reviewer accepted it."* — opening for the M100.1 lesson.
2. *"The evidence is the work itself, the reviewer is a human who knows the domain, and the credential is the record of that exchange."* — one-sentence definition for the comprehension check rubric.
3. *"Gating on a completion certificate composes nothing, because the prerequisite reduces to 'this person showed up.'"* — single best line on why composability requires contribution-centered credentials. Also callable back in M500 and M600.
4. *"A course is a piece of living documentation, and the learner working through it carefully is often the person best positioned to improve it."* — feeds the M700.5 critique SLT directly.
5. *"A credential is only as valuable as the weight it can bear when something else is built on top of it."* — candidate for the closing line of the whole course.

**Downstream implications beyond M100:**

- **M700.5** ("critique the Andamio DX") gains a philosophical anchor. What was a soft reflective close is now *the protocol doing what the protocol does* — learner feedback is itself evidence of contribution under the feedback-as-contribution shape.
- **M500 and M600** open-paragraphs can call back to the pedagogy: the course loop is the ¶3 shape, the project loop is the same paragraph's second half. The mechanics of M500 and M600 now have a "you already know why this exists" anchor.
- **M100.1 comprehension check** can grade against the brief directly — no lesson-author reconstruction needed.

## Good examples, per SLT

Below, each now-Ready SLT has a verified example the lesson author can point to. File paths and command snippets are copy-pasteable.

---

### SLT 200.2 — Mint an access token on preprod

**How:** No dedicated CLI command; use the generic TX pipeline.

```bash
andamio tx run /v2/tx/global/user/access-token/mint \
  --body '{"alias":"myalias","initiator_data":{"change_address":"addr_test1...","used_addresses":["addr_test1..."]}}' \
  --skey ./payment.skey \
  --tx-type access_token_mint
```

**Expected output:**

```
Building transaction: POST /v2/tx/global/user/access-token/mint
✓ Built unsigned TX
✓ Signed with ./payment.skey (tx: abc123de...)
Submitting to https://preprod.submit.andamio.io
✓ Submitted to network
✓ Registered as access_token_mint
⏳ Waiting for confirmation...
State: pending
State: confirmed
State: updated
✓ Confirmed on-chain — complete!
```

**Source:** `andamio-cli/cmd/andamio/tx_build.go:32`, `andamio-cli/cmd/andamio/tx_register.go:25`

**Key teaching points:**
- `initiator_data` is required before an alias exists (SYSTEM_REFERENCE.md §4.1 exception). After minting, the alias is established and subsequent TXs use `alias` instead.
- 5 ADA fee goes to the protocol treasury.
- Once the TX reaches `updated`, the learner can run `andamio user me --output json` to see their on-chain alias.

---

### SLT 200.4 — Log in headlessly with `.skey` file

**How:**

```bash
andamio user login \
  --skey ./payment.skey \
  --alias myalias \
  --address $(cat wallet.addr)
```

**Expected output (text mode):**

```
Requesting login session...
Signing nonce with ./payment.skey...
Validating signature...

Authenticated as: myalias
User ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Key hash: d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3
```

**JSON mode (`--output json`):**

```json
{
  "alias": "myalias",
  "user_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "key_hash": "d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3"
}
```

**Implementation (for the lesson narrative):**

1. `POST /api/v2/auth/login/session` → `{id, nonce, expires_at}`
2. Sign nonce using CIP-8 with the `.skey`
3. `POST /api/v2/auth/login/validate` with `{id, address, access_token_alias, signature}` → JWT
4. JWT stored in `~/.andamio/config.yaml` under `user.jwt`

**Source:** `andamio-cli/cmd/andamio/user.go:45–84` (command), `260–360` (runHeadlessLogin)

**Required flags for headless:** `--skey`, `--alias`, `--address` (all three required together).

**For CI/CD:** redirect stderr to suppress progress: `andamio user login --skey ... 2>/dev/null`.

---

### SLT 200.5 — Verify an Attestation JWT offline

**Claim schema (Go):**

```go
type AccessTokenAttestationClaims struct {
    WalletAddress string `json:"wallet_address"`  // Bech32 wallet address from CIP-30
    jwt.RegisteredClaims
    // sub = alias, iss = "andamio-api", aud = ["access-token-verification"]
}
```

**Example decoded payload:**

```json
{
  "sub": "alice",
  "iss": "andamio-api",
  "aud": ["access-token-verification"],
  "wallet_address": "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp",
  "exp": 1710086400,
  "iat": 1710085800,
  "nbf": 1710085800
}
```

**JWKS URL:** `/.well-known/jwks.json` (at gateway service root)
**Key ID:** `"andamio-api-attestation-key"`
**Signing algorithm:** RS256
**Token lifetime:** 10 minutes
**Key rotation policy:** Not documented (single static RSA key pair loaded at startup — worth flagging as an open question)

**Flow for third-party apps:**
1. Call `POST /api/v2/verify/session` with the alias → get nonce
2. User's wallet signs the nonce via CIP-30
3. Exchange signature for attestation JWT via `POST /api/v2/verify/complete`
4. Verify the JWT offline using the public key fetched from `/.well-known/jwks.json`

**Source:**
- `andamio-api/internal/auth/jwt.go:23–29` (claim struct), `:120` (10-min TTL), `:124–154` (signing)
- `andamio-api/internal/handlers/v2/gateway_handlers/jwks_handlers.go:14–97`
- `andamio-api/internal/viewmodels/auth_viewmodels/access_token_verification_viewmodels.go:62–79`

**Teaching takeaway:** The 10-min window is intentional — attestation JWTs are meant to be used immediately (e.g., prove alias ownership to join a Discord, claim a quest reward), not stored and reused. Third-party apps should refuse tokens older than a few minutes even within the TTL.

---

### SLT 300.3 — Query user credentials and interpret the response

**Endpoint:** `POST /v2/course/student/credentials/list`
**Auth:** User JWT or API Key

**Response schema:**

```json
{
  "data": [
    {
      "course_id": "56-char hex policy ID",
      "course_title": "string or null",
      "is_enrolled": "boolean",
      "enrollment_status": "enrolled | completed",
      "claimed_credentials": ["slt_hash array"],
      "modules": [
        {
          "slt_hash": "64-char hex",
          "module_code": "numeric string (100, 200, 300)",
          "title": "string or null",
          "status": "ON_CHAIN | DEPRECATED | ARCHIVED"
        }
      ],
      "source": "merged | chain_only"
    }
  ],
  "meta": { "warning": "string or null" }
}
```

**Example response:**

```json
{
  "data": [
    {
      "course_id": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0",
      "course_title": "Introduction to Cardano Development",
      "is_enrolled": true,
      "enrollment_status": "enrolled",
      "claimed_credentials": [],
      "modules": [
        {
          "slt_hash": "8a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0",
          "module_code": "100",
          "title": "Wallets & Keys",
          "status": "ON_CHAIN"
        }
      ],
      "source": "merged"
    }
  ],
  "meta": null
}
```

**Source:**
- Handler: `andamio-api/internal/handlers/v2/merged_handlers/merged_handlers.go:579–625`
- Orchestration: `andamio-api/internal/orchestration/course_orchestrator.go` (ListStudentCredentials)
- Types: `andamio-api/internal/orchestration/types.go` (StudentCourseCredential)

**Teaching takeaway:** The `source` field on each course row is the learner's window into Andamio's merge layer — it tells them whether the gateway had both off-chain and on-chain data (`merged`) or only on-chain data (`chain_only`). `claimed_credentials` is an array of `slt_hash` values representing modules the learner has fully completed and claimed credentials for.

---

### SLT 400.3 — Execute a TX through the full state machine

**Manual five-step invocation:**

```bash
# 1. Build
andamio tx build /v2/tx/course/teacher/modules/manage --body-file modules.json

# 2. Sign
andamio tx sign --tx <unsigned_tx_hex> --skey ./payment.skey

# 3. Submit
andamio tx submit --tx <signed_tx_hex> --submit-url https://preprod.submit.andamio.io

# 4. Register
andamio tx register --tx-hash <hash> --tx-type modules_manage

# 5. Poll
andamio tx status <hash>
```

**Wrapper:**

```bash
andamio tx run /v2/tx/course/teacher/modules/manage \
  --body-file modules.json \
  --skey ./payment.skey \
  --tx-type modules_manage \
  --instance-id <course_id>
```

**Key flags per step:**

| Step | Required flags | Notes |
|---|---|---|
| `tx build` | `--body` or `--body-file` | Body is TX-type-specific JSON |
| `tx sign` | `--tx`, `--skey` | Can use `--tx-file` for large CBOR |
| `tx submit` | `--tx`, `--submit-url` | URL often read from config |
| `tx register` | `--tx-hash`, `--tx-type`, optional `--instance-id` | `instance-id` is course_id or project_id |
| `tx status` | positional `tx-hash` | No flags required |
| `tx run` | `--skey`, `--tx-type`, `--body`/`--body-file`, optional `--no-wait`, `--timeout`, `--instance-id` | Wraps all 5 |

**Source:**
- `andamio-cli/cmd/andamio/tx_build.go`
- `andamio-cli/cmd/andamio/tx_sign.go`
- `andamio-cli/cmd/andamio/tx_submit.go`
- `andamio-cli/cmd/andamio/tx_register.go`
- `andamio-cli/cmd/andamio/tx.go:30–37`
- `andamio-cli/cmd/andamio/tx_run.go` and `tx_lifecycle.go`

**Teaching takeaway:** The manual five steps exist for debugging, scripting control, and learning. `tx run` is what production code uses. The lesson should walk through the manual path first (to expose the API surface), then introduce `tx run` as the production shortcut.

---

### SLT 400.4 — Diagnose and respond to TX failures

**The five failure modes, with real response shapes:**

#### 1. Build error (Atlas rejects the body)

```bash
$ andamio tx build /v2/tx/course/teacher/modules/manage --body '{"invalid": "data"}'
Error: failed to build transaction: 400 Bad Request: {"error": "alias field required"}
# exit code: 1
```

Atlas errors pass through the gateway unchanged — not structured gateway responses. The lesson should teach learners to parse HTTP 4xx + error body.

#### 2. Sign error (client-side)

```bash
$ andamio tx sign --tx abc123... --skey ./nonexistent.skey
Error: failed to load signing key: open ./nonexistent.skey: no such file or directory
# exit code: 1
```

Sign errors never touch the gateway — they're local. Common causes: missing `.skey`, bad skey format, user declined in browser wallet.

#### 3. Submit rejection (Cardano chain rejects)

```bash
$ andamio tx submit --tx abc123... --submit-url https://preprod.submit.andamio.io
Error: submit failed: 400 Bad Request: transaction validation failed
# exit code: 1
```

Common causes: insufficient ADA for fees, bad UTxO selection, script validation failure.

#### 4. Chain expiry (2h timeout, never landed)

```bash
$ andamio tx status abc123...
```

```json
{
  "tx_hash": "abc123...",
  "tx_type": "assignment_submit",
  "state": "expired",
  "user_id": "user123",
  "instance_id": "course-id-56hex",
  "metadata": {},
  "created_at": "2026-04-05T12:00:00Z",
  "updated_at": "2026-04-05T14:00:30Z",
  "confirmed_at": null,
  "retry_count": 10,
  "not_indexed_count": 72,
  "last_error": "Not found on chain"
}
```

Terminal state. Safe to retry the whole operation with a new TX.

#### 5. DB sync failure (chain confirmed, DB update failed 5×)

```json
{
  "tx_hash": "8a3b5c7d...",
  "tx_type": "modules_manage",
  "state": "failed",
  "user_id": "user123",
  "instance_id": "course-id-56hex",
  "metadata": {},
  "created_at": "2026-04-05T12:00:00Z",
  "updated_at": "2026-04-05T12:05:00Z",
  "confirmed_at": "2026-04-05T12:00:30Z",
  "retry_count": 5,
  "last_error": "Module not found in DB",
  "failure_reason": "MODULE_NOT_FOUND"
}
```

The `failure_reason` field is enum-like: `MODULE_NOT_FOUND`, `TASK_NOT_FOUND`, etc. The on-chain TX succeeded; only the DB mirror failed. Recovery is operational (create the missing DB record, gateway retries automatically).

**Source:**
- Status handler: `andamio-api/internal/handlers/v2/tx_state_handlers/tx_state_handlers.go:52–82, 224–268`
- Lifecycle error handling: `andamio-cli/cmd/andamio/tx_lifecycle.go:36–237`

**HTTP codes for `tx status`:**
- `200` — TX found (any state)
- `404` — TX not in Redis (expired from TTL, or never registered)
- `400` — bad `tx_hash` format
- `500` — service error

**Key teaching insight:** The gateway only tracks state *from register onward*. Build and submit errors are the client's responsibility to handle — they never become TX records. Expired and failed both carry the `last_error` field, but only `failed` has `failure_reason` (because `failed` is structurally different: chain succeeded, DB didn't).

---

### SLT 500.2 — Compute an `slt_hash` for a course module

**How:**

```bash
# From SLT text
andamio course credential compute-hash \
  --slt "Describe how Cardano works" \
  --slt "Build a smart contract"

# From a markdown outline file
andamio course credential compute-hash --file ./compiled/my-course/101/outline.md

# JSON output
andamio course credential compute-hash \
  --slt "SLT 1" \
  --slt "SLT 2" \
  --output json
```

**Expected output (text):**

```
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1
SLT count: 2
```

**JSON output:**

```json
{
  "slt_hash": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
  "slt_count": 2,
  "slts": ["Describe how Cardano works", "Build a smart contract"]
}
```

**Source:** `andamio-cli/cmd/andamio/course_credential.go:15–224`

**Flags:**
- `--slt` (repeatable) — SLT text string
- `--file` — path to `outline.md` (parsed from `## SLTs` section)
- `--output json` — structured output

**Verification command (requires auth):**

```bash
andamio course credential verify-hash <course-id>
```

This pulls the course's modules from the API and recomputes each `slt_hash` locally, reporting any mismatches.

**Teaching takeaway:** `slt_hash` computation is local and deterministic — no network call. The encoding is Blake2b-256 over a PlutusTx-serialized byte string list (NOT Plutus Data). Changing a single character in any SLT produces a completely different hash. This is the learner's first concrete taste of content-addressed identity on-chain.

---

### SLT 600.2 — Compute a `task_hash` for a project task

**How:**

```bash
# From individual fields
andamio project task compute-hash \
  --content "Build API endpoint" \
  --lovelace 5000000 \
  --expiration 2026-12-31

# With native asset tokens
andamio project task compute-hash \
  --content "Build API endpoint" \
  --lovelace 5000000 \
  --expiration 2026-12-31 \
  --token "722c475bebb10...,XP,50"

# From markdown file with YAML frontmatter
andamio project task compute-hash --file ./tasks/001-build-api.md
```

**JSON output:**

```json
{
  "task_hash": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
  "fields": {
    "content": "Build API endpoint",
    "lovelace": 5000000,
    "expiration_ms": 1735689600000,
    "tokens": [
      { "policy_id": "722c475bebb10...", "token_name": "XP", "quantity": 50 }
    ]
  }
}
```

**Source:** `andamio-cli/cmd/andamio/project_task.go:92–982`

**Verification command (requires auth):**

```bash
andamio project task verify-hash <project-id>
```

**Teaching takeaway:** The encoding contrast with `slt_hash` is the whole point of this SLT. Both are Blake2b-256, both are 64-char hex, but `slt_hash` hashes a raw PlutusTx byte string list while `task_hash` hashes Plutus Data wrapped in `Constr 0 [content, expiration, lovelace, native_assets]` with CBOR tag 121. The lesson should show the two commands side by side to make the difference concrete.

---

### SLT 700.1 — Choose the right integration strategy

**What the Andamio App Template (v2.1.0) actually gives you:**

| Feature | What it solves | Not-template equivalent work |
|---|---|---|
| Next.js 15 + App Router | Framework choice | Pick React SPA / Svelte / Remix / etc. |
| tRPC client, auto-typed from OpenAPI | API boilerplate | Hand-write fetch wrappers, manual types |
| Mesh SDK + CIP-30 integration | Wallet plumbing | Integrate Lucid/Mesh manually, handle CIP-30 events |
| JWT auth wiring (`RequireAuth`, login flow) | Session handling | Implement nonce signing, session storage |
| Zustand TX watcher store (survives navigation) | TX state management | Build TX polling + cross-page state yourself |
| SSE + polling hybrid for confirmation | Confirmation UX | Implement polling with retries, backoff, stalled detection |
| shadcn/ui + Tailwind v4 + semantic colors | Design system | Design component library |
| Pre-wired .env.example, preprod endpoints | Environment setup | Figure out which env vars, which URLs |
| 8 portable agent skills (`.skills/`) | Agentic workflows | Write your own or rely on external plugin |
| E2E tests with Playwright | Test infrastructure | Set up testing against preprod |

**The three legitimate strategies:**

1. **Fork the template** — best for developers shipping a full Andamio-first app. 9 minutes from `git clone` to minted access token on preprod.
2. **Direct API integration** — best for adding Andamio features to an existing app. Use the gateway API via your existing fetch layer; CLI for dev/ops; no wallet UX needed if you can delegate signing to users via their own tools.
3. **CLI-first (scripts, backend jobs)** — best for ops tooling, CI/CD, data pipelines. No UI, no wallet integration, just shell scripts or any language calling `andamio` as a subprocess.

**Source:** `andamio-app-template/` root, `andamio-app-template/README.md:13–26`, `andamio-app-template/src/` structure

**Teaching takeaway:** The choice isn't "which is better" — it's "which problem are you solving?" The template is for building an Andamio-native app. Direct API is for adding Andamio to something existing. CLI is for ops. The lesson should frame each as the right tool for a specific job, not as a hierarchy.

---

### SLT 700.3 — Handle TX failure modes gracefully in code

**All five failure modes have real code examples in the template and production app:**

#### Build error

From `andamio-app-template/src/hooks/tx/use-transaction.ts:199–225`:

```typescript
const response = await fetch(url, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(params),
});

if (!response.ok) {
  const errorText = await response.text();
  let errorDetails: string;
  try {
    const errorJson = JSON.parse(errorText) as {
      error?: string;
      details?: string;
      message?: string;
    };
    errorDetails = errorJson.details ?? errorJson.message ?? errorJson.error ?? errorText;
  } catch {
    errorDetails = errorText;
  }
  txLogger.buildResult(txType, false, { status: response.status, error: errorDetails });
  throw new Error(`Transaction API error: ${response.status} - ${errorDetails}`);
}
```

**Pattern:** Throw immediately, no retry. User sees the error and retries manually.

#### Sign error

From `use-transaction.ts:83–92`:

```typescript
function humanizeTxError(message: string): string {
  const lower = message.toLowerCase();
  if (lower.includes("user declined") || lower.includes("user rejected")) {
    return "You declined to sign the transaction.";
  }
  if (lower.includes("insufficient") && lower.includes("fund")) {
    return "Insufficient funds in your wallet to complete this transaction.";
  }
  return message;
}
```

**Pattern:** Translate low-level wallet errors to user-facing messages. Don't retry — user has to fix wallet state.

#### Submit rejection

From `andamio-app-v2/src/lib/tx-error-messages.ts`:

```typescript
const TX_ERROR_PATTERNS: Record<string, string> = {
  "ACCESS_TOKEN_ERROR": "You don't have a valid access token",
  "SCRIPT_FAILURE": "Transaction validation failed on-chain",
  "INSUFFICIENT_FUNDS": "Insufficient funds (UTxO or fees)",
  "INVALID_OUTPUT": "Invalid output state (datum/value mismatch)",
};
```

**Pattern:** Map Cardano script error codes to user language before surfacing.

#### Chain expiry

From `andamio-app-v2/src/lib/tx-polling-fallback.ts:65–165`:

```typescript
export async function pollUntilTerminal(
  txHash: string,
  authenticatedFetch: (url: string) => Promise<Response>,
  callbacks: PollCallbacks = {},
  options: PollOptions = {},
  signal?: AbortSignal
): Promise<TxStatus | null> {
  const { interval = 6_000, maxPolls = 150 } = options;

  for (let i = 0; i < maxPolls; i++) {
    if (signal?.aborted) return null;
    if (i > 0) await new Promise((r) => setTimeout(r, interval));

    const response = await authenticatedFetch(`${GATEWAY_API_BASE}/tx/status/${txHash}`);
    const status = (await response.json()) as TxStatus;
    callbacks.onStatus?.(status);

    if (TERMINAL_STATES.includes(status.state)) {
      callbacks.onComplete?.(status);
      return status;
    }
  }
}
```

**Pattern:** 6s polling interval, max 150 polls (~15 min). `expired` is terminal — surface a retry button.

#### DB sync failure

From `andamio-app-v2/src/lib/tx-polling-fallback.ts:118–134`:

```typescript
if (status.state === "confirmed" && status.last_error) {
  stalledCount++;
  if (stalledCount >= STALLED_THRESHOLD) {
    callbacks.onComplete?.(status);
    return status;
  }
} else {
  stalledCount = 0;
}
```

Where `STALLED_THRESHOLD = 5` (30 seconds at 6s intervals).

**Pattern:** Detect confirmed-with-error stuck state, treat as success for UX purposes. The on-chain TX succeeded; the DB mirror can be healed operationally.

**Pending-release note:** This stalled-state detection is currently the app being defensively ahead of the spec (GitHub issue #449). SYSTEM_REFERENCE.md will document the stalled-state handling after Monday's deployment. This is pending-release, not drift.

**Source:**
- `andamio-app-template/src/hooks/tx/use-transaction.ts`
- `andamio-app-v2/src/lib/tx-polling-fallback.ts`
- `andamio-app-v2/src/lib/tx-error-messages.ts`
- `andamio-app-v2/src/lib/api-error-messages.ts`

---

### SLT 700.4 — Ship a minimal working integration

**Day-one file structure the learner sees:**

```
andamio-app-template/
├── src/
│   ├── app/
│   │   ├── (app)/
│   │   │   ├── dashboard/
│   │   │   ├── course/[courseId]/
│   │   │   └── api-setup/
│   │   └── layout.tsx                 # auth + wallet + tRPC providers wired
│   ├── components/
│   │   ├── auth/                      # RequireAuth, wallet connect
│   │   ├── tx/                        # 20+ TX form components
│   │   └── andamio/                   # shadcn/ui wrappers with semantic colors
│   ├── hooks/
│   │   ├── auth/use-andamio-auth.ts
│   │   └── tx/
│   │       ├── use-transaction.ts     # main TX hook
│   │       └── use-tx-stream.ts       # confirmation tracking
│   ├── stores/
│   │   └── tx-watcher-store.ts        # cross-page TX tracking
│   └── config/
│       ├── transaction-ui.ts          # 18 TX types mapped to endpoints
│       └── transaction-schemas.ts     # Zod validation
├── .env.example
├── .skills/                            # 8 agent skills
├── package.json
└── README.md
```

**Setup flow (~9 minutes total):**

| Step | Time | Output |
|---|---|---|
| Fork + clone | 1 min | local repo |
| `npm install` | 3 min | node_modules ready |
| `cp .env.example .env` + add API key | 2 min | env configured |
| `npm run dev` | 30 sec | http://localhost:3000 |
| Connect wallet (Nami/Eternl/social) | 30 sec | wallet connected |
| Click "Mint Access Token" + sign | 30 sec | TX on chain, spinner |
| Wait for `updated` | 20–90 sec | enrolled, re-authenticated |
| **Total** | **~9 min** | **fully working enrolled user** |

**First code change the learner makes (from the template's `/getting-started` skill):** change brand colors in `src/styles/globals.css`:

```css
:root {
  --primary: oklch(0.669 0.199 38.581);   /* your brand */
  --secondary: oklch(0.387 0.134 250.505);
  /* 20+ more semantic colors */
}
```

Hot reload → entire app rebranded.

**First code that calls Andamio:**

```typescript
// src/app/(app)/dashboard/page.tsx — already wired in the template
import { useAndamioFetch } from "~/hooks/api/use-andamio-fetch";

export default function DashboardPage() {
  const { data: courses } = useAndamioFetch({
    endpoint: "/course/list",
    authenticated: true,
  });

  return (
    <div>
      {courses?.map(course => <div key={course.id}>{course.title}</div>)}
    </div>
  );
}
```

Types auto-generated from the OpenAPI spec. No API client boilerplate.

**Source:** `andamio-app-template/README.md:13–26`, full repo structure

**Teaching takeaway:** The template's biggest gift is that "minimal working integration" doesn't mean "write from scratch." It means "fork, configure, run, modify." M700 lessons should frame the capstone as extending the template rather than building from a blank slate — learners who try the blank-slate path are implicitly choosing strategy #2 (direct API), and that's a different (larger) lesson.

---

## Pending-release observations (not drift)

1. **Stalled confirmed-state handling (GitHub issue #449)** — `andamio-app-v2/src/lib/tx-polling-fallback.ts:118–134` treats `state: confirmed` + `last_error` present for 5+ polls as a terminal success state. SYSTEM_REFERENCE.md currently says `confirmed` is not terminal (wait for `updated`/`failed`/`expired`). The app is being defensively more graceful than the spec requires, anticipating a Monday deployment that will add explicit guidance on stalled-state handling to the gateway.

Nothing else pending-release identified in the repos I searched.

## Drift inventory

**Zero real drift** between source code and SYSTEM_REFERENCE.md across the 11 unlocked SLTs.

## Open documentation gaps (feed back to team)

1. ~~**Contribution-centered learning pedagogy brief**~~ — **resolved 2026-04-05**. Brief now exists at `andamio-ai-context/02-strategy/contribution-centered-learning.md`.
2. **Attestation JWT key rotation policy** — implementation uses a single static RSA key pair loaded at startup. No rotation policy is documented. Worth flagging for the team: if keys leak, there's no documented rotation process. Low urgency for the course, but a real protocol gap.

## Updated readiness totals

| Status | Count | Change from Phase 4 |
|---|---|---|
| Ready | 32 | +12 (from Needs Context) |
| Needs Context | 0 | −12 |
| Needs Human | 0 | 0 |

**All 32 SLTs are ready for lesson drafting.** SLT 100.1 was unblocked 2026-04-05 when the team authored the contribution-centered-learning pedagogy brief directly into `andamio-ai-context`.
