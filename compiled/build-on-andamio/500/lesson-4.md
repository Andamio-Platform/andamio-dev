# The course assignment commitment lifecycle

## Before we start

Modules are on-chain. Content is published. A student is ready to enroll. What happens between enrollment and credential? This lesson describes the states a course assignment passes through — the commitment lifecycle. If M400 was about individual transactions, this lesson is about the arc those transactions trace.

## The states

A course assignment commitment moves through these states:

```
AWAITING_SUBMISSION → SUBMITTED → ACCEPTED → credential claimed
                               → REFUSED → AWAITING_SUBMISSION (retry)
```

Each arrow is a transaction that goes through the five-step state machine from M400.

| State | Set by | What it means |
|-------|--------|--------------|
| `AWAITING_SUBMISSION` | Student creates commitment (off-chain) | Student is enrolled but hasn't submitted evidence yet |
| `SUBMITTED` | Student's `assignment_submit` TX reaches `updated` | Evidence is on-chain, waiting for teacher review |
| `ACCEPTED` | Teacher's `assessment_assess` TX reaches `updated` | Teacher approved the evidence. Student can claim credential. |
| `REFUSED` | Teacher's `assessment_assess` TX reaches `updated` | Teacher rejected the evidence. Student can resubmit. |

## Two outcomes, not three

Course assignments have two assessment outcomes: **accept** and **refuse**.

- **Accept** means the evidence meets the SLT criteria. The student can claim a credential.
- **Refuse** means "try again." The commitment reverts to `AWAITING_SUBMISSION` and the student can submit new evidence. There's no penalty and no limit on resubmissions.

There is no "deny" for course assignments. A teacher can refuse indefinitely, but can't permanently remove a student from a module. This is deliberate — courses are about learning, and a student who hasn't met the bar yet is a student who needs another attempt, not expulsion.

Projects are different. M600 introduces the third outcome: **deny**, which is terminal. The distinction matters, and it maps to the difference between learning and contribution.

## Off-chain before on-chain

Before the `assignment_submit` transaction, the student creates a commitment record off-chain:

```bash
andamio course student commitment create \
  --course-id "$COURSE_ID" \
  --module-code 100
```

This creates an `AWAITING_SUBMISSION` record in the Andamio API. Without it, the enrollment transaction fails — the API's batch confirm looks for an off-chain record to match the on-chain state, and returns 404 without one.

The module must have assignment content before this command succeeds. If the teacher published the module on-chain (M500.3) but hasn't imported content yet, students can't create commitments.

## The pending states

Between stable states, records pass through `PENDING_TX_*` states while waiting for on-chain confirmation. From M400.5:

| Transition | Pending state | On TX expiry |
|-----------|--------------|--------------|
| First enrollment | `PENDING_TX_COMMIT` | **No revert** — no prior state exists |
| Submit evidence | `PENDING_TX_SUBMIT` | Reverts to `AWAITING_SUBMISSION` |
| Teacher assesses | `PENDING_TX_ASSESS` | Reverts to `SUBMITTED` |
| Claim credential | `PENDING_TX_CLAIM` | Reverts to `ACCEPTED` |

The `PENDING_TX_COMMIT` exception is the one from M400.5 — a first-time enrollment creates a new record, so there's nothing to revert to if the TX expires.

## Batch assessment

A teacher doesn't assess one student at a time. The `assessment_assess` transaction accepts an `assignment_decisions` array:

```json
{
  "assignment_decisions": [
    {"alias": "alice", "outcome": "accept"},
    {"alias": "bob", "outcome": "refuse"},
    {"alias": "carol", "outcome": "accept"}
  ]
}
```

One transaction, multiple students, mixed outcomes. This is how real courses work — a teacher reviews a cohort and submits all decisions in a single on-chain write.

## The full picture

```
Off-chain: student creates commitment
  → AWAITING_SUBMISSION

On-chain: assignment_submit (student)
  → SUBMITTED

On-chain: assessment_assess (teacher)
  → ACCEPTED (student can claim)
  → REFUSED  (student retries → AWAITING_SUBMISSION)

On-chain: credential_claim (student)
  → credential NFT in wallet
```

Four roles for three transactions. The teacher never touches the enrollment or claim — those are student-initiated. The student never touches the assessment — that's the teacher's decision. Separation of concerns, enforced by the protocol.

## Your turn

1. A student submits evidence. The teacher refuses it. What state is the commitment in, and what can the student do next?
2. Why does Andamio use two outcomes (accept/refuse) for course assignments instead of three? What would a "deny" outcome mean for a learning context?

Write your answers before checking the rubric.

## Rubric

1. After a refuse, the commitment is back in `AWAITING_SUBMISSION`. The student submits new or revised evidence with another `assignment_submit` transaction. No limit on retries.
2. Two outcomes because courses are about learning — a student who hasn't met the bar needs another attempt, not expulsion. A "deny" would permanently bar the student from earning a credential for that module. Projects use deny because contributions involve treasury funds and teams can't afford indefinite retry loops. The domain difference (learning vs paid work) drives the outcome set.

## What you just did

You understand the arc from enrollment to credential: the four stable states, the two assessment outcomes, the off-chain prerequisite, and batch assessment. You also know why courses have two outcomes where projects will have three — the domain shapes the protocol.
