# Acceptance Test Prerequisites

Checklist for running Andamio transaction loop acceptance tests on preprod. Complete all items before starting any tx loop.

## Environment

- [ ] CLI installed: `andamio --version` (minimum v0.12.0 for chunked task hash fix)
- [ ] CLI pointed at preprod: `andamio config set-url https://preprod.api.andamio.io`
- [ ] API key configured: `andamio auth login --api-key <key>`
- [ ] Cardano submit configured: `andamio config show` should show a submit URL (Blockfrost preprod) and `project_id` header

## Wallets

You need **two wallets** with different roles:

| Role | Wallet | Used for |
|------|--------|----------|
| Owner / Teacher / Manager | Wallet A | course_create, modules_manage, assessment_assess, project_create, tasks_manage, task_assess |
| Student / Contributor | Wallet B | assignment_commit, credential_claim, project_join, project_credential_claim |

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
- [ ] **Has an Andamio access token** (check via Blockfrost or explorer):
  ```bash
  # Look for tokens with 'u' prefix under the access-token policy
  # Token name 'ualice' means alias is 'alice'
  ```
- [ ] **Has sufficient tADA**: Wallet A needs ~400 tADA (course + project creation). Wallet B needs ~50 tADA.
- [ ] **Login works with correct alias**:
  ```bash
  andamio user login --skey <wallet>/payment.skey \
    --alias <alias-from-access-token> \
    --address $(cat <wallet>/payment.addr)
  andamio user status  # should show alias and active session
  ```

### If wallets lack access tokens

Mint them first (requires ~5 ADA each):
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

## Switching Wallets

The CLI stores one JWT at a time. Switch with:
```bash
andamio user login --skey <other-wallet>/payment.skey --alias <alias> --address $(cat <other-wallet>/payment.addr)
```

No need to logout first — the new JWT replaces the old one.

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
