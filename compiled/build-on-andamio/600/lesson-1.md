# How Andamio projects differ from courses

## Before we start

Module 500 covered the course domain end to end. Module 600 does the same for projects. Before you build one, this lesson explains what makes a project different — the treasury, the escrow, the three assessment outcomes, and the economic model that connects them.

## Same bones, different economics

Courses and projects share the transaction state machine from M400 and the same basic shape: an owner creates the thing, a manager/teacher configures it, participants commit, get assessed, and claim credentials. But the economics are different, and the economics drive the protocol differences.

| Dimension | Course | Project |
|-----------|--------|---------|
| **Purpose** | Learning a capability | Contributing funded work |
| **Manager role** | Teacher | Manager |
| **Participant role** | Student | Contributor |
| **Treasury** | None — no on-chain funds | Real ADA locked in an on-chain treasury |
| **Escrow** | None | Task reward locked in escrow until assessment |
| **Deposit** | ~1.45 ADA (enrollment) | ~14.5 ADA (contributor state) |
| **Assessment outcomes** | Accept, Refuse | Accept, Refuse, **Deny** |
| **Credential claim** | Net positive (~1.03 ADA refund) | Net positive (deposit refund + task reward - 5% commission) |
| **Prerequisite** | None by default | Requires a course credential |

## The treasury

A project has an on-chain treasury — real ADA locked in a validator UTxO. The owner funds the treasury at creation or via a separate `treasury_fund` transaction. Task rewards come from this pool.

The treasury isn't a fee. It's the project's budget. When a contributor claims a credential, the task reward transfers from escrow to their wallet. The treasury balance decreases. When all tasks are completed, the remaining treasury can be recovered by the owner.

This is why projects require more ADA up front than courses. Creating a project costs ~112 ADA in service fees and deposits, plus whatever you deposit into the treasury. A course costs ~132 ADA total and has no treasury.

## The escrow

When a manager publishes a task (via `tasks_manage`), the task's reward moves from the treasury to an escrow UTxO. The ADA is locked — neither the manager nor the contributor can touch it until assessment.

- **Accept** → reward transfers from escrow to contributor (minus 5% commission).
- **Refuse** → reward stays in escrow, contributor resubmits.
- **Deny** → reward returns to treasury, contributor is removed.

The escrow is what makes projects trustless. The contributor knows the reward exists before committing. The manager knows the contributor has skin in the game (~14.5 ADA deposit). Neither party has to trust the other — the protocol enforces the deal.

## Three outcomes, not two

Courses have accept and refuse. Projects add **deny**.

| Outcome | Course (M500.4) | Project |
|---------|-----------------|---------|
| **Accept** | Credential earned, deposit refunded | Credential earned, deposit refunded, reward paid |
| **Refuse** | "Try again" — student resubmits | "Try again" — contributor resubmits |
| **Deny** | *Does not exist* | **Terminal** — contributor permanently removed, reward clawed back to treasury |

Why the difference? Courses are about learning. A student who fails deserves another chance. Projects involve real money. A contributor who acts in bad faith (plagiarism, spam, malicious code) needs to be removable, and the treasury needs to recover the reward.

Deny is permanent and irreversible. There's no re-enrollment after a deny. It's the only terminal negative outcome in the Andamio protocol.

## The prerequisite link

Projects can require course credentials as prerequisites. The `course_prereqs` field in the `project_create` body specifies which `slt_hash` values a contributor must hold before committing to a task.

This is the composability from M100.1: a course credential proves the contributor did the learning work. A project can require that proof before handing out funded tasks. The credential is the bridge between the two domains.

## Roles

| Role | Course equivalent | What they can do |
|------|-------------------|-----------------|
| **Owner** | Owner | Create the project, fund the treasury, add/remove managers |
| **Manager** | Teacher | Create tasks, assess contributions, refuse or deny contributors |
| **Contributor** | Student | Commit to tasks, submit evidence, claim credentials and rewards |

The names change because the relationship changes. A teacher teaches. A manager manages funded work. The protocol's permissions are the same shape — the vocabulary reflects the domain.

## Your turn

A team wants to run a hackathon where participants complete tasks for ADA rewards, but they also want participants to have completed an introductory Andamio course first.

1. Which Andamio construct (course or project) is the right fit for the hackathon? Why?
2. What would they put in the `course_prereqs` field?
3. Under what circumstances would a manager use "deny" instead of "refuse"?

Write your answers before checking the rubric.

## Rubric

1. A project — the hackathon has funded tasks with ADA rewards, which requires a treasury. Courses don't have treasuries.
2. The `course_prereqs` would contain the `course_id` and `slt_hash` values from the introductory course's modules. A contributor must hold those credentials to commit to hackathon tasks.
3. Deny is for bad faith: plagiarism, spam, or malicious submissions. Refuse is for honest work that doesn't meet the bar yet. The distinction matters because deny is permanent (contributor removed, reward clawed back) while refuse allows resubmission.

## What you just did

You understand what separates a project from a course: the treasury, the escrow, the three-outcome assessment, and the prerequisite link. Same transaction state machine, different economic model. The treasury makes projects trustless; the escrow makes task rewards enforceable; deny makes bad-faith removal possible.
