# Module 200 Assignment: Identity

Two parts: evidence and feedback.

## Part 1: Evidence

### SLT 200.1 — Mint your access token

Mint an access token on preprod (M200.1). Provide:

1. Your alias.
2. The mint transaction hash.
3. A [preprod.cardanoscan.io](https://preprod.cardanoscan.io) link showing the access token in your wallet.

### SLT 200.2 — API keys vs User JWTs

Confirm both auth credentials are active:

```bash
andamio config get api-key
andamio user status
```

Paste both outputs.

### SLT 200.3 — Headless login

Log in headlessly using your `.skey`:

```bash
andamio user login \
  --skey ./payment.skey \
  --alias YOUR_ALIAS \
  --address $(cat payment.addr) \
  --output json
```

Paste the output. If you already have a valid JWT, the `user status` output from 200.2 covers this.

### SLT 200.4 — Attestation JWTs

Fetch the JWKS public key from the Andamio API:

```bash
curl -s https://preprod.api.andamio.io/.well-known/jwks.json | python3 -m json.tool
```

Paste the output. This is the key any third party uses to verify an Attestation JWT offline.

## Part 2: Feedback

Not optional. Feedback is how this course improves.

1. **What was the clearest? What was the muddiest?**
2. **One change you'd make to Module 200?**

Detailed feedback → open an issue at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev) and paste the link.

## How to submit

**Andamio App:** `app.andamio.io/courses/{COURSE_ID}/modules/200/assignment`

**CLI:** Submission mechanics covered in M500.5.

## What happens next

Accepted → Module 300 unlocks, `/auth-setup` Ops skill available. Two down, five to go.
