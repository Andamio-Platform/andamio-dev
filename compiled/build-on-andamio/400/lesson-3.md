# Execute an Andamio transaction through its full state machine

## Before we start

`andamio tx run` wraps all five state-machine steps in one command. This lesson opens the wrapper. You'll see the five individual CLI commands and use `tx status` to inspect a real transaction you've already run. When something breaks, you need to know which step failed.

## The five commands

### 1. `andamio tx build`

```bash
andamio tx build <endpoint> --body-file <file>
```

Sends JSON to the API → API returns unsigned CBOR hex. Nothing touches the chain. You can discard the result. Build doesn't require a JWT on most endpoints — it's effectively a preview.

### 2. `andamio tx sign`

```bash
andamio tx sign --tx <unsigned_cbor_hex> --skey ./payment.skey
```

Signs the CBOR locally. Private key never leaves your machine. No network calls. Signed CBOR can sit on disk indefinitely before submission.

### 3. `andamio tx submit`

```bash
andamio tx submit --tx <signed_cbor_hex>
```

Broadcasts to Cardano. Returns a tx_hash. **This is the point of no return** — once submitted, the TX will either land or be rejected. Write down the hash immediately.

### 4. `andamio tx register`

```bash
andamio tx register --tx-hash <hash> --tx-type <type>
```

Tells the Andamio API to track this TX. Without registration, the TX lands on-chain but the API never syncs its off-chain view to match.

### 5. `andamio tx status`

```bash
andamio tx status <tx_hash>
```

Returns the full state record:

```json
{
  "tx_hash": "a1b2c3d4e5f6...",
  "tx_type": "access_token_mint",
  "state": "updated",
  "created_at": "2026-04-05T12:00:00Z",
  "updated_at": "2026-04-05T12:00:45Z",
  "confirmed_at": "2026-04-05T12:00:30Z"
}
```

This is the command you'll use most — the live window into what a transaction is doing.

## How `tx run` wraps these

```
✓ Built unsigned TX
✓ Signed with ./payment.skey
✓ Submitted to network (tx: a1b2c3...)
✓ Registered as access_token_mint
⏳ Waiting for confirmation...
   State: pending
   State: confirmed
   State: updated
✓ Complete
```

Each checkmark is one of the five commands completing. The `State:` lines are repeated `tx status` calls in the wait step. `tx run` is what you use for normal writes; the individual commands are for when a write breaks midway.

## Your turn

Inspect the access token mint from M200.1:

```bash
andamio tx status <your-mint-tx-hash>
```

If you didn't save the hash, find it on [preprod.cardanoscan.io](https://preprod.cardanoscan.io) — search your wallet address and look for the TX that created the native asset.

Answer:

1. What state is the TX in? (Should be `updated`.)
2. Gap between `created_at` and `confirmed_at`? (Time in Cardano's mempool — typically 20–60s on preprod.)
3. Gap between `confirmed_at` and `updated_at`? (The M400.2 sync window — near zero for `access_token_mint` since it's `updates_db: false`.)

## Rubric

1. `updated` — any other state means the mint didn't fully succeed.
2. 20–60 seconds typical. Block times on preprod vary.
3. Under 1 second typical for `updates_db: false` types. For `updates_db: true` types (you'll see this in M500 when you create a course), expect a few seconds of sync work.

If your numbers land in those ranges, you've read a real TX lifecycle end to end.

## What you just did

You know the five individual commands, and you've used `tx status` to inspect real timestamps: registration, on-chain confirmation, and API sync. The gap between the last two is exactly the window M400.2 warned about.
