# Windows, WSL, and Codex Setup

Use this guide to set up `andamio-dev` on Windows with WSL and OpenAI Codex. The goal is to make the operational Andamio skills available to Codex, verify the Andamio CLI on preprod, and leave the deeper course-agent refactor for later.

## 1. Install WSL And Clone The Repo

Install Ubuntu in WSL from PowerShell:

```powershell
wsl --install -d Ubuntu
```

Open Ubuntu, then install basic tools:

```bash
sudo apt update
sudo apt install -y git curl build-essential
```

Clone the repo inside the Linux filesystem, not under `/mnt/c`, so symlinks and file watching behave normally:

```bash
mkdir -p ~/andamio
cd ~/andamio
git clone https://github.com/Andamio-Platform/andamio-dev.git
cd andamio-dev
```

## 2. Install And Verify Codex

Install Codex using the current OpenAI Codex instructions for Linux, then verify it inside WSL:

```bash
codex --version
```

Start Codex from the repo root:

```bash
cd ~/andamio/andamio-dev
codex
```

## 3. Ask Codex To Configure This Repo

The repo already stores reusable operational skills in `skills/`. Codex discovers project skills from `.agents/skills/`, so ask Codex to create symlinks instead of copying files.

Paste this prompt into Codex:

```text
Configure this repository for Codex use on WSL.

Create `.agents/skills/` if it does not exist. For every directory under `skills/` that contains a `SKILL.md`, create a relative symlink at `.agents/skills/<skill-name>` pointing back to `../../skills/<skill-name>`.

Do not copy skill files. Do not move or rewrite the `skills/` directory. Do not modify `.claude/`.

For now, do not migrate or symlink `.claude/skills/learn`, `.claude/skills/deliver-lesson`, `.claude/skills/assess-assignment`, `.claude/agents/instructor.md`, or `.claude/agents/assessor.md`. Those are still Claude-specific and will be refactored later.

After creating symlinks, verify with:
find .agents/skills -maxdepth 2 -name SKILL.md -print
```

Expected result:

```text
.agents/skills/auth-setup/SKILL.md
.agents/skills/cli-guide/SKILL.md
.agents/skills/compound/SKILL.md
.agents/skills/cost-estimator/SKILL.md
.agents/skills/course-ops/SKILL.md
.agents/skills/explore-api/SKILL.md
.agents/skills/orientation/SKILL.md
.agents/skills/project-ops/SKILL.md
.agents/skills/start/SKILL.md
.agents/skills/troubleshoot/SKILL.md
```

If Codex asks whether symlinks are allowed, say yes. On WSL they should work normally when the repo is stored under your Linux home directory.

## 4. Install The Andamio CLI

Install the CLI inside WSL and verify it:

```bash
brew install andamio-platform/tap/andamio
andamio --version
```

If Homebrew is not installed in WSL yet, install Homebrew for Linux first, then open a new shell and rerun the CLI install.

Set the CLI to preprod:

```bash
andamio config set-url https://preprod.api.andamio.io
andamio config show
```

Always start on preprod. Mainnet uses real ADA.

## 5. Configure Andamio Auth

Andamio uses two credentials:

| Credential | Command | Needed For |
| --- | --- | --- |
| API key | `andamio auth login --api-key <key>` | Read-only API access |
| Wallet JWT | `andamio user login` | Write operations and user-specific reads |

Create an API key at:

```text
https://preprod.app.andamio.io/api-setup
```

Then store it:

```bash
andamio auth login --api-key <your-ant-key>
andamio auth status
```

For write operations, log in with your wallet:

```bash
andamio user login
andamio user status
```

You need a Cardano preprod wallet with an Andamio Access Token before wallet login is useful. Use the Cardano preprod faucet for test ADA.

## 6. Verify Read Access

These commands should work with an API key and no wallet JWT:

```bash
andamio course list --output json
andamio project list --output json
andamio token list --output json
andamio tx types --output json
```

Without any credentials, the useful query surface is limited:

```bash
andamio user exists <alias>
```

## 7. Use Codex With The Andamio Skills

Once `.agents/skills/` exists, restart Codex from the repo root. Then use natural prompts or name a skill directly:

```text
$start
```

```text
Use the course-ops skill. I want to create a new course on preprod.
```

```text
Use the explore-api skill. What course queries can I make with only an API key?
```

Course creation requires API key, wallet JWT, preprod ADA, your Andamio alias, and initial teacher aliases. Ask Codex for `/course-ops` and provide:

```text
course title:
owner alias:
initial teacher aliases:
environment: preprod
```

## 8. Known Codex Gap

The operational skills in `skills/` are ready for Codex. The full `/learn` course harness still has Claude-specific pieces in `.claude/`, especially the instructor and assessor agent definitions. Leave those alone for now; the later refactor should move the learning orchestrator into a Codex-native `.agents/` structure without changing the course content in `courses/`.
