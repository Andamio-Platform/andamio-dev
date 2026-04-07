# Compute a task_hash for a project task

## Before we start

In M500.2 you computed an `slt_hash` — the content-addressed identity of a module's learning targets. Projects have an equivalent: the `task_hash`, which identifies a task by its content, reward, and expiration. Same concept, different encoding. This lesson covers the command, the fields, and why the encoding differs.

## What task_hash is

A `task_hash` is a 64-character hex string — the Blake2b-256 hash of a task's on-chain datum. It identifies a specific task within a project. The contributor references this hash when committing to a task, and it appears in the credential's on-chain metadata.

Like `slt_hash`, it's deterministic: same inputs produce the same hash. Unlike `slt_hash`, the inputs include more than just text.

## The fields that feed the hash

| Field | Type | Example |
|-------|------|---------|
| `content` | String | `"Build an API integration example"` |
| `lovelace` | Integer | `50000000` (50 ADA) |
| `expiration` | Date (converted to POSIX milliseconds) | `2026-12-31` → `1767225600000` |
| `native_assets` | Array of (policy_id, token_name, quantity) | `[]` or token triples |

Change any field — the description, the reward amount, the expiration date, or the native asset list — and the hash changes completely.

## Compute a hash from fields

```bash
andamio project task compute-hash \
  --content "Build an API integration example" \
  --lovelace 50000000 \
  --expiration 2026-12-31
```

For structured output:

```bash
andamio project task compute-hash \
  --content "Build an API integration example" \
  --lovelace 50000000 \
  --expiration 2026-12-31 \
  --output json
```

```json
{
  "task_hash": "b7e4f2a1c8d3e5f6a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1",
  "fields": {
    "content": "Build an API integration example",
    "lovelace": 50000000,
    "expiration_ms": 1767225600000,
    "tokens": []
  }
}
```

| Flag | Purpose |
|------|---------|
| `--content` | Task description string (matches `project_content` in the TX body) |
| `--lovelace` | Task reward in lovelace (1 ADA = 1,000,000 lovelace) |
| `--expiration` | Expiration date — CLI converts to POSIX milliseconds |
| `--token` | Optional. Format: `"policy_id,token_name,quantity"`. Repeatable for multiple native assets. |
| `--output json` | Structured output with all resolved fields |

## With native assets

```bash
andamio project task compute-hash \
  --content "Build an API integration example" \
  --lovelace 50000000 \
  --expiration 2026-12-31 \
  --token "722c475bebb10...,XP,50"
```

Native assets change the hash. A task with the same content, lovelace, and expiration but different tokens is a different task.

## Compute from a file

```bash
andamio project task compute-hash --file ./tasks/001-build-api.md
```

The CLI reads task fields from YAML frontmatter in the markdown file. Same hash as the flag approach if the fields match exactly.

## The encoding difference

Both `slt_hash` and `task_hash` are Blake2b-256, both are 64-character hex. The encoding is different:

| Hash | Input encoding |
|------|---------------|
| `slt_hash` | PlutusTx-serialized byte string list (raw text) |
| `task_hash` | Plutus Data wrapped in `Constr 0 [content, expiration, lovelace, native_assets]` with CBOR tag 121 |

Why the difference? SLTs are pure text — a list of strings. Tasks have structured data — a string, an integer, a timestamp, and an asset list. The Plutus Data encoding preserves this structure so the on-chain validator can read individual fields.

You don't need to implement either encoding. The CLI handles both. But if you're debugging a hash mismatch, knowing which encoding is in play narrows the problem: `slt_hash` mismatches are always about text (order, whitespace, casing). `task_hash` mismatches can also be about numeric fields (lovelace amounts, expiration timestamps, asset quantities).

## Verify an existing project's hashes

```bash
andamio project task verify-hash <project-id>
```

Pulls the project's tasks from the Andamio API, recomputes each `task_hash` locally, and reports mismatches. Requires authentication.

## Your turn

Compute the `task_hash` for a task with these fields:

- Content: `"Review the Module 500 course content"`
- Reward: 25 ADA (25000000 lovelace)
- Expiration: `2026-12-31`
- No native assets

Run the command with `--output json` and paste the result.

Then change the reward to 50 ADA and compute again. Does the hash change?

## Rubric

The hashes are different. The reward amount is part of the encoding — doubling the lovelace produces a completely different hash, just as changing any SLT text produces a different `slt_hash`. If both hashes are identical, check that you actually changed the `--lovelace` value.

## What you just did

You can compute a `task_hash` from task fields and verify it against a published project. You also know how the encoding differs from `slt_hash` — Plutus Data with structured fields vs PlutusTx byte strings — and why that difference exists. This hash is what you'll reference in the next lesson's commitment lifecycle and in M600.4 when you run the full project loop.
