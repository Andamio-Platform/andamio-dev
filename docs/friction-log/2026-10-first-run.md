# First-run friction log, October 2026

**What this is:** a timed, step-by-step record of a developer who is new to Cardano trying to get started with Andamio using the public docs and this plugin, with an AI coding agent doing the work. Every point where the path broke, misled or slowed down is logged with what was expected, what actually happened, the time it cost and a severity.

**Why:** Month 4 of the andamio-cli MRP, "Measure the first-run experience". This log is the evidence. It feeds two follow-ups: a quickstart tutorial in andamio-docs and a revision of the `orientation` skill (plus a CLI reference sync to 1.2.0).

**Run by:** Andrew (awattsdev), 20 and 21 October 2026.

## How the run was done

**The box.** A fresh Docker container (`ubuntu:24.04`, Node 20, Claude Code, empty home directory, passwordless sudo). Deliberately not installed: the andamio CLI, Go, any Cardano tools and any Andamio repo. The Dockerfile is in [Appendix A](#appendix-a-dockerfile).

**The persona.** A competent developer who knows a terminal, git and Node, and has used an AI coding agent, but is new to Cardano and Andamio. That is the audience the andamio-dev README speaks to ("New to Cardano? Start with `/orientation`"). Anything Cardano-specific (wallets, preprod, faucet, Access Token) has to be explained by the docs or the agent. If it isn't, that's friction.

**The rule.** Follow only public material: READMEs, andamio-docs and the plugin's skills. Where we had to use knowledge a newcomer wouldn't have, it is logged as **insider help**. A line was drawn at row 16 (the API key blocker); everything after it uses two pieces of insider help, each named in its row.

**Who did what.** Two Claude Code sessions ran side by side:

- **In the container**, Andrew drove a Claude Code agent with the andamio-dev plugin loaded, answering its questions and following its instructions the way a newcomer would. He did the browser-side steps himself (wallet, faucet, Andamio app).
- **On the host**, a second Claude Code session acted as the note-taker. Andrew passed it screenshots as the run went; on day 2 it also read the container agent's session transcript directly (read-only, through `docker exec`), masking API keys and tokens in anything it pulled out. For each step it wrote the row, then checked the claim against the source: this repo's skills and bundled spec, the andamio-cli source, andamio-docs and the live API. Those references are cited inline in the rows.

**Severity.** **blocker**: can't continue without outside help. **major**: cost more than 10 minutes or caused a wrong turn. **minor**: confusing, quickly worked around. **nit**: wording or polish.

**Times** are CEST. Plugin version: andamio-dev 0.2.0 at `6dd825a`. CLI: andamio 1.2.0.

## Results at a glance

| | |
|---|---|
| Active time | about 2 hours over two sessions (20 Oct 15:10 to 16:12, 21 Oct 13:28 to 14:30) |
| Findings | 30: **7 blocker**, 13 major, 7 minor, 3 nit (plus 1 step that simply worked well) |
| Time to first success, public path only | **none**. The run stops at row 15/16, about 62 minutes in |
| Time to first success, with insider help | first authenticated CLI read at about 84 minutes (row 19); auth complete at about 106 minutes (row 22) |
| First write (course created, module minted, enrolment) | **never reached** (row 24) |
| Not covered | andamio-app-template was not reached in this run |

**Headline 1: a newcomer can't get a preprod API key without buying ADA.** The plugin points to `preprod.app.andamio.io/api-setup`, which redirects to the dashboard. The docs point to `app.andamio.io/api-setup`, which needs a **mainnet** Access Token (about 7.9 real ADA). The preprod app has no link to API setup at all. (rows 12 to 16)

**Headline 2: the wallet that gets you through auth can't build anything through the CLI.** Everything up to and including login uses a browser wallet (CIP-30). The CLI's write path needs a `.skey` file and a chain-submit URL such as a Blockfrost project. Nothing on the path mentions either until the first write, and then the only way forward is to leave the CLI for the app. (rows 24 and 25)

### Themes

- **Two kinds of wallet, never introduced.** Auth is browser-wallet; CLI writes are `.skey`. The newcomer finds out at the first write.
- **Agents running in containers or on remote machines aren't considered.** `andamio user login` waits for a callback on `127.0.0.1`, which a browser on another machine can't reach. (rows 20 and 21)
- **Out-of-date docs mislead the agent, not just the reader.** The spec's `ant-` key example led to a confident misdiagnosis (row 18). The brew cask name is wrong in 10 places (P3). The plugin's CLI reference is synced to 1.1.2 and documents only the broken install route (row 9).
- **The install story is Mac-first.** Every doc and skill leads with Homebrew. A Linux or WSL developer is told to install a Mac package manager for one binary, while the release download and `go install` routes in the CLI README are invisible to the plugin.
- **The agent rescues broken docs, which hides them.** It recovered from the wrong cask name by reading the tap's cask file (row 10). Good for the user, but a person without an agent would have stopped.
- **The agent overclaims.** "A browser opened" when none had (row 20), "read+write access verified" after a read (row 22), "only the JWT from here" when module minting still needs a signed transaction (row 25).
- **Secrets on screen.** The full API key was printed three times (rows 18 and 19), against auth-setup's own rule to show only the first and last 4 characters.

## Recommended fixes (To be clear, agent generated. But this report is a good baseline for tool improvement/direction)

Ordered by impact within each area. Row numbers point to the evidence.

### andamio-dev (this repo)

1. **Fix the API key route** in `skills/auth-setup/SKILL.md`, `skills/orientation/SKILL.md`, `SETUP.md`, `AGENTS.md` and `reference/integration-paths.md`: `app.andamio.io/api-setup`, not the preprod URL, and say up front that it currently needs a mainnet Access Token and real ADA. Remove "No real money needed" from the README until that changes. (12, 12a, 15, 16)
2. **Introduce the two wallets in `orientation`.** Explain early that the browser wallet covers the app and login, and that CLI writes need a `.skey` wallet (`andamio wallet create`) and a submit endpoint. In `course-ops`, offer the app as a first-class option when there is no `.skey`, and don't claim later lifecycle steps are JWT-only when they mint on-chain. (24, 25)
3. **Make the install path work.** Add a `marketplace.json` to this repo (or make the marketplace public with andamio-dev in it), document `claude --plugin-dir` for the clone route, and give the `settings.json` path. (2 to 5)
4. **Fix the CLI install guidance.** The cask is `andamio-platform/tap/andamio-cli` (10 places). Check the OS and offer the release download or `go install` on Linux. Sync `reference/andamio-cli-context.md` to 1.2.0. (P3, 8 to 10)
5. **Handle browser login from containers in `auth-setup`.** Run `user login` in the background, show the URL the CLI prints, never say a browser opened unless the user confirms it, and offer the callback-replay, `ANDAMIO_JWT` and `--skey` routes when the agent is in a container. (20, 21)
6. **Mask secrets in `troubleshoot`** as `auth-setup` already requires. (18, 19)
7. **Explain the jargon in auth-setup:** what the Access Token (222-token) is, which wallet to use, switching it to preprod, the faucet, and a link to the app for minting. (11, 13, 14)
8. **Give the next-step menu one line per option and a recommendation**, e.g. "Create your first course: `/course-ops`", or hand back to `/orientation`. (22, 23)
9. Reference the seed with `${CLAUDE_PLUGIN_ROOT}/knowledge/` instead of a `..` path, so the first thing a new developer sees isn't a path-traversal warning. (6)

### Bundled API spec / andamio-docs

1. **Update the API key format** in the spec (`specs/andamio-api.yaml:53` shows `ant-xxxx…`): real keys are `ant_pp_…` (preprod) and `ant_mn_…` (mainnet). (17 to 19)
2. A quickstart in andamio-docs built from this log: one path that works end to end on Linux, with costs and both wallet types stated up front.

### andamio-cli

1. **A fallback for `user login` when the callback can't be reached:** a device-code flow, or accept a pasted callback URL or token. (20, 21)
2. **Browser signing and a default submit route for `tx`** (the same localhost-callback pattern as `user login`, submitting through the Andamio gateway), so a browser-wallet developer can build from the CLI without a `.skey` or a Blockfrost project. (24)
3. **Clearer auth errors:** distinguish "key revoked or expired" from "malformed key". (18)
4. A `--public` filter and table output for `course list`; when a module is `chain_only`, say so instead of pointing back to `course modules`. (26, 28)
5. README: update the pinned `VERSION=1.0.0`, and show `sha256sum` alongside `shasum` for Linux. (P1, P2)

### Andamio app / platform

1. **A way for a newcomer to get a preprod API key without mainnet ADA:** free preprod registration, a shared or sponsored preprod key, or a link to API setup in the preprod app. (12a, 14 to 16)
2. **Warn on network mismatch:** a preprod wallet connected to the mainnet app gets no warning and is still offered a mint. (16)
3. Lace's connect button did nothing (no popup, no error) on the preprod app. (13)
4. After minting an Access Token the wallet had to be reconnected before the app recognised it. (14)
5. The CLI login callback sends `user_id=undefined` as a literal string (the CLI already sanitises it). (21)
6. Spam titles appear in the public preprod course list, which is the first thing a newcomer browsing courses sees. Public courses with `chain_only` modules can't be previewed outside the app. (26, 28)

## Open questions for the Andamio team

1. **API keys on preprod.** Is a mainnet Access Token for a preprod key intended for new developers? If so, the docs need to say so plainly; if not, what should the free route be? Since an API key is application identity, not user identity (andamio-docs `api/accounts/authentication.mdx`), a shared or sponsored preprod key would unblock newcomers without changing the Access Token rules.
2. **Sponsored transactions.** The course-create request has `sponsor_data` ("Sponsored path (Path A)"). Is that meant for onboarding, and could it cover a newcomer's first course on preprod?
3. **Access Tokens across wallets.** Can an Access Token be moved from a browser wallet to a CLI (`.skey`) wallet, or does a CLI wallet need its own?
4. **Course-create alias.** The build endpoint takes `alias` as free text with only the API key. Is it right that the signature is what enforces ownership, so building for another alias just yields a transaction you can't sign? `course-ops` offers "Different alias" without saying so.

## Pre-run observations (reading the READMEs)

| # | Where | Observation | Severity |
|---|-------|-------------|----------|
| P1 | andamio-cli README, "Download a release" | The example pins `VERSION=1.0.0`; the latest is 1.2.0. A copy-paster installs an old CLI. | minor |
| P2 | andamio-cli README, "Download a release" | The checksum step uses `shasum -a 256`; stock Linux has `sha256sum` (`shasum` needs Perl). The example is macOS-only. | minor |
| P3 | andamio-dev SETUP.md §4 | `brew install andamio-platform/tap/andamio`, but the tap only has `andamio-cli` (checked homebrew-tap/Casks). The same wrong name appears in 10 places across andamio-dev, including `skills/orientation/SKILL.md:33,79`, auth-setup, cli-guide, course-ops and lesson 100.2. The orientation skill hands a new developer a failing install command. | major |

## Run log

### Day 1: 20 October, public path only

| # | Step | Expected | Actual | Time | Severity |
|---|------|----------|--------|------|----------|
| 0 | Container started | Clean shell | `dev@` shell, empty home. Start 15:10. | 0 | |
| 1 | Run `claude`, log in | Browser login works from a container | Worked via browser URL and code. Baseline step, not Andamio. | | |
| 2 | Install the plugin per the andamio-dev README | README says where `settings.json` is | "Add to your `.claude/settings.json`" gives no path, doesn't say user or project level, or that the file may not exist yet. Andrew: "I have no idea where to get to this file". Fix: give the path (`~/.claude/settings.json`) or lead with the `/plugin` commands, which need no file editing. | | major |
| 3 | `/plugin marketplace add Andamio-Platform/andamio-marketplace` | Marketplace found, andamio-dev installable | Not found. `andamio-marketplace` is not public (404 to outsiders), and its `marketplace.json` lists only `coach`, not andamio-dev. The README's recommended install path can't work for a new developer. Fix: make the marketplace public and add andamio-dev, or ship a `marketplace.json` in andamio-dev itself. | | **blocker** |
| 4 | README "Clone" route: clone andamio-dev, `cd`, run `claude` | `/start` and `/orientation` available | Not listed. As a plain project, Claude Code only reads `.claude/skills/` (learn, deliver-lesson, assess-assignment); the ops skills, including start and orientation, live in `skills/` and only load as a plugin. The README's "Three ways to start" can't be followed on this route. | | **blocker** |
| 5 | Workaround: `claude --plugin-dir ~/andamio-dev` | Plugin loads | Works: the ops skills appear under `/`. But the flag isn't in the README (outside knowledge), nothing confirms the plugin loaded (you find out by typing `/`), and it must be passed on every launch. Fix: document it as the clone route, or add a `marketplace.json` so `/plugin marketplace add Andamio-Platform/andamio-dev` works. | | major |
| 6 | `/start`, step 0 (plugin init) | Welcome menu | Before the welcome, a permission prompt: "Path contains '..' traversal after a directory segment, which may follow a symlink outside the working directory". Caused by `start/SKILL.md` telling the agent to find the seed at `../../knowledge/` relative to the skill file. A harmless `ls`, but the first thing a new developer sees is a security warning. Fix: use `${CLAUDE_PLUGIN_ROOT}/knowledge/`. (15:23) | | minor |
| 7 | `/start` welcome menu | Clear choice of where to begin | Good. Knowledge base initialised, correctly noticed the CLI isn't installed and offered to set it up, six clear options. Picked "First time here". (15:24) | ~1 min | works well |
| 8 | Orientation steps 1 and 2: intro, check CLI | Clear intro, install guidance that works on my OS | Intro clear; when Andrew asked "this appears to be agent led as opposed to command line cli", the agent explained CLI versus plugin well. The CLI check found `andamio: command not found`. Then it recommended `brew install andamio-platform/tap/andamio`: the wrong cask name (P3), and no OS check, though Homebrew isn't on a stock Linux box. It also said "since this is a walkthrough environment, you may not need to actually install it", guessing this was a demo. (15:24 to 15:26) | | major |
| 9 | Chose "Install it now" | Agent installs the CLI | `which brew`: not found. The agent checked the plugin's `reference/andamio-cli-context.md`, which documents **only** `brew install …/andamio` under "Install (macOS/Linux)", with no release download or `go install`, and concluded "that's the only install method documented for the CLI". It offered to install Homebrew first or look for another route. The CLI README has three methods; the plugin knows one, and it's the broken one. (15:30 to 15:32) | | major |
| 10 | Install Homebrew, then `brew install andamio-platform/tap/andamio` | CLI installs | Homebrew on Linux installed (~1.5 min, modifies `.bashrc`). Then the documented command failed: `No available formula or cask with the name "andamio-platform/tap/andamio"`. The agent recovered **on its own** by reading the tapped cask file and running `brew install --cask andamio-platform/tap/andamio-cli`, which installed andamio 1.2.0. Then `andamio: command not found` in the agent's shell (non-interactive shells skip `.bashrc`), so it prefixed every command with `brew shellenv`. A person following the docs would have been stuck at the cask error. (15:36 to 15:40) | ~10 min | major |
| 11 | auth-setup: "Read + Write", then "No, I need to register" | Clear, beginner-level steps to an API key | A 4-step plan: wallet with Access Token, register at `preprod.app.andamio.io/api-setup`, generate an `ant-` key, paste it back. For a Cardano newcomer: "Andamio Access Token (the '222-token')" is unexplained jargon; "a Cardano wallet" comes with no advice on which one or that it must be switched to preprod; "mint an Access Token via the app" doesn't link the app. Andrew: "this is where it gets a bit trickier. how knowledgeable about the process should the dev be?" (15:44) | | major |
| 12 | auth-setup step 2: register at `preprod.app.andamio.io/api-setup` | The URL works | **Wrong URL.** andamio-docs (`api/getting-started.mdx:29`, `api/reference/environments.mdx:17`, `api/accounts/api-keys.mdx:10`) and the andamio-cli README say keys for every network come from `app.andamio.io/api-setup` (with a network selector); the preprod `/api-setup` redirects to the dashboard by design. andamio-dev still says preprod in 5 places: `skills/auth-setup/SKILL.md:86`, `skills/orientation/SKILL.md:83`, `SETUP.md:121`, `AGENTS.md:123`, `reference/integration-paths.md:73`. | | **blocker** |
| 12a | Same step, the cost underneath | Free, as promised | API keys themselves are free, and preprod keys are "open to everyone" (andamio-docs, since API v2.4.1), but registering needs a **mainnet** Access Token: about 7.9 real ADA (0.36 tx fee, 5 ADA service fee, ~2.5 ADA locked; `protocol/v2/cost-estimation.mdx`). The andamio-docs quickstart is honest about this ("Cardano wallet on mainnet with a small amount of ADA"); andamio-dev isn't: its README says "No real money needed; everything runs on preprod testnet." `skills/auth-setup/SKILL.md:190-193` tells you to get test ADA and mint on preprod, then says the Access Token is a prerequisite for the key. Nowhere in andamio-dev does it say the key needs a mainnet token or real ADA, and every route it gives leads to the preprod dead end. | | **blocker** |
| 13 | New preprod wallet in Lace, test ADA from the faucet (outside the agent, which gave no wallet steps) | Wallet connects to the Andamio app | Wallet and test ADA obtained. On the preprod app's Connect Wallet modal (Lace, Eternl, Google, Discord, X), **clicking Lace did nothing**: no popup, no error. Switched to a second clean wallet in Eternl. (15:58) | | major |
| 14 | Connect wallet, mint an Access Token on the preprod app | Token minted | Connected with Eternl. Access Token minted on preprod, alias `awattsdevtest`. After minting, **the wallet had to be reconnected** before the app recognised the token. Landed on the learner dashboard (0 courses, credentials, projects). **Nothing on the page points to API keys:** the sidebar's Dev Tools only has Component Library and Sitemap. Andrew: "creating an access token wasnt really listed in the instructions… feels like now i'm back at the start of step 2". The agent's plan (row 11) only mentioned minting in passing, with no link, no how-to, and nothing saying it's a separate on-chain step with its own fee. (16:07) | | major |
| 15 | Type the `/api-setup` URL directly (the UI has no link) | Key registration page with a network selector | Used the plugin's URL, `preprod.app.andamio.io/api-setup`. **It redirects to the dashboard** with no message. Following the instructions as written, there is no path to an API key. **A newcomer stops here.** (between 16:07 and 16:12) | | **blocker** |
| 16 | Deviation: try `app.andamio.io/api-setup` (the andamio-docs URL) | Network selector, preprod key | **Also redirects to the dashboard**, which shows "Getting Started 1 of 3" and Create Access Token. The preprod `awattsdevtest` token doesn't count on mainnet, so a second, mainnet token is needed (12a). Also seen: (a) **no network-mismatch warning**: the connected Eternl wallet shows a testnet address on the mainnet app, and the app still offers to mint; (b) the mainnet sidebar does have Dev Tools → API Setup, Usage Dashboard and Billing (greyed out until you have a token), and the preprod sidebar has none of these. So the only UI route to a key is on mainnet, behind a paid token. (16:12) | | **blocker** |

**Paused at 16:12.** The public path ends here, about 62 minutes in. The container was stopped, not removed, so the session, CLI and plugin state carried over to day 2.

### Day 2: 21 October, with insider help

**Resumed at 13:28** in the same container. **Insider help #1:** Andrew's existing preprod API key from his own andamio-cli work. Per andamio-docs, the API key is application identity, not user identity, so a key from anyone works with any wallet's login. The wallet login uses the preprod `awattsdevtest` Access Token minted on the public path in row 14, so that part is not insider help.

| # | Step | Expected | Actual | Time | Severity |
|---|------|----------|--------|------|----------|
| 17 | `claude --continue`, "I have an api key now, carry on with auth" | Agent stores the key, verifies, moves on to the wallet JWT | Good start: auth-setup loaded, checked state, asked only for the missing key, and offered "run the command yourself" so the key stays out of the chat. But it said keys start with `ant-` (real keys are `ant_pp_…` and `ant_mn_…`), and it skipped auth-setup Step 1 (environment selection), though the URL turned out to be preprod. The first key was rejected (401), so it switched to the `troubleshoot` skill. (13:29) | | minor |
| 18 | Troubleshoot the 401 | Clear cause: expired or revoked key, or wrong environment | The agent read the OpenAPI spec and curled routes by hand (finding the real prefix is `/api/v2/…`, not `/v2/…`), confirmed a clean gateway 401, then **misdiagnosed**: because the spec shows keys as `ant-` plus hex, it told Andrew his key "is not an Andamio key… probably from a different service". It was a real, old preprod key; the spec's key format is out of date, so the docs talked the agent into a false conclusion. It then sent him back to `preprod.app.andamio.io/api-setup`, the URL that redirects (row 15). **The full API key was printed in plain text** in a curl command and again in the explanation, against auth-setup's rule to show only the first and last 4 characters. (13:29 to 13:40) | ~11 min | major |
| 19 | Give the agent a working key (insider help #1, continued) | Accepted, stored, verified | A new key couldn't be generated in the app, so Andrew used the key from his own andamio-cli config (checked first: 200 on preprod). The agent again flagged "the same format mismatch" but this time **tested before assuming**, got a 200 and corrected itself ("my format assumption from the spec example was wrong"). It stored the key with `andamio auth login --api-key` and checked `auth status` and `course list`. A good recovery, but the out-of-date spec costs every new developer a detour, and the full key was printed again (command and approval prompt). (13:50) | ~3 min | minor |
| 20 | Wallet JWT: auth-setup offers browser login, `--skey`, or "no Access Token yet"; picked browser (`andamio user login`) | Browser opens, sign with Eternl, CLI gets the JWT | The menu was good: plain requirements, and the "no Access Token" option says the preprod fee is covered by the faucet (what was missing at row 12). Then: there's no browser in the container, so the CLI printed "Failed to open browser… Please open this URL manually" (`cmd/andamio/user.go:218-221`, correct). But the agent **spun for several minutes, then told Andrew a browser had opened** when none had. `user login` blocks while it waits for the callback, which the agent's shell tool handles badly. Only when Andrew asked for the URL did it give it, with a correct note that the `127.0.0.1:<port>/callback` redirect only works on the same machine. Signing in the host browser gave **`127.0.0.1 refused to connect`**: the callback listener is inside the container. Anyone running their agent in a container, devcontainer or remote machine hits this. (13:59 to 14:07) | ~8 min | major |
| 21 | Retry `user login` (the 5-minute timeout had expired), complete via the callback URL (insider help #2) | Login completes | The agent re-ran login in the background and gave a fresh URL, noting the timeout (good). After signing it correctly diagnosed that the sign-in never reached the callback server, but **didn't suggest a way round it**; it asked where Andrew had signed in. Andrew supplied the workaround: copy the failed `127.0.0.1:<port>/callback?…` URL from the host's address bar and replay it with curl inside the container. **It worked** and the JWT was stored. A newcomer wouldn't know this, so it's insider help #2. Side notes: the callback carries `user_id=undefined` as a literal string (the CLI already sanitises it, `user.go:184`); the replayed URL contains the full JWT in plain text. (14:08 to 14:11) | ~3 min | major |
| 22 | Auth wrap-up | Clear summary and next steps | Good: confirmed the replay worked (JWT valid ~23h), a tidy summary (environment, key, JWT, config path), and unprompted, a note that every future `user login` in a container needs the same manual relay. But it said **"read+write access verified"** when the only check was `andamio user me`, a read (confirmed from the session transcript). Next steps were four bare skill names (`/explore-api`, `/cli-guide`, `/course-ops`, `/project-ops`) with nothing on what each does or which to pick. **Auth complete at about 14:12.** | ~1 min | nit |
| 23 | `/cli-guide`, chose "browse" | Help browsing my data | A clear, well-laid-out command reference (command, auth needed, exit codes, `jq` chains), ending with an offer to run them. Works as designed, but it's a reference mode, not a doing mode: a newcomer who wants to see their data gets a page of commands first. The menu in row 22 gave no hint that cli-guide is reference-only and course-ops is where you build. The skill's CLI reference is "synced against CLI v1.1.2" (installed: 1.2.0). | ~2 min | nit |
| 24 | `/course-ops`, "create a new course" | Guided creation, signed with the wallet I already used | Good start: checked the JWT, listed course actions with the cost up front ("on-chain, ~119.3 ADA with one teacher"), read the request schema from the spec, then a stepped form: Owner alias, Teachers, **Signing key**, Submit. The alias step offered "Different alias" without saying only that alias's wallet can sign. Then: **"Do you have a Cardano payment signing key (.skey file) for this wallet?"** with **no browser-wallet option**. Choosing "Not sure", the agent searched for `.skey`/`.addr` files and checked `config show`, then gave a clear, honest diagnosis of **two** blockers: (1) no `.skey`, and "the browser wallet you used for user login (CIP-30) does **not** give the CLI a local key"; (2) **no submit URL**: `andamio config set-submit-url` must point at a chain-submit service such as a Blockfrost `/api/v0/tx/submit` endpoint with a project ID, a second third-party account nothing earlier mentioned. It offered: give a `.skey` path, use the Andamio app instead, or build the unsigned transaction only. It didn't mention `andamio wallet create` (which would make a new wallet without the Access Token anyway). (14:21 to 14:23) | ~2 min | **blocker** (CLI path) |
| 25 | Chose "Use the Andamio app instead" | Clear handoff to the app and back | A clear 3-step handoff: create the course on the preprod app with the same wallet, bring back the `course_id`, and the CLI carries on (modules, content, publish), with the reply pre-filled as "the course_id is <id>". But it said the rest of the lifecycle "only need[s] the wallet JWT you already have, not the skey". The plugin's own `course-ops` skill says **each module is a Cardano transaction (~1.86 ADA)** and publishing mints modules with `tx run`, so the row 24 blocker returns at the first module mint. Only the DB-side steps (module shell, DRAFT content import) are JWT-only. (14:26) | ~1 min | major |
| 26 | "can i view what courses are available with a view to enrolling in one?" | List of courses I could join | Works with the API key alone. Raw `course list` returned 79.6 KB of JSON, including private courses; the agent filtered on `is_public` with `jq` to 34 public preprod courses and picked out the structured ones in a table. Unprompted, it noted that the public list includes obvious spam titles (open testnet) and that **enrolment happens in the app, not the CLI** (CLI 1.0 removed the learner commands). A good answer. (14:27) | ~1 min | minor |
| 27 | "Cardano Go looks good, how do i enroll?" | How to enrol | Pulled `course get` and `course modules`, then clear app steps: connect the same wallet, commit (~2.64 tADA, in-browser signing), submit evidence, teacher accepts, claim credential. Correct that this is app-only. A slightly muddled close about checking progress (offered a teacher-side command, then said to use the app). (14:28) | ~1 min | nit |
| 28 | "what can you tell me about the course", then try the assignment and intro | Course content preview | Description and 4 SLTs from on-chain data, then a clear "what's missing": the module is `source: "chain_only"`, so **no module code, lesson, assignment or intro is reachable from the CLI or API**. The agent then guessed module codes `100`, `101` and `1` for `course assignment`; each failed with "Run `andamio course modules <id>` to see which modules have assignments", the command that had just returned no module code. A flagship public preprod course can't be previewed outside the app. (14:29) | ~1 min | minor |

**Stopped at 14:30.** This is the natural end of the run: the CLI write path is blocked for a browser-wallet developer (row 24), and learner actions are app-only (rows 26 to 28). Course creation in the app was not attempted.

## Appendix A: Dockerfile

```dockerfile
# Clean first-run box for the MRP Month 4 friction log.
# Baseline = "a developer with a terminal + an AI coding agent".
# Deliberately NOT installed: andamio CLI, Go, Cardano tools, any Andamio repo.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo jq nano less \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

# Fresh user, empty home, passwordless sudo (a normal dev laptop has admin rights)
RUN useradd -m -s /bin/bash dev && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
CMD ["bash"]
```

To reproduce: `docker build -t andamio-first-run:2026-10 .` then `docker run -it --name andamio-first-run andamio-first-run:2026-10`. Inside: `git clone https://github.com/Andamio-Platform/andamio-dev ~/andamio-dev`, then `claude --plugin-dir ~/andamio-dev`.
