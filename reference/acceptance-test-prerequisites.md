# Acceptance Test Prerequisites

Checklist for running Andamio transaction loop acceptance tests on preprod. Complete all items before starting any tx loop.

## Environment

- [ ] CLI installed: `andamio --version` (minimum v0.13.3 — the current release)
- [ ] CLI pointed at preprod: `andamio config set-url https://preprod.api.andamio.io`
- [ ] API key configured: `andamio auth login --api-key <key>`
- [ ] Cardano submit configured: `andamio config show` should show a submit URL (Blockfrost preprod) and `project_id` header

## Wallets

You need **two wallets** with different roles:

| Role | Kind | Wallet | Established by | Used for |
|------|------|--------|----------------|----------|
| Owner | granted | Wallet A | standing up the course or project | course_create, project_create |
| Teacher | granted | Wallet A | `/v2/tx/course/owner/teachers/manage`, run by the Owner | modules_manage, assessment_assess |
| Manager | granted | Wallet A | `/v2/tx/project/owner/managers/manage`, run by the Owner | tasks_manage, task_assess |
| Student | participant | Wallet B | nothing — committing makes you one | assignment_submit, credential_claim |
| Contributor | participant | Wallet B | nothing — committing makes you one | project_join, project_credential_claim |

**Granted** roles are established by an on-chain transaction and must exist before the loops
that use them will run. Owning a course or project grants neither Teacher nor Manager — if
Wallet A is to author or assess, run the relevant `manage` transaction first.

**Participant** roles are not granted and there is no roster. A person is a learner or a
contributor by virtue of having made a commitment, so there is nothing to set up for Wallet B
beyond the wallet checks below.

### One wallet, many identities

An Andamio identity is an access token — a `u`-prefixed NFT under the global access-token policy.
A wallet can hold **several**, all signable with the same `payment.skey`, and
**`andamio user login` succeeds for every one of them.** `andamio user status` then reports an
active session whichever alias you picked, so it is evidence that a session exists — never
evidence that you are logged in as the identity your test needs.

Roles hang off the alias, not the wallet. Picking the wrong alias from the right wallet fails in
two ways, and only one of them is loud:

| Wrong-alias case | What you see |
|------------------|--------------|
| Alias holds the role, but not on the course/project you meant | `422 UNPROCESSABLE_ENTITY`, `TEACHER_NOT_ALLOWED`, exit 1 |
| Alias holds the role on its own courses/projects, just not the fixture you wanted | `teacher assignments list` → **0 results, exit 0** |

The second is the dangerous one: a green run that assesses nothing and reports success. Verify the
role and the fixture, not the session — see the login check below.

### Per-wallet checklist

For each wallet, verify:

- [ ] Has `payment.skey`, `payment.vkey`, `payment.addr` files
- [ ] **Skey matches address** (critical — login will succeed but txs will fail if mismatched):
  ```bash
  # These two hashes must match:
  cardano-cli conway address key-hash --payment-verification-key-file <wallet>/payment.vkey
  cardano-cli conway address info --address $(cat <wallet>/payment.addr)
  # payment key hash from address info must equal the key-hash output
  ```
- [ ] **Enumerate _every_ Andamio access token in the wallet** — do not go looking for "the" one:
  ```bash
  # preprod policy; mainnet is ff5d0640b5a2717646d3f3151d100d57d194fdfa88cacf03f9edc568
  POLICY=aa1cbea2524d369768283d7c8300755880fd071194a347cf0a4e274f
  curl -s -H "project_id: $BLOCKFROST_PROJECT_ID" \
    "https://cardano-preprod.blockfrost.io/api/v0/addresses/$(cat <wallet>/payment.addr)" \
  | jq -r --arg p "$POLICY" '.amount[] | select(.unit | startswith($p)) | .unit[56:]' \
  | while read -r hex; do echo "$hex" | xxd -r -p; echo; done
  ```
  Each line printed is a token name; strip the leading `u` for the alias (`ualice` → `alice`).
  If more than one comes back, decide which alias you need **before** logging in — see
  [Shared preprod wallets](#shared-preprod-wallets).
- [ ] **Has sufficient tADA**: Wallet A needs ~400 tADA (course + project creation). Wallet B needs ~50 tADA.
- [ ] **Login lands on the identity you want** — check the role, not the session:
  ```bash
  andamio user login --skey <wallet>/payment.skey \
    --alias <alias-you-chose> \
    --address $(cat <wallet>/payment.addr)

  andamio user status   # session is active — true for ANY alias in the wallet, proves nothing

  # Now prove the identity. Run the check for the role this wallet plays in the run:
  andamio course owner list  --output json   # Owner:   must contain the course under test
  andamio teacher courses    --output json   # Teacher: must contain the course under test
  andamio project owner list --output json   # Owner:   must contain the project under test
  andamio manager projects   --output json   # Manager: must contain the project under test
  ```
  An empty or non-matching list means either you picked the wrong alias out of the wallet or the
  granting transaction has not been run. Settle which before continuing — a green `andamio user
  status` is not a passing check.
- [ ] **The fixture the run needs is visible to this alias.** For an assessment leg, that means a
  submission actually awaiting review:
  ```bash
  andamio teacher assignments list --course <course-id> --output json   # course assessment
  andamio project manager commitments --project-id <project-id> --output json  # task assessment
  ```
  An empty result here exits 0. Treat it as a failed precondition, not a passing one.

<a id="shared-preprod-wallets"></a>
### Shared preprod wallets

Accurate as of **2026-08-24**. Re-verify before relying on it — aliases and fixtures drift.

`preprod-wallets/andamio-preprod-001` holds **three** access tokens under policy
`aa1cbea2524d369768283d7c8300755880fd071194a347cf0a4e274f`, all signable with the same `payment.skey`:

| Alias | Teacher courses | Commitments awaiting review |
|-------|-----------------|-----------------------------|
| `qa-1778157478` | `beebcdee…`, `9d1682d2…` (broken off-chain DB state) | **1 — `SUBMITTED`** |
| `tester_0001` | `b9baa6ba…`, `9f437601…`, `4ef42f85…` | **0** |
| `andamio-preprod-001` | `f2298842…` | not surveyed |

So an acceptance run that must assess a `SUBMITTED` commitment has to log in as `qa-1778157478`.
`tester_0001` is a teacher on three courses with nothing to review: the run goes green having done
no work. No single alias in this wallet currently satisfies both "owner/teacher/manager identity"
and "has a submission to assess" — split the roles across aliases or mint the missing fixture.

### If wallets lack access tokens

Mint them first (requires ~5 ADA each). Minting adds an alias to the wallet, it does not replace
the ones already there — record the new alias alongside the existing map:
```bash
andamio tx run /v2/tx/global/user/access-token/mint \
  --body '{"alias":"<chosen-alias>","initiator_data":"<bech32-address>"}' \
  --skey <wallet>/payment.skey \
  --tx-type access_token_mint
```

See `tx-loops.yaml` loop 15 (general.access-token) for details.

## Test Execution Order

Follow the dependency graph in `tx-loops.yaml`:

```
Loop 16: general.auth.headless (login both wallets)
  └─ Loop 1: course.setup (Wallet A)
       ├─ Loop 3: course.credential (Wallet B submits, Wallet A assesses)
       │    └─ Loop 2: project.setup (Wallet A)
       │         └─ Loop 4: project.credential (Wallet B commits, Wallet A assesses)
       └─ Variants (7, 8, 9, etc.) as needed
```

## Switching Wallets — and Switching Aliases Within One Wallet

The CLI stores one JWT at a time. Switch with:
```bash
andamio user login --skey <other-wallet>/payment.skey --alias <alias> --address $(cat <other-wallet>/payment.addr)
```

No need to logout first — the new JWT replaces the old one.

The same command switches *identity within a single wallet*: same `--skey`, same `--address`, a
different `--alias`. It succeeds for any access token the wallet holds, so re-run the role check
from the per-wallet checklist after every switch. `andamio user status` will look identical either
way.

## Verification Commands

After each tx, verify with:

| What | Command |
|------|---------|
| TX status | `andamio tx status <hash> --output json` |
| Course modules | `andamio course modules <course-id> --output json` |
| Student commitments | `andamio course student commitments --output json` |
| Student credentials | `andamio course student credentials --output json` |
| Project details | `andamio project get <project-id> --output json` |
| Project tasks | `andamio project tasks <project-id> --output json` |
| Contributor commitments | `andamio project contributor commitments --output json` |
