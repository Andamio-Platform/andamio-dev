# Mint your access token

## Before we start

Every write operation on Andamio is tied to an actor. Until you mint an access token, the protocol doesn't know who you are. This lesson fixes that in about ninety seconds of on-chain work.

## Why it exists

Every Andamio write is a Cardano transaction tied to an actor. "Who" has to be something verifiable — not a display name or email.

Cardano already signs every transaction with a key, but key hashes are 28-byte hex strings: unreadable and brittle across key rotations. Andamio wraps something simpler on top: a human-readable alias, tied cryptographically to your wallet and stored as an on-chain asset.

That asset is the access token. Minting one costs 5 ADA and creates three things:

| What | Why |
|------|-----|
| Your alias as a globally unique string | Every future write references it |
| An NFT in your wallet | Cryptographic proof you own the alias |
| A protocol-level identity record | Foundation for credentials, commitments, submissions |

The 5 ADA isn't a service fee — most of it pays for block space and the minUTxO deposit. Your alias is yours in the same sense your ADA is yours: nobody can suspend or revoke it.

## Choose your alias

1–31 characters. Lowercase letters, numbers, hyphens, underscores. Every credential and submission will reference this string. Examples: `alice-dev`, `contrib42`, `buildonandamio`.

Must be globally unique on the network. Duplicate → error at build time; pick another.

## What you need

- **Your alias** (chosen above)
- **Your bech32 address** — `cat payment.addr` or paste from your wallet
- **Your signing key file** — the `.skey` on disk (read locally, never leaves your machine)

```bash
export MY_ALIAS=alice-dev
export MY_ADDRESS=$(cat payment.addr)
export MY_SKEY=./payment.skey
```

## Build the request body

```bash
cat > mint-request.json <<EOF
{
  "alias": "$MY_ALIAS",
  "initiator_data": {
    "change_address": "$MY_ADDRESS",
    "used_addresses": ["$MY_ADDRESS"]
  }
}
EOF
```

`initiator_data` is an exception to Andamio's normal request shape. Every other write endpoint looks up your addresses from your alias. The mint is different — no alias exists yet, so you provide wallet addresses explicitly.

## Run the mint

```bash
andamio tx run /v2/tx/global/user/access-token/mint \
  --body-file mint-request.json \
  --skey "$MY_SKEY" \
  --tx-type access_token_mint
```

| Flag | Purpose |
|------|---------|
| `tx run` | CLI wrapper for the full TX state machine |
| `/v2/tx/global/user/access-token/mint` | API endpoint that builds the mint |
| `--body-file` | The JSON you just wrote |
| `--skey` | Your signing key, read locally |
| `--tx-type access_token_mint` | Tells the API how to track this TX |

Expected output:

```
Building transaction: POST /v2/tx/global/user/access-token/mint
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

`State: updated` = mint succeeded, alias is on-chain.

## What just happened

The five lines map to five steps of Andamio's transaction state machine (covered in depth in M400):

1. **Build.** CLI sent your body to the API → API selected UTxOs → returned unsigned CBOR.
2. **Sign.** CLI signed the CBOR locally with your `.skey`.
3. **Submit.** Signed CBOR broadcast to Cardano → transaction hash returned.
4. **Register.** CLI told the API to track this TX by hash.
5. **Wait.** CLI polled until status reached `updated` — on-chain confirmed and synced.

`updated` is the only status that means "really done." M400 explains why.

## Verify

Paste your address into [preprod.cardanoscan.io](https://preprod.cardanoscan.io) and check the assets. You should see an Andamio access token named after your alias.

`andamio user me` also confirms your alias once you have a User JWT (M200.3).

## If something went wrong

- **Insufficient funds at build.** Not enough ADA for the 5 ADA fee + TX costs. Hit the faucet again (M100.3).
- **Alias already exists.** Pick a different alias and retry.
- **Stuck in `pending`.** Preprod sometimes has slow blocks. Run `andamio tx status <tx_hash>`.
- **State reaches `failed`.** Rare on mint. Check `failure_reason` in the status response.

Anything else: open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) with the command, error, and tx_hash.

## Your turn

Run the mint. Verify your alias on [preprod.cardanoscan.io](https://preprod.cardanoscan.io). Done when the explorer shows an Andamio access token in your wallet.

## What you just did

Your alias is on-chain and your wallet holds the token. Every future write on the protocol references this identity. You also saw the five-step TX state machine run end to end — M400 breaks it apart.

The access token isn't course-specific. It's the same identity for any Andamio course, project, or integration.
