# Container run, November 2026

**What this is:** a timed run of the revised `auth-setup` skill (#38) in a fresh container, playing a developer new to Andamio, followed by an exploratory pass at creating a course and minting its first module with the `course-ops` skill. Every point where the path broke, misled or slowed down is recorded with what happened and what would fix it.

**Why:** #38 was to be approved after an end-to-end run of the new route, in particular two steps nobody had run yet: a headless login with an alias the wallet doesn't hold, and the Access Token mint on that session. This is that run. It is also evidence for Month 5 of the andamio-cli MRP (auth-setup polished), and a first look at the Month 6 goal of creating a course quickly from the CLI.

**Run by:** Andrew (awattsdev), 20 November 2026, on preprod. Compare with the October first-run log (#32).

## How the run was done

**The box.** The same fresh `ubuntu:24.04` container as October (Dockerfile in #32's log, Appendix A), rebuilt from scratch, with Claude Code 2.1.197.

**What was different from a real newcomer**, because the skill under test isn't merged yet:

- The plugin was loaded from this PR's branch (`fix/auth-setup`, 1d09c84) with `claude --plugin-dir ~/andamio-dev`, not through the marketplace setup in the README.
- The andamio CLI was built from andamio-cli main (8c644b4, which includes andamio-cli#216, #217 and #218, not yet released) and installed before the run. The install step was not timed.

**The API key step ran for real** at `app.andamio.io/api-setup`, with a browser wallet holding a mainnet Access Token.

**Who did what.** As in October: Andrew drove the Claude Code agent in the container and did the browser steps himself (portal, faucet, Blockfrost). A second Claude Code session on the host read the container agent's transcript as it was written (read-only, through `docker exec`, secrets masked), logged each step and checked claims against the andamio-cli source. Where that session told the container agent something it hadn't worked out itself, it is marked as **insider help**.

**Opening prompt**, in a newcomer's words: "I'm new to Andamio. I want to set up the Andamio CLI so I can create courses. Can you get me authenticated?"

**Times** are CET.

## Results at a glance

| | October (#32) | November (this run) |
|---|---|---|
| Empty box to authenticated CLI with an alias | about 106 minutes, with two pieces of insider help | **14 minutes**, none |
| Course created on-chain | never reached | **about 4 minutes** after auth (public at 10:01) |
| Module drafted and minted | never reached | done, with snags (10:02 to 10:24); stuck as DRAFT until 11:19 |

**Headline 1: the auth route works.** The agent picked up `auth-setup` on its own, warned about the mainnet Access Token before starting, ran the Blockfrost signup while the faucet ADA arrived, and got the submit URL right first time. Both checks for #38 passed.

**Headline 2: `course teacher mint-modules` will mint a module that is still DRAFT, and the module then sticks.** The draft never stored its SLT hash, so the minted module couldn't be matched to it. It took setting the draft to APPROVED with the hash by hand to bring it to ON_CHAIN. course-ops currently describes minting from DRAFT, which is the path the agent followed.

**Headline 3: `course import` can't add an SLT to an existing module, and reports success.** The new SLT and its lesson were dropped without an error in JSON output.

## Part 1: auth-setup

| Time | Step | Notes |
|---|---|---|
| 09:38 | Opening prompt | `auth-setup` picked up without a nudge. Pre-check found the CLI on preprod and nothing else |
| 09:39 | API key | Warned up front that keys come from the mainnet portal and need a mainnet Access Token. Sent the developer to `app.andamio.io/api-setup` for a preprod key (`ant_pp_`) |
| 09:41 | Store the key | "Run `andamio auth login --api-key <key>` yourself". The developer was inside Claude Code and the skill didn't say where to run it. A `!` command would have put the key in the transcript. The CLI takes the key only as a flag, so it also lands in shell history |
| 09:43 | Key works | Read access confirmed (`course list`) |
| 09:43 | Wallet | `wallet create`, plaintext mnemonic warning given. The agent paused to ask "ready?" before giving the faucet link |
| 09:44 | Faucet | The skill said "choose Preprod", but the faucet page has several dropdowns; the one that matters is **Environment** |
| 09:44 to 09:50 | Blockfrost | Started while the faucet ADA arrived. Full `/api/v0/tx/submit` URL set first time. `set-submit-header project_id <id>` asks a newcomer for an HTTP header name |
| 09:50 | Balance | The agent tried `andamio wallet balance`: there is no balance command. It went on and let the mint tell it |
| 09:51 | Login with an alias the wallet doesn't hold | **Check 1.** Session returned, no error (pass). But the CLI printed "Authenticated as: awattsdev-tester" and `user status` showed the alias, although the wallet held no token: when the API returns no alias, `user login` saves the `--alias` flag (`cmd/andamio/user.go`, around line 357). The skill said `user status` would show no alias |
| 09:52 | Access Token mint | **Check 2.** Built, signed, submitted through Blockfrost and confirmed in about 30 seconds (pass). `tx run` warned that `--skey` wasn't given |
| 09:52 | Second login and summary | Alias attached. `user me --output json` returned 118 KB |

## Part 2: course creation (course-ops, exploratory)

| Time | Step | Notes |
|---|---|---|
| 09:57 | course-ops | Warned the create is a paid transaction (about 119 ADA) and asked for teachers up front, since adding them later costs more |
| 09:58 | First create | Build failed: 404 "No access token with alias: nature-photography". The agent put the course name in `alias`, which is the owner's alias. course-ops shows `Body: { alias, teachers }` and `"my-alias"` without saying whose. It recovered in about 25 seconds by reading the bundled spec |
| 09:59 | Course created | Confirmed on-chain |
| 09:59 | Set the title | `course owner register` returned 409 "Course already registered": `tx run` with `--tx-type course_create` registers the course itself. It also passed `--tx-hash`, which the API has ignored since 2.6.0 but `reference/andamio-cli-context.md` still lists |
| 10:00 | Find the course | `course list` (public courses) didn't show it. `course list` returns a bare JSON array where `user me` wraps in `.data`, and `course get` takes the ID as an argument where `course owner update` uses `--course-id`: two wrong guesses |
| 10:00 to 10:01 | Title and visibility | `course owner update --title`, then `--public` |

## Part 3: first module (exploratory)

| Time | Step | Notes |
|---|---|---|
| 10:03 | Create module | DRAFT with three SLTs |
| 10:03 | Review first | The developer stopped the agent importing content straight away and asked for draft files to read first, then added a fourth SLT |
| 10:08 | Drafts | Introduction and four lessons written locally |
| 10:10 | Image | A photo placed in the module's `assets/` folder and added to the introduction |
| 10:11 | Dry run | JSON listed the image under `failed_images`. In dry-run, that list holds images that *would* be uploaded (`course_import.go:343`); text mode says so correctly. The agent took it as a real failure and started inspecting the file. **Insider help:** the host session told it the image was fine |
| 10:12 | Import | Reported success, `slt_count: 4`, `lesson_count: 4`, `lessons_created: 3` |
| 10:13 to 10:15 | Missing SLT | The fourth SLT was never created. When a module already has SLTs, import sends every SLT with an `slt_index`, so the new one is treated as an update to an index that doesn't exist and dropped (`course_import.go`, around line 1609). Lesson 4 was then skipped, with the warning shown only in text mode. The agent found the dropped SLT itself |
| 10:16 to 10:21 | Rebuild | The module was still DRAFT, so it was deleted and recreated with four SLTs, then imported: four lessons created |
| 10:23 | Mint | `mint-modules` build refused: "Text length 175 exceeds maximum of 140 characters". `create-module`, `import` and `mint-modules --dry-run` had all accepted it. Two SLTs were shortened and the module rebuilt |
| 10:24 | Mint | Confirmed on-chain |
| 10:25 | Register | The agent ran `register-module` without being asked: "module 101 found in teacher list but slt_hash field is missing or empty (response shape may have changed)". Reproducible |
| 10:25 to 11:17 | Waiting | The agent waited for the indexer. `course modules` showed two records: a `chain_only` one with the minted hash, and the DRAFT with an empty `slt_hash`. `tx status`: `not_indexed_count: 1`. The troubleshoot skill's gotcha-010 matches `not_indexed_count`, but its cause (wrong submit URL, resubmit) doesn't apply to a confirmed transaction |
| 11:19 | Fixed | `course teacher update-module-status --status APPROVED --slt-hash <hash>`: the two records merged at once and the module showed ON_CHAIN |

## Proposed fixes

To be clear, these were drafted with an agent from the log above, as in October.

### andamio-dev, follow-up PR

#38 itself only adds this report and the "up to 1.3.0" wording James asked for. Everything below goes in a follow-up PR.

- **auth-setup, secrets:** say where to run a command that holds a secret: a separate terminal, not the chat or a `!` command (which lands in the transcript), started with a space to keep it out of shell history.
- **auth-setup, alias:** read the attached alias from the API (`user me`, `.data.user.alias`), not `user status`, in the pre-check, the routing table and steps 4 to 7. Don't print the whole `user me` response.
- **auth-setup, faucet:** name the **Environment** field. There's no CLI balance command, so give an explorer link, or let the mint report it. Suggest setting up the submit endpoint while the faucet ADA arrives.
- **auth-setup, mint:** pass `--skey` on the mint command.
- **course-ops, creating a course:** `alias` is the owner's Access Token alias; the create transaction takes no name. `tx run` registers the course, so set the title with `course owner update`, and find it with `course owner list`.
- **course-ops, minting a module:** the "SLT hash workflow" says to mint from DRAFT and register afterwards "if needed", while the status section says DRAFT → APPROVED → PENDING_TX → ON_CHAIN. Make them agree: set APPROVED with the SLT hash, then `course teacher mint-modules`. Add the fix for a module already minted from DRAFT.
- **course-ops, SLTs:** 140 characters at most. Until the CLI is fixed, adding an SLT to an existing DRAFT module means deleting and recreating it.
- **course-ops, content:** offer a review step (draft locally, the owner reads it, then import) before anything is published.
- **knowledge:** a gotcha for "minted while DRAFT, stuck with an empty `slt_hash`" and one for SLTs over 140 characters. gotcha-010: say it doesn't apply once `confirmed_at` is set.
- **reference/andamio-cli-context.md:** drop `--tx-hash` from `course owner register`; add `mint-modules` once andamio-cli 1.3.1 is released.
- **README.md:** "No real money needed" contradicts the mainnet Access Token needed for an API key today.

### andamio-cli, issues to raise

1. `course teacher mint-modules` mints a module that is still DRAFT. It should set APPROVED with the hash first, or refuse. Its hash guard compares a locally computed hash, so it doesn't notice an empty stored one.
2. `course import` can't add an SLT to a module that already has SLTs, and reports success. (An earlier version of this report also listed the draft not storing the `slt_hash` the import sent. That's by design: the API stores the hash only when a module is approved.)
3. No check of the 140-character SLT limit before the mint build.
4. `course teacher register-module` can't recover a module minted from DRAFT ("slt_hash field is missing or empty"). A draft that was never approved has no stored hash, and the command's lookup treats that as an error, so its DRAFT → APPROVED step is never reached.
5. `user login` and `user status` show the `--alias` flag as the user when the API attached no alias.
6. Dry-run JSON lists images to be uploaded under `failed_images`.
7. Smaller:
   - `auth login` takes the key only as a flag.
   - There's no wallet balance command.
   - `set-submit-header` asks a newcomer for a header name. One provider-neutral option: `set-submit-url <url> --api-key <value>`, choosing the header for providers the CLI recognises and falling back to `set-submit-header`.
   - JSON shapes and ID arguments differ between commands.

## Evidence (preprod)

| What | Hash / ID |
|---|---|
| Alias | `awattsdev-tester` |
| Wallet address | `addr_test1qragtfstuejs43tnrqwpq4cuwy348an6kvwcweqedssf3znrqpc539d6xhuu54lvzuu2tx9wqlylmge0nh7nnxgx46gqhapzft` |
| Access Token mint | `0b6e944d5d15ac78faccaded54c91df7135a690740e238fec7a66ed30dc931f0` |
| Course create | `c983e3e7ddd3b40525bb29157abc3416c61f35fe449e83a77f6a06a3aee2793e` |
| Course ID ("Nature Photography") | `694417e4f60a21dab4b3b29bb0beeb5511e8617ea4df682db5a505ab` |
| Module 101 mint | `5c369db327b981935f07641c4bca744e90eef1fbe1928841687ae6b7d40d1792` |
| Module 101 SLT hash (minted) | `ecbeee25d58849f320c137e85fd2481adc1cd9452b327ad7900c9390647a6f4d` |
| SLT hash the first import reported (never minted) | `7735a8df4d5551f32d8c8ecacfea7aaa0c00bc8ed1973121ae7a22fedc37951f` |
