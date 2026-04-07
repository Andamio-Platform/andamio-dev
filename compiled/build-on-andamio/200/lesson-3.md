# Log in headlessly with a .skey file

## Before we start

You need a User JWT for write operations. There are two ways to get one:

- **Browser path** — CIP-30 wallet signs a nonce in the browser. How end users authenticate.
- **Headless path** — `.skey` file signs the same nonce from the terminal. How developers and CI pipelines authenticate.

This lesson teaches the headless path. If you don't have a `.skey` file, generate one with `cardano-cli` (M100.3 shows the commands).

## What the login flow does

Three-step conversation with Andamio's auth endpoints:

1. CLI requests a login session → server returns a session ID and random nonce.
2. CLI signs the nonce with your `.skey` using CIP-8 (Cardano's standard for signing arbitrary bytes).
3. CLI sends session ID, signature, wallet address, and alias → Andamio verifies the signature, confirms wallet owns the alias, issues a JWT (~24 hours).

The JWT is stored in `~/.andamio/config.yaml` and attached to every subsequent request automatically.

## Run the command

```bash
andamio user login \
  --skey ./payment.skey \
  --alias my-alias \
  --address $(cat payment.addr)
```

| Flag | Purpose |
|------|---------|
| `--skey` | Your signing key file. Read locally, never leaves your machine. |
| `--alias` | The alias you minted in M200.1. Forgot? Check your mint TX on [preprod.cardanoscan.io](https://preprod.cardanoscan.io). |
| `--address` | Your `addr_test1...` bech32 address. |

Expected output:

```
Requesting login session...
Signing nonce with ./payment.skey...
Validating signature...

Authenticated as: my-alias
User ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Key hash: d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3
```

## Verify

```bash
andamio user me --output json
```

Requires a JWT, so it only works after login. A JSON object with your alias, user ID, and key hash means you're in.

## JWT lifetime

~24 hours. When it expires, writes fail and you re-run `andamio user login`. Check expiration with:

```bash
andamio user status
```

## Scripts and CI

```bash
andamio user login \
  --skey "$CARDANO_SKEY_PATH" \
  --alias "$ANDAMIO_ALIAS" \
  --address "$CARDANO_ADDRESS" \
  2>/dev/null

andamio tx run ...   # writes work for ~24 hours
```

`2>/dev/null` suppresses progress messages in CI logs. For long-running jobs, check `andamio user status` periodically and re-login before expiry.

## Browser path (brief note)

For web apps, the flow is structurally the same (session → nonce → signature → JWT), but signing uses CIP-30 in the browser wallet instead of a local `.skey`. See the Andamio app template repo for a working example using Mesh SDK and React hooks.

For the rest of this course, we use the headless path. Every write from M300 onward assumes a valid JWT.

## Your turn

Run `andamio user login`, then confirm with `andamio user me --output json`. Done when it returns your alias.

## What you just did

You have a JWT. Every write operation from here forward uses it transparently. You also saw the login mechanics — session, nonce, signature, JWT — which you'll recognize again in M200.4's attestation flow.
