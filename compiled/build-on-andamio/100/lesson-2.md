# Install and configure the Andamio CLI

## Before we start

The Andamio CLI is a single binary called `andamio`. It reads data from the Andamio API, builds and signs Cardano transactions, and tracks the transactions it submits. Every lesson after this one assumes you have it installed and configured with an API key.

## Install

```bash
brew install Andamio-Platform/tap/andamio
```

Works on macOS and Linux (via Linuxbrew). For other environments, see the [andamio-cli repository](https://github.com/Andamio-Platform/andamio-cli).

## Verify the install

```bash
andamio --version
```

Any version string (e.g. `andamio v0.10.2`) means the install succeeded.

If you get `command not found`, Homebrew's bin directory isn't on your `$PATH`:

- **macOS, Apple Silicon:** `eval "$(/opt/homebrew/bin/brew shellenv)"` — then add to `~/.zshrc`
- **macOS, Intel:** same, with `/usr/local/bin/brew`
- **Linuxbrew:** `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` — then add to `~/.bashrc`

## Get your API key

The CLI needs an API key to talk to the Andamio API. Every request — reads and writes — requires one.

1. Register at the [Andamio developer portal](https://app.andamio.io/developers) (or the preprod equivalent your instructor provides).
2. Generate an API key. Copy it — you'll only see it once.
3. Configure the CLI:

```bash
andamio config set api-key <your-api-key>
```

Verify it's stored:

```bash
andamio config get api-key
```

The key is saved in `~/.andamio/config.yaml`. The CLI attaches it as an `X-API-Key` header on every request automatically. M200.2 explains what the API key represents and when you'll also need a User JWT.

## What the CLI actually wraps

Every subcommand is a thin wrapper around an HTTP call to the Andamio API. The CLI adds three things:

| Layer | What it does |
|-------|-------------|
| **Authentication** | Attaches your API key and JWT headers automatically |
| **Formatting** | Returns human-readable text or structured JSON |
| **Orchestration** | `tx run` wraps the five TX state-machine steps in one invocation |

Underneath, it's API calls. By M300 you'll know which endpoint each command hits. By M700 you'll know when to skip the CLI and call the API directly.

## Try your first command

Before moving on, try something that previews where the course is going. These are Module 100's four SLTs — the learning targets you'll complete by the end of this module:

```bash
andamio course credential compute-hash \
  --slt "I can explain Andamio's contribution-centered learning model." \
  --slt "I can install and configure the Andamio CLI." \
  --slt "I can fund a preprod wallet from the Cardano testnet faucet." \
  --slt "I can distinguish Learning Mode from Ops Mode in this plugin."
```

You get back a 64-character hex string — the on-chain fingerprint of this module. That hash, combined with a course ID, becomes the credential's address on the blockchain. Change one character in any SLT and the hash is completely different.

You don't need to understand the full picture yet. The concept comes back in M300 (where you'll verify a real course's hashes) and M500 (where you'll build a course and mint this hash on-chain). For now: the CLI works, and this hash will come back.

## Your turn

Run the install. Run `andamio --version`. Configure your API key. Run the `compute-hash` command above. You're done when the version prints, `andamio config get api-key` returns your key, and you have a 64-character hex string.

## What you just did

You have the tool, an API key, and you know what the CLI wraps — a Go binary over the Andamio API, not a black box. When a command misbehaves later, the first question is: *what HTTP call is this making?*

If you're on the web and also want agent orchestration, the `andamio-dev` plugin carries the same content. M100.4 explains it.
