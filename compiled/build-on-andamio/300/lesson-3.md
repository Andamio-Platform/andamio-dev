# Query a user's Andamio credentials

## Before we start

The most common read in Andamio integrations: fetching a user's credentials and interpreting what the response says. By the end you can answer "which courses has this user completed?" and "which modules has this user earned credit for?" for any alias on the protocol.

## The endpoint

`POST /v2/course/student/credentials/list`

POST for a read — same pattern from M300.2. The body tells the endpoint which user to query. Auth: API key required; User JWT optional (needed if querying another alias).

## The CLI shortcut

```bash
andamio course student credentials list --output json
```

Defaults to the logged-in alias. Pass `--alias someone-else` to query a different user. If you haven't enrolled in any courses yet, the `data` array will be empty — that's fine, the response still shows the shape.

## The response shape

```json
{
  "data": [
    {
      "course_id": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0",
      "course_title": "Introduction to Cardano Development",
      "is_enrolled": true,
      "enrollment_status": "enrolled",
      "claimed_credentials": [
        "8a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0"
      ],
      "modules": [
        {
          "slt_hash": "8a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0",
          "module_code": "100",
          "title": "Wallets and Keys",
          "status": "ON_CHAIN"
        },
        {
          "slt_hash": "c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0",
          "module_code": "200",
          "title": "Building a Simple Transaction",
          "status": "ON_CHAIN"
        }
      ],
      "source": "merged"
    }
  ],
  "meta": null
}
```

| Field | Type | Meaning |
|-------|------|---------|
| `course_id` | 56-char hex | On-chain policy ID — the course's stable identifier. Save this if you store course data. |
| `course_title` | string | Off-chain. May be missing if `source` is `chain_only`. |
| `is_enrolled` | bool | User has committed to at least one module (doesn't imply completion). |
| `enrollment_status` | enum | `"enrolled"` = active commitments. `"completed"` = all credentials claimed. Treat unknown values as `enrolled`. |
| `claimed_credentials` | array of `slt_hash` | Modules the user has earned credentials for. Empty = none yet. |
| `modules` | array | Course modules with off-chain metadata + on-chain `slt_hash`. |
| `source` | string | From M300.1. Read first. `merged` is the normal case. |

## Interpreting the example

User is enrolled in "Introduction to Cardano Development." Two modules exist. The first `slt_hash` in `modules` matches the entry in `claimed_credentials` — Module 100 is claimed. Module 200 is not. A UI would render: "Wallets and Keys: claimed, Building a Simple Transaction: in progress."

One API call gives you both the course structure and the user's progress through it.

## Joining modules to claimed_credentials

The `slt_hash` is the join key. To determine per-module completion:

```javascript
const claimedSet = new Set(course.claimed_credentials);

for (const module of course.modules) {
  const isClaimed = claimedSet.has(module.slt_hash);
  console.log(`${module.title}: ${isClaimed ? "claimed" : "not claimed"}`);
}
```

Or in shell:

```bash
andamio course student credentials list --output json \
  | jq -r '.data[] | . as $course
           | $course.modules[]
           | "\(.title): \(if ($course.claimed_credentials | index(.slt_hash)) then "claimed" else "not claimed" end)"'
```

The response is designed to answer "which modules has this user completed?" without a second API call.

## Your turn

```bash
andamio course student credentials list --output json
```

1. Are you enrolled in any courses? Name them (or note the empty array).
2. For each course, how many modules exist vs. how many have claimed credentials?
3. What's the `source` value, and does it match expectations?

## Rubric

No single correct answer. A good answer:

1. Correctly identifies enrolled courses (or reports the expected empty array for a fresh alias).
2. Compares `modules` against `claimed_credentials` and reports per-module status.
3. Reports `source` and explains whether it makes sense.

If you can explain your own response without guessing, you've got it.

## What you just did

You called a real endpoint, parsed the response, and saw the join pattern between `modules` and `claimed_credentials` via `slt_hash`. Every Andamio read response follows this shape: entities with on-chain identifiers and off-chain metadata, joined by hashes.
