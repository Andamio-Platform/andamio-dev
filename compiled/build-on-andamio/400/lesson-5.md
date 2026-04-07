# Which commitment states revert on TX expiry

## Before we start

Last lesson in Module 400. When a transaction expires, what happens to the commitment record it was trying to move forward? Most in-progress states roll back automatically. Two don't, and those two are the ones your code must handle explicitly.

## The problem

A student submits evidence. The `assignment_submit` transaction enters the state machine. The API records the submission as `PENDING_TX_*` while waiting for confirmation. Two hours later: `expired`. The on-chain write never happened.

If the API leaves it in `PENDING_TX_*` forever, the UI shows a broken record. If it rolls back to the pre-submission state, the student can retry cleanly.

The API chose rollback for most cases, with two exceptions.

## The general rule

When a TX expires, the API reverts `PENDING_TX_*` records to their pre-transaction stable state:

- `PENDING_TX_SUBMIT` → reverts to stable pre-submission state. Student/contributor can retry.
- `PENDING_TX_ASSESS` → reverts to `SUBMITTED` or `COMMITTED`. Teacher/manager can retry.
- `PENDING_TX_CLAIM` → reverts to `ACCEPTED`. Claimant can retry.

Clean rollback. No manual intervention.

## The two exceptions

### `PENDING_TX_COMMIT` — no revert

When a student enrolls or a contributor joins for the first time, the API creates a new commitment record. It starts in `PENDING_TX_COMMIT` — **there is no earlier stable state**, because the record didn't exist before.

If the TX expires, the API can't revert (there's nothing to revert to) and won't delete (that would throw away any metadata the user entered, like a reflection or task notes). The record stays in `PENDING_TX_COMMIT`.

**Your code must:** surface a retry action, let the user delete the draft, or periodically sweep stale pending-commit records.

### `PENDING_TX_LEAVE` — no revert

When a student or contributor leaves voluntarily, the record moves to `PENDING_TX_LEAVE`. The intent is to reach `LEFT` or `ABANDONED`. If the TX expires, reverting would restore an active commitment the user explicitly tried to abandon — bad UX, and potentially conflicting with other on-chain activity in the 2-hour window.

The record stays in `PENDING_TX_LEAVE`.

**Your code must:** let the user retry the leave with a fresh TX, or explicitly re-enroll if they changed their mind.

## Summary table

| Pending state | On TX expiry |
|---|---|
| `PENDING_TX_COMMIT` | **No revert** — stays pending, manual resolution required |
| `PENDING_TX_SUBMIT` | Reverts to pre-submission stable state |
| `PENDING_TX_ASSESS` | Reverts to `SUBMITTED` (assignments) or `COMMITTED` (tasks) |
| `PENDING_TX_CLAIM` | Reverts to `ACCEPTED` |
| `PENDING_TX_LEAVE` | **No revert** — stays pending, manual resolution required |

The two exceptions: COMMIT has no pre-transaction state to revert to. LEAVE would undo an intentional user action.

## What this means for your code

**Defensive pattern:** after any expired TX, fetch the record and read its current state before deciding what to do. Don't assume.

- **Auto-reverted states** (SUBMIT, ASSESS, CLAIM): the API already cleaned up. Show the user where the record is now. They can retry immediately.
- **Dangling states** (COMMIT, LEAVE): the record is still pending. Let the user retry or explicitly abandon.

## Your turn

1. **A student submits evidence on an existing assignment, and the TX expires.** What state is the record in? What can the app do?
2. **A student tries to enroll for the first time (a commit TX), and the TX expires.** What state is the record in? Why is this different?

## Rubric

1. The record reverts to its pre-submission stable state. The app refreshes and the user retries — no special handling needed.
2. The record is in `PENDING_TX_COMMIT` and stays there. There was no pre-transaction state to revert to. The app must let the user retry or delete the dangling record. The difference: question 1 had a baseline to revert to; question 2 didn't.

## What you just did

You know the general rule (pending states revert) and the two exceptions (`PENDING_TX_COMMIT` and `PENDING_TX_LEAVE`). Module 400 is complete: five steps, five statuses, five failure modes, two non-reverting states. That's every edge case the transaction lifecycle can throw at you.

You also unlocked `/troubleshoot` in Ops Mode — a shortcut for the diagnostic workflow from M400.4 and M400.5. You know what it does under the hood.
