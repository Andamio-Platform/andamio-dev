# Describe each step of the Andamio TX state machine

## Before we start

Every write operation on Andamio goes through the same five-step pattern. You saw it in M200.1 when you minted your access token. Module 400 is where you learn the pattern itself — this lesson describes *what happens*; M400.3 teaches you *how to see it happen*.

## Write operations vs off-chain drafts

| Shape | What it is | State machine? | Covered in |
|-------|-----------|----------------|------------|
| **On-chain write** | A Cardano transaction (create course, submit evidence, claim credential) | Yes — five steps below | This module |
| **Off-chain draft** | Preparation work before any TX (authoring SLTs, lesson content, task descriptions) | No — free, no chain involved | M500, M600 |

For the rest of Module 400, "write operation" and "transaction" mean the on-chain shape.

## The five steps

```
build → sign → submit → register → wait
```

**1. Build.** You send a request to the Andamio API describing what you want to do. The API reads the chain state, selects UTxOs, and returns an unsigned transaction as CBOR hex. Nothing has touched the blockchain. You can discard the unsigned TX and nothing happens.

**2. Sign.** Your CLI reads your `.skey` and signs the CBOR locally. Your private key is used here and only here — it never leaves your machine. The signed CBOR is still just a string in your terminal. No network calls since build.

**3. Submit.** The signed CBOR is broadcast to the Cardano network. If accepted, you get back a transaction hash — a 64-character hex string that uniquely identifies this transaction on Cardano forever. If you write nothing else down, write down the hash.

**4. Register.** The CLI sends the tx_hash and `tx_type` to the Andamio API, which stores it with state `pending` and starts watching for on-chain confirmation. Without registration, the transaction still lands on-chain, but the Andamio API doesn't know it's there and can't sync its off-chain view.

**5. Wait.** The CLI polls the Andamio API's status endpoint. Status goes `pending → confirmed → updated`. `updated` is the only status that means "fully done and safe to query." Usually 30–90 seconds on preprod.

## Why five steps and not one

The split exists because of keys and trust:

- **Sign must be local.** Your private key can never reach the Andamio API. That's the non-custodial guarantee. If the five steps were one request, the API would either hold your key (custodial, bad) or somehow use it without transmitting it (impossible).
- **Submit is separate from build** because Cardano's submit path is its own infrastructure. Submit can fail for Cardano-specific reasons (bad UTxO selection, insufficient fees, mempool conflicts) that have nothing to do with Andamio.
- **Register is separate from submit** because you're informing a different system. Submit tells Cardano; register tells Andamio.
- **Wait is separate from register** because without it, your code reads stale data. M400.2 is about exactly this failure mode.

The CLI hides all five behind `andamio tx run` for convenience, but the steps are always there.

## Vocabulary: transaction loops

A single transaction — one run through the five steps — is the atomic unit of work. Many workflows require several transactions in sequence: creating a course, adding modules, enrolling a student, assessing, credentialing. A named sequence that accomplishes a larger goal is a **transaction loop**. You'll meet specific loops in M500 (course) and M600 (project).

## Your turn

1. **Name the five steps in order** and write one sentence each describing what happens. Don't look back first.
2. **Which step uses your private key, and which steps happen entirely on your local machine?**

## Rubric

**Five steps:** Build (API returns unsigned CBOR), Sign (CLI signs locally with `.skey`), Submit (broadcast to Cardano, get tx_hash), Register (tell Andamio API to track it), Wait (poll until `updated`). Order and mechanism matter; phrasing doesn't.

**Security boundary:** Private key is used in step 2 only. Steps 1–2 happen locally (build sends a request but only receives unsigned CBOR back). Steps 3–5 involve network calls but never transmit your key.

## What you just did

You understand the five-step pattern and why it's five steps: the private key stays local, Cardano and Andamio are separate systems, and waiting is how you know the write is done. Every lesson from here through M700 builds on this.
