# Integration Paths

> Three supported ways to build on the Andamio Protocol. Pick the path that fits your project shape.

**Last updated**: 2026-05-14

| Path | Best for | Tech | Auth model |
|------|----------|------|------------|
| **1. CLI only** | Scripts, agents, ops workflows, headless integrations | `andamio-cli` (Go binary) | API key + browser wallet, or animal-wallet for headless |
| **2. App template** | New dApps, full-stack web products | `andamio-app-template` (Next.js 15) | API key (server) + browser wallet (client) |
| **3. Custom app** | Existing app, exotic stack, mobile, server-only | Your stack + Andamio HTTP API | API key (server) + browser wallet (client) |

All three talk to the same public API at `https://preprod.api.andamio.io` (preprod) or `https://mainnet.api.andamio.io` (mainnet).

---

## 1. CLI only

The fastest path for agents and scripted workflows. No frontend, no React, no Node.

```bash
brew install andamio-platform/tap/andamio
andamio auth login --api-key <key>
andamio user status
```

**When to use**:
- You're an AI agent or running scripted ops.
- You want to run transaction loops end-to-end from a terminal.
- You don't need a UI — outcomes matter, not pixels.

**Reference**: [andamio-cli-context.md](./andamio-cli-context.md) — full command surface, env vars, auth modes.

**Skills that target this path**: `/cli-guide`, `/cost-estimator`, most `/tx-loop-*` skills.

---

## 2. App template

The `andamio-app-template` repo is a Next.js 15 + TypeScript starter wired to the Andamio API. Fork it, theme it, ship it.

```bash
git clone https://github.com/Andamio-Platform/andamio-app-template.git
cd andamio-app-template
npm install
cp .env.example .env  # set NEXT_PUBLIC_ANDAMIO_GATEWAY_URL and ANDAMIO_API_KEY
npm run dev
```

**What you get**:
- Web3 login (browser wallet via CIP-30).
- Server-side API key holding (Next.js route handlers proxy to Andamio API).
- Sponsored transaction support (server signs fees; user signs intent).
- Pre-built course/project/credential flows you can keep, modify, or strip out.
- Agent Skills bundled — open the repo in Claude Code / Cursor / Copilot and run `/getting-started`.

**When to use**:
- You're building a course-delivery app, project-coordination app, or credential-issuing app.
- You want sponsored TX out of the box (paying for users' transactions).
- You want a baseline UI you can customize rather than building from scratch.

**Generate types from the API spec**: `npm run generate:types`.

---

## 3. Custom app

You already have an app, or you're on a stack `andamio-app-template` doesn't cover (Rails, Django, Phoenix, Flutter, mobile native, server-only).

Use the public API directly.

```bash
# Bearer auth: get an API key from https://app.andamio.io/api-setup
curl -H "Authorization: Bearer $ANDAMIO_API_KEY" \
  https://preprod.api.andamio.io/v2/user/me
```

**What you need to build yourself**:
- API key storage (server-side only — never ship to the browser).
- Wallet signing flow (CIP-30 for web, mobile-specific SDK for native).
- TX submission to Cardano (Blockfrost, Maestro, or your own submit endpoint).
- TX state polling (or websocket to `/v2/tx/events/{tx_hash}`).

**When to use**:
- You have an existing app that needs Andamio credentialing.
- You're building outside the Next.js ecosystem.
- You need a custom auth or UX model that the template doesn't support.

**Reference**: [api-endpoints-by-use-case.md](./api-endpoints-by-use-case.md) for a use-case map; `specs/andamio-api.yaml` for the full OpenAPI spec.

---

## Choosing between paths

```
Need a UI?
 ├── No  → Path 1 (CLI)
 └── Yes
      ├── Greenfield Next.js project? → Path 2 (app template)
      └── Existing app or other stack? → Path 3 (custom)
```

You can mix paths. Common pattern: use the CLI for setup and ops (create courses, mint credentials) while end users interact through a custom or templated app.

---

## What's shared across all paths

All paths converge on the same underlying contracts:

- [Status enums](./status-enums.md) — the same vocabulary across CLI, app, and API responses.
- [TX loops](./tx-loops.yaml) — the same canonical workflows (course setup, credential claim, project tasks).
- [Acceptance test prerequisites](./acceptance-test-prerequisites.md) — the same preflight before any TX work on preprod.
