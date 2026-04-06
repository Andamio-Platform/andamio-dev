# Terminology — Build on Andamio

The authoritative terminology reference for this course. Every lesson author, every contributor, every agent drafting content against this course must honor the rules below.

The goal is audience-facing clarity. Learners should see the Andamio ecosystem through a small, stable vocabulary that maps cleanly to what they'll actually touch: the Andamio API, the Andamio CLI, the Andamio App, the Andamio App Template. Internal service names and implementation details do not belong in learner-facing material.

## Approved terms

Use these exact names. Match the capitalization.

| Term | Meaning |
|---|---|
| **Andamio API** | The HTTP API at `api.andamio.io` (or whichever base URL the learner has configured). This is the single public entry point learners talk to for reads and writes. When you would have written "the gateway," write "the Andamio API" instead. |
| **Andamio CLI** | The `andamio` binary installed via Homebrew in M100.2. It wraps the Andamio API for terminal use. |
| **Andamio App** | The web application at `app.andamio.io`. Where learners read lessons and submit assignments if they're using the web path. |
| **Andamio App Template** | The public repository at `github.com/Andamio-Platform/andamio-app-template`. The scaffold for learners who want to build an Andamio-integrated app, introduced in M700. |
| **access token** | The on-chain asset minted in M200.1. Creates a learner's alias and establishes their identity on the protocol. Always lowercase unless at the start of a sentence. |
| **alias** | The human-readable identifier minted with an access token. A learner's primary identity across every Andamio interaction. Always lowercase unless at the start of a sentence. |
| **course** | An Andamio course — the protocol's primary construct for credentialed learning. |
| **project** | An Andamio project — the protocol's construct for credentialed contribution with on-chain treasury. |
| **evidence** | The artifact a learner submits to earn a credential. Could be written reflection, code, a transaction hash, a repo link, feedback on a lesson — whatever the assignment asks for. |
| **credential** | The on-chain record issued when evidence is accepted. Tied to an alias, verifiable forever. |

## Forbidden terms

Never use these in course content. If you find yourself reaching for one of them, the approved term in the adjacent column is the fix.

| Forbidden | Why it's forbidden | Use this instead |
|---|---|---|
| **gateway** (and "gateway API", "the gateway", "Andamio gateway") | An internal service name for the public-facing API. Exposing the name leaks internal architecture and confuses learners who don't need to know about it. | **Andamio API** |
| **andamioscan** | Internal indexer service. Not a subject of this course. | *(no direct substitute — rephrase to describe the behavior without naming the indexer)* |
| **tx api**, **tx-api**, **txapi**, **Atlas**, **atlas** | Internal transaction-building service. Not a subject of this course. | *(no direct substitute — describe what happens without naming the service)* |
| **db api**, **db-api**, **dbapi** | Internal database service. Not a subject of this course. | *(no direct substitute — rephrase to describe the behavior)* |

## Edge cases and context rules

- **"Gate" is not "gateway."** The word *gate* — as in "the gate between Learning Mode and Ops Mode" in M100.4 — is allowed and has nothing to do with the forbidden *gateway*. Don't over-correct.
- **"on-chain" and "off-chain"** are allowed. They describe data characteristics, not services. When a lesson needs to explain where data comes from, "on-chain data" and "off-chain data" are the right terms. See M300.1 for the canonical framing: on-chain data is the commons; off-chain data is local to whichever Andamio API is answering.
- **Don't name internal services even when describing architecture.** If M200.4 needs to explain that a JWT is issued by a service and verified by another, describe the flow ("a signing service issues the JWT; the Andamio API verifies it on incoming requests") without naming the services. The learner doesn't need the division of responsibility.
- **Filenames are content.** If a file in the repo has a forbidden term in its name (e.g., `specs/gateway-api.yaml`), the file must be renamed. Lesson references to filenames must use the approved name.
- **URL paths may contain `tx`.** The HTTP path `/v2/tx/global/user/access-token/mint` is fine — `tx` as a URL segment is the protocol's actual wire format, not a service name. The rule targets prose references to internal services, not literal endpoint paths.
- **The literal string `andamio-api`** (e.g., in a JWT `iss` field) is allowed. That's a verifiable claim value, not a prose reference.

## Why these rules exist

Andamio's public surface is small and stable: an API, a CLI, an app, a template. Behind that surface lives a constellation of services that may change, be renamed, get split, or be merged without the public surface moving at all. Course content that names those services ties the learner's mental model to implementation details that aren't theirs to care about. Course content that uses the public names — **Andamio API**, **Andamio CLI**, **Andamio App**, **Andamio App Template** — stays correct as the implementation evolves.

It also tells learners the truth about what they need to know. A developer building on Andamio does not need to know which service answers their requests; they need to know how to call the API, read the response, and act on it. Teaching them the internal service layout is a distraction that trades clarity for false expertise.

## Maintaining this file

Every time a new lesson author proposes content, they should check against this file. Every time the ecosystem adds a new public surface (a new CLI tool, a new app, a new SDK), the approved terms table should grow. Every time internal service names leak into lesson content during drafting, a reviewer should catch it against this file.

If the rules need to change, update this file first, then cascade the change to lesson content in a dedicated pass. Don't let the rules drift from the content; the point of writing them down is to keep the two in lockstep.
