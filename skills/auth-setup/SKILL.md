---
name: auth-setup
description: Walk through API key creation, wallet JWT authentication, and environment config for the Andamio API.
license: MIT
compatibility: Requires the Andamio CLI for wallet authentication. Install via brew install andamio-platform/tap/andamio.
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Auth Setup

## Description

Walks developers through authenticating with the Andamio API. Covers API key (read-only), wallet JWT (read+write), and CI/CD configuration. Detects existing credentials and skips completed steps.

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read reference from `${CLAUDE_PLUGIN_ROOT}/reference/`.
- **Clone/symlink context** (default): Read reference at `reference/` relative to project root.

### Pre-Execution Check

1. Read `reference/andamio-cli-context.md` for the complete auth command reference.
2. Check for existing credentials:

```bash
# Check if CLI is installed
andamio --version 2>/dev/null

# Check existing auth state
andamio auth status 2>/dev/null
andamio user status 2>/dev/null

# Check environment variables
echo "ANDAMIO_API_KEY: ${ANDAMIO_API_KEY:-(not set)}"
echo "ANDAMIO_JWT: ${ANDAMIO_JWT:-(not set)}"

# Check config file
cat ~/.andamio/config.json 2>/dev/null | python3 -m json.tool 2>/dev/null
```

3. If credentials already exist and work, report status and ask if the developer wants to reconfigure or proceed to their next task.

### Step 1: Environment Selection

**Always default to preprod.**

```
Which environment are you targeting?

1. Preprod (recommended) — Cardano testnet. Free test ADA. Safe to experiment.
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

### Step 2: Access Level Decision

```
What level of access do you need?

1. Read-only — Browse courses, projects, and public data. (API key only)
2. Read + Write — Create courses, submit assignments, build transactions. (API key + wallet JWT)
3. CI/CD pipeline — Automated access for scripts and workflows. (API key + ANDAMIO_JWT env var)
```

### Step 3a: API Key Setup (All Paths)

Every developer needs an API key. Walk through:

1. **Register a developer account:**
   - Go to `https://preprod.app.andamio.io/api-setup` (or `https://app.andamio.io/api-setup` for mainnet)
   - Connect your wallet (you need an Andamio Access Token — mint one if you don't have it)
   - Register with your email
   - Verify your email (check inbox for verification link)

2. **Generate an API key:**
   - After email verification, log in at the API setup page
   - Generate a new API key
   - Copy the key (starts with `ant-`)

3. **Store the key in the CLI:**

```bash
andamio auth login --api-key <your-key>
andamio auth status  # Verify it works
```

4. **Test read-only access:**

```bash
andamio course list --output json
```

If the developer selected read-only access, auth setup is complete.

### Step 3b: Wallet JWT Setup (Read + Write)

For write operations, the developer also needs a wallet JWT:

1. **Prerequisites:**
   - A Cardano wallet with an Andamio Access Token (222-token)
   - The Andamio CLI installed

2. **Authenticate:**

```bash
andamio user login
# Opens browser for CIP-30 wallet signing
# Signs a challenge nonce to prove wallet ownership
# JWT stored at ~/.andamio/config.json
```

3. **Verify:**

```bash
andamio user status
# Shows: alias, JWT expiry time, access token status
```

4. **Test write access:**

```bash
andamio user me --output json
```

**Note:** JWT expires after ~24 hours. Re-authenticate with `andamio user login` when it expires.

### Step 3c: CI/CD Setup

For automated pipelines:

1. Complete steps 3a (API key) and 3b (get a JWT).
2. Set environment variables:

```bash
export ANDAMIO_API_KEY="ant-your-key-here"
export ANDAMIO_JWT="your-jwt-token-here"
```

The CLI reads `ANDAMIO_JWT` from the environment, overriding the stored config. This is useful for CI/CD where browser wallet signing isn't available.

**For headless signing** (no browser):

```bash
andamio user login --skey /path/to/payment.skey
```

### Step 4: Verification Summary

After setup, present a summary:

```
Auth Setup Complete

Environment:  preprod
API Key:      configured (read-only access)
Wallet JWT:   configured (read+write, expires in ~24h)
Config:       ~/.andamio/config.json

You're ready to:
- Browse courses and projects (/explore-api)
- Use the CLI for operations (/cli-guide)
- Create courses (/course-ops) or projects (/project-ops)

What would you like to do next?
```

### Handling Async Steps

If the developer says "I already registered but haven't verified my email":
- Tell them to check their inbox (including spam) for the verification email
- They can resend: the API setup page has a resend option
- Once verified, continue from step 3a.2 (generate API key)

If the developer says "I don't have an Access Token":
- They need to mint one first. This costs ~7.9 ADA (see /cost-estimator).
- On preprod: get test ADA from the faucet first, then mint via the app at preprod.app.andamio.io
- The Access Token is a prerequisite for API key generation

### Guidelines

- Always start on preprod unless the developer explicitly requests mainnet
- Never store or display full API keys or JWTs in output — show first/last 4 characters only
- If the CLI isn't installed, provide install instructions: `brew install andamio-platform/tap/andamio`
- Skip steps the developer has already completed (detected in pre-execution check)
