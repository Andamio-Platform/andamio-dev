# Compute an slt_hash for a course module

## Before we start

Last lesson described the three-layer structure and mentioned that `slt_hash` bridges on-chain identity with off-chain SLT text. This lesson makes that concrete: you'll compute a hash, see what changes it, and understand why the encoding matters.

## What slt_hash is

An `slt_hash` is a 64-character hex string — the Blake2b-256 hash of a module's SLT list. It's the on-chain identity of a module's learning targets. Two modules with identical SLTs produce the same hash. Change one character in one SLT and the hash is completely different.

The hash is what goes on-chain when a module is minted. The SLT text stays off-chain. Anyone with the text can recompute the hash and verify the match.

## Compute a hash from SLT text

```bash
andamio course credential compute-hash \
  --slt "Learner can explain the Andamio transaction state machine" \
  --slt "Learner can execute a transaction through its full lifecycle"
```

Expected output:

```
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1
SLT count: 2
```

| Flag | Purpose |
|------|---------|
| `--slt` (repeatable) | One SLT text string per flag. Order matters — same SLTs in different order produce a different hash. |

For structured output:

```bash
andamio course credential compute-hash \
  --slt "Learner can explain the Andamio transaction state machine" \
  --slt "Learner can execute a transaction through its full lifecycle" \
  --output json
```

```json
{
  "slt_hash": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1",
  "slt_count": 2,
  "slts": [
    "Learner can explain the Andamio transaction state machine",
    "Learner can execute a transaction through its full lifecycle"
  ]
}
```

## Compute from a file

If SLTs are stored in a markdown outline (the format the Andamio CLI uses for course import):

```bash
andamio course credential compute-hash --file ./compiled/my-course/100/outline.md
```

The CLI parses SLTs from the `## SLTs` section of the file. Same hash as the `--slt` flag approach if the text matches exactly.

## What the encoding actually is

The hash is Blake2b-256 over a PlutusTx-serialized byte string list. Not Plutus Data — raw PlutusTx byte strings. This is a Cardano-specific encoding detail, but it matters for one reason: you can't reproduce the hash by hashing the SLT text with a generic Blake2b library. The serialization step adds structure.

The CLI handles this. You never need to implement the encoding yourself — but if you're debugging a hash mismatch, knowing that the encoding is PlutusTx byte strings (not plain text, not Plutus Data, not CBOR) narrows the search.

## What changes the hash

| Change | Same hash? |
|--------|-----------|
| Identical SLTs, same order | Yes |
| Same SLTs, different order | **No** — order is part of the encoding |
| Trailing whitespace added | **No** — byte-level comparison |
| Different capitalization | **No** |
| SLT added or removed | **No** |

One-character change → completely different 64-character hex string. This is the content-addressed property: the hash is the identity of the content, not a label.

## Verify an existing module's hash

If you have a published course and want to confirm its modules match your SLT source files:

```bash
andamio course credential verify-hash <course-id>
```

This pulls the course's modules from the Andamio API, recomputes each `slt_hash` locally from the stored SLT text, and reports any mismatches. Requires authentication (API key or JWT).

## Your turn

Compute the `slt_hash` for a module with these two SLTs (in this order):

1. "I can explain how Andamio courses are structured."
2. "I can compute an slt_hash for a course module."

Run the command with `--output json` and paste the result.

Then swap the order of the two SLTs and compute again. Are the hashes the same?

## Rubric

The two hashes are different. Order matters because the SLTs are serialized as an ordered list. The first computation produces one 64-character hex string; the swapped computation produces a different one. If both hashes are identical, something went wrong — check that you actually swapped the `--slt` arguments.

## What you just did

You can compute an `slt_hash` from SLT text and verify it against a published course. You also know what changes the hash (everything — order, whitespace, casing, content) and what the encoding is (Blake2b-256 over PlutusTx byte strings). This hash is what you'll reference in the next lesson when you publish a module on-chain.
