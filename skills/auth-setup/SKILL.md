---
name: auth-setup
description: Walk through API key creation, wallet JWT authentication, and environment config for the Andamio CLI and the app template. Picks up from whatever the developer already has.
license: MIT
compatibility: Requires the Andamio CLI for wallet authentication. Install via brew install Andamio-Platform/tap/andamio-cli.
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: Auth Setup

## Description

Walks developers through authenticating with the Andamio API. Covers the API key (application identity, read access), a signing wallet and submit endpoint, the wallet JWT (user identity, needed for writes), the Access Token, the app template's `.env`, and CI/CD configuration. Detects existing credentials, including a developer returning after creating content, and skips completed steps.

The only browser step is getting the API key from the developer portal. Everything after that uses a signing key file (`.skey`) and the CLI, with no browser wallet signing.

## Instructions

### Path Resolution

Bundled paths in this skill (`reference/`) are relative to the **package root**: the directory two levels above this `SKILL.md`, after resolving symlinks — the one that contains `specs/andamio-api.yaml`. Resolve them from there, never from the current working directory, which is the developer's own project and does not contain these files. From this file, `reference/andamio-cli-context.md` is `../../reference/andamio-cli-context.md`.

### Secrets

API keys, JWTs, `.skey` contents, `mnemonic.txt` and submit-service project IDs are secrets. Never print them in full, in your own text or in a command you show or run: show the first and last 4 characters only. When a key needs storing, offer the developer the command to run themselves so the key never enters the chat. Say where to run it: in a separate terminal, not in this chat (a `!` command lands in the transcript too). Start the command with a space so the shell keeps it out of its history. Never `cat` the CLI config file or a `.env` file. Use `andamio config show`, which masks the key, and check `.env` values without echoing them (for example `grep -c '^ANDAMIO_API_KEY=.\+' .env`).

### Pre-Execution Check

1. Read `reference/andamio-cli-context.md` for the complete auth command reference.
2. Check what the developer already has:

```bash
# CLI installed?
andamio --version 2>/dev/null

# CLI state (these mask secrets)
andamio config show                 # base URL (= network), API key set or not, submit URL
andamio auth status 2>/dev/null
andamio user status 2>/dev/null     # JWT expiry (its "User:" can be the --alias flag, not proof of a token)
andamio user me --output json 2>/dev/null | jq -r '.data.user.alias // "none"'   # alias the API attaches

# JWT injected from the environment? (the CLI reads ANDAMIO_JWT; it does not read ANDAMIO_API_KEY)
[ -n "$ANDAMIO_JWT" ] && echo "ANDAMIO_JWT: set" || echo "ANDAMIO_JWT: not set"

# Local signing wallet from `andamio wallet create`?
ls ~/.andamio/wallet/ 2>/dev/null

# In an app template project? (.env holds the template's own auth config)
ls .env .env.example 2>/dev/null
grep -E '^(NEXT_PUBLIC_ANDAMIO_GATEWAY_URL|NEXT_PUBLIC_CARDANO_NETWORK)=' .env 2>/dev/null
grep -c '^ANDAMIO_API_KEY=.\+' .env 2>/dev/null    # 1 = set; never print the value
```

3. Work out where the developer is, then go to the matching step:

| What you find | Go to |
|---|---|
| Nothing set up | Step 1 |
| API key works, no signing wallet or no submit URL | Step 3b |
| Wallet and submit URL set, JWT missing or expired | Step 3b.4 only. An expired JWT just needs the headless `user login` again |
| JWT works but `user me` shows no alias | Step 3b.5 (mint the Access Token), then log in again |
| API key and JWT (with alias) both work | Report status (Step 4). Offer Step 3d if they're in a template project and its `.env` isn't filled in |
| CLI base URL and template `.env` point at different networks | Flag it before anything else (Step 1) |
| A template `.env` with `your-api-key-here` or no key | Step 3d. The CLI's key works there too, so there's no need to make a new one |

Don't claim a check passed that you didn't run. `andamio user me` is a read: it proves the JWT is valid, not that writes work.

### Step 1: Environment Selection

**Always default to preprod.** Don't skip this step even if the base URL already looks right: confirm it with the developer.

```
Which environment are you targeting?

1. Preprod (recommended) — Cardano testnet. Test ADA from the faucet. Safe to experiment.
2. Mainnet — Real ADA. Production use only.
```

If the developer selects mainnet, warn:

> Mainnet operations cost real ADA. Make sure you've tested your integration on preprod first. Proceed?

Configure the environment:

```bash
# Preprod (default)
andamio config set-url https://preprod.api.andamio.io

# Mainnet
andamio config set-url https://mainnet.api.andamio.io
```

Everything else must match the network chosen here: the API key, the signing wallet's address (`addr_test1…` on preprod), the submit endpoint, the Access Token, and, in a template project, `NEXT_PUBLIC_ANDAMIO_GATEWAY_URL`, `NEXT_PUBLIC_CARDANO_NETWORK` and `NEXT_PUBLIC_ACCESS_TOKEN_POLICY_ID` in `.env`. If anything points at the other network, say so plainly and fix it before going on.

### Step 2: Access Level Decision

```
What level of access do you need?

1. Read-only — Browse courses, projects, and public data. (API key only)
2. Read + Write — Create courses and projects, build and submit transactions. (API key + signing wallet + submit endpoint + wallet JWT + Access Token)
3. CI/CD pipeline — Automated access for scripts and workflows. (The same as Read + Write, with the login run in the pipeline)
```

### Before Step 3: What to Explain

Explain these in plain words before asking the developer to do anything on-chain. Don't assume Cardano knowledge.

**The Access Token.** An Andamio Access Token (the "222-token") is a small on-chain token in your wallet that carries your Andamio alias. It's your identity on Andamio: you mint it once per network, and a preprod token doesn't count on mainnet. Costs are in /cost-estimator.

**Two wallets, two jobs.**
- A **browser wallet** (Eternl, Lace or another CIP-30 wallet) on **mainnet** is needed once, to get an API key from the developer portal (Step 3a). That's how the portal works today, and it may change. Nothing after that uses it.
- A **signing key file** (`.skey`) is what the CLI uses for everything else: logging in, minting the preprod Access Token, and signing every on-chain step. `andamio wallet create` makes one offline (Step 3b).

**A submit endpoint.** The Andamio API builds transactions but doesn't send them to the chain. The CLI signs with the `.skey` and sends the transaction itself, through a Cardano submit service you configure, such as a free Blockfrost project.

### Step 3a: API Key Setup (All Paths)

Every developer needs an API key. It identifies the application, not the person: one key works with any wallet's login, and the same key works for the CLI and the app template.

**Say this up front:** as it works today, API keys for every network, preprod included, come from the developer portal on the **mainnet** app, using a browser wallet. Registering there needs a **mainnet** Access Token, which costs real ADA (see /cost-estimator). The keys themselves are free. This is the only step that uses a browser wallet or mainnet. A developer with only a preprod token can't register yet, so tell them before they start, not after. Andamio may change this, so describe it as the current process, not a permanent rule.

1. **Mint a mainnet Access Token** (skip if they have one): go to `https://app.andamio.io`, connect the wallet (switched to mainnet), and follow Create Access Token. If the app doesn't recognise the new token straight away, disconnect and reconnect the wallet.

2. **Register a developer account:**
   - Go to `https://app.andamio.io/api-setup` (Dev Tools → API Setup in the sidebar, once you hold a token). Not `preprod.app.andamio.io/api-setup`: that redirects to the dashboard by design
   - Connect the wallet that holds the mainnet Access Token
   - Register with your email, then verify it (check spam)

3. **Generate an API key:**
   - Pick the network with the portal's network selector (preprod for development)
   - Generate a key. Preprod keys start with `ant_pp_`, mainnet keys with `ant_mn_`

   On the free (Pioneer) tier you get one API key: 15,000 requests a month, 500 a day. Choose preprod for development. A second key, for example for mainnet, is refused with `tier_limit_exceeded` (CLI exit 7) until you delete the first one in the portal or upgrade. Keep the key somewhere safe: losing it means deleting it in the portal and generating a new one.

4. **Store the key in the CLI.** Offer this for the developer to run themselves:

```bash
andamio auth login --api-key <your-key>
andamio auth status  # Verify it works
```

5. **Test read-only access:**

```bash
andamio course list --output json | jq length
```

If a key is rejected (401), don't decide from its format that it belongs to another service. Check that the key's network matches the base URL (`andamio config show`), then that it hasn't been revoked in the portal, then ask for a new key.

The CLI is for course Owners and Teachers and project Managers, whether a person or an agent is running it. An Issuer (enterprise) key gets 403 on the transaction build routes: that's expected, not a broken key, and Issuer work isn't covered by the CLI.

If the developer selected read-only access, go to Step 3d (template project) or Step 4.

### Step 3b: Signing Wallet, Login and Access Token (Read + Write)

All of this runs in the CLI with a `.skey`. No browser wallet signing.

1. **Signing wallet.** If the developer already has a `.skey` for this network, use it (with its bech32 address). Otherwise create one:

```bash
andamio wallet create          # writes ~/.andamio/wallet/default/ for the configured network
cat ~/.andamio/wallet/default/address.txt
```

The address is public and fine to show. The wallet folder also holds `payment.skey` and `mnemonic.txt`: tell the developer to back up the mnemonic somewhere safe, and never read either file aloud. `tx sign` and `tx run` use this wallet when `--skey` is omitted.

2. **Fund it.** On preprod, send test ADA to the address from the faucet: `https://docs.cardano.org/cardano-testnets/tools/faucet`. The page has several dropdowns: set **Environment** to **Preprod**. Wait for it to arrive before minting. The CLI has no balance command: the developer can check the address on `https://preprod.cardanoscan.io/address/<address>`, or go on and let the mint tell you (it fails without funds). Setting up the submit endpoint (next) while the faucet ADA arrives saves time.

3. **Submit endpoint.** The Andamio API never submits transactions for you, by design: the CLI signs with the `.skey` and sends the transaction to a Cardano submit service you configure. Blockfrost is the default. It's a signup in the browser that an agent can't do for the developer, so walk them through it:
   - Sign up at `https://blockfrost.io` (the free plan is enough)
   - Add a project and choose **Cardano preprod** as its network. A free account has one project, so preprod is the right one for development
   - Copy the project ID

   Then:

```bash
andamio config set-submit-url https://cardano-preprod.blockfrost.io/api/v0/tx/submit
andamio config set-submit-header project_id <blockfrost-project-id>
```

Use the full URL, ending in `/api/v0/tx/submit`. Blockfrost redirects a wrong path (the base URL, or one missing `/v0`) to its homepage, and CLI versions up to 1.3.0 take that as a successful submit: the transaction never reaches the chain and `tx run` waits until it times out (andamio-cli#218 makes this an error). Have the developer run the header command themselves, since the project ID is a secret. Any Cardano submit API that takes raw CBOR works too.

4. **Log in with the signing key:**

```bash
andamio user login --skey ~/.andamio/wallet/default/payment.skey \
  --alias <alias> --address $(cat ~/.andamio/wallet/default/address.txt)
```

The login itself doesn't need an Access Token: any wallet that signs gets a session. The alias is only attached if the wallet holds that alias's Access Token on this network; otherwise the API drops it without an error. So for a new wallet, pass the alias the developer wants. Don't go by the CLI's own output here: `user login` prints "Authenticated as: <alias>" and `user status` shows "User: <alias>" even when the API dropped it, because the CLI falls back to the `--alias` flag. Ask the API instead:

```bash
andamio user me --output json | jq -r '.data.user.alias // "none"'
```

"none" for a new wallet is expected. Don't print the whole `user me` response: it can run to over 100 KB.

5. **Mint the Access Token** (skip if `user me` already shows the alias). Check the alias is free, then mint it onto the wallet:

```bash
andamio user exists <alias>
andamio tx run /v2/tx/global/user/access-token/mint \
  --body '{"alias":"<alias>","initiator_data":"<bech32 address>"}' \
  --tx-type access_token_mint \
  --skey ~/.andamio/wallet/default/payment.skey
```

`initiator_data` is the wallet's address as a plain string, not an object. Report the mint only when `tx run` reports it confirmed.

6. **Log in again** with the same command as step 4. Now `user me` should show the alias.

7. **Check the session:**

```bash
andamio user status                                   # JWT valid, expiry
andamio user me --output json | jq -c '.data.user'    # alias attached by the API
```

This confirms the JWT is valid and carries the alias. `user me` is a read, so don't report write access as verified from it; the confirmed mint in step 5 is the proof that signing and submitting work.

**Note:** The JWT expires after about 24 hours. An expired JWT counts as logged out, so re-running the step 4 login is all that's needed. Returning developers usually only need this step.

### Step 3c: CI/CD Setup

For automated pipelines:

1. Complete steps 3a and 3b once, outside the pipeline, so the wallet holds its Access Token.
2. Store the API key, the `.skey`, the address and the submit project ID in the CI secret store. In the pipeline:

```bash
andamio config set-url https://preprod.api.andamio.io
andamio auth login --api-key "$ANDAMIO_API_KEY"
andamio config set-submit-url https://cardano-preprod.blockfrost.io/api/v0/tx/submit
andamio config set-submit-header project_id "$BLOCKFROST_PROJECT_ID"
andamio user login --skey "$SKEY_PATH" --alias "$ANDAMIO_ALIAS" --address "$WALLET_ADDRESS"
```

The CLI doesn't read an `ANDAMIO_API_KEY` variable on its own, which is why the key goes through `auth login`. Logging in each run avoids the 24-hour JWT expiry. The CLI also reads `ANDAMIO_JWT` and `ANDAMIO_SUBMIT_URL` from the environment if you'd rather inject those.

### Step 3d: App Template `.env` (template projects)

If the developer is in an `andamio-app-template` project (a `.env.example` mentioning `ANDAMIO_API_KEY`), check its auth settings. Copy `.env.example` to `.env` if there's no `.env` yet.

| Variable | Should be |
|---|---|
| `ANDAMIO_API_KEY` | An API key for the same network. The CLI's key from Step 3a works. Server-side only: never put it in a `NEXT_PUBLIC_` variable |
| `NEXT_PUBLIC_ANDAMIO_GATEWAY_URL` | The same base URL as the CLI (`andamio config show`) |
| `NEXT_PUBLIC_CARDANO_NETWORK` | `preprod` or `mainnet`, matching the above |
| `NEXT_PUBLIC_ACCESS_TOKEN_POLICY_ID` | The Access Token policy ID for that network (listed in `.env.example`) |
| `NEXT_PUBLIC_BLOCKFROST_PROJECT_ID` | Only needed for social-wallet logins (Google, Discord, X), not for browser wallets |

Have the developer paste the key into `.env` themselves, and check it's set with `grep -c`, never by printing it. People using the template log in with their own browser wallets in the running app, so the CLI's JWT isn't used there.

### Step 4: Verification Summary

After setup, summarise what was actually checked:

```
Auth Setup Complete

Environment:   preprod
API Key:       ant_pp_…a1b2 (course list returned 200)
Signing key:   ~/.andamio/wallet/default/ (addr_test1…)
Submit URL:    Blockfrost preprod, /tx/submit
Access Token:  <alias> (mint confirmed)
Wallet JWT:    valid for alias <alias>, expires in ~24h
Template .env: API key set, network matches
Config:        ~/.andamio/config.json
```

Then suggest next steps, with a line on what each is for:

- If they already have a course or project, point back to it: /course-ops or /project-ops carries on with it.
- **/explore-api** — look around courses, projects and the API, read-only.
- **/cli-guide** — a reference of CLI commands, for checking what's available.
- **/course-ops** — create and manage a course.
- **/project-ops** — create and manage a project.

What would you like to do next?

### Handling Async Steps

If the developer says "I already registered but haven't verified my email":
- Tell them to check their inbox (including spam) for the verification email
- They can resend: the API setup page has a resend option
- Once verified, continue from step 3a.3 (generate API key)

If the developer says "I don't have an Access Token":
- Explain what it is (see "Before Step 3"). Costs are in /cost-estimator
- For the API key: today a **mainnet** token is needed, minted at `https://app.andamio.io` with real ADA. A preprod token can't register a developer account
- For preprod work: the CLI mints one onto the signing wallet in Step 3b.5, paid with faucet ADA

If the developer is waiting on faucet ADA: the mint fails without funds, so pause at Step 3b.2 and check the address has a balance on `https://preprod.cardanoscan.io/address/<address>` before going on.

### Guidelines

- Always start on preprod unless the developer explicitly requests mainnet
- Never print secrets in full (see "Secrets"); show the first and last 4 characters only
- Only report what you checked: never say a login worked, a mint landed or write access is verified without seeing it
- Don't route the developer through browser wallet signing after Step 3a; use the `.skey`
- If the CLI isn't installed, provide install instructions: `brew install Andamio-Platform/tap/andamio-cli`
- Skip steps the developer has already completed (detected in the pre-execution check)
