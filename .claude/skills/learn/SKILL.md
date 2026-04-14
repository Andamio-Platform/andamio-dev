---
name: learn
description: "Learn to build on Andamio — take the course, get lessons delivered, do exercises, submit assignments, and track progress across 7 modules (31 SLTs). Use when the learner says 'learn', 'start the course', 'teach me', 'next lesson', 'continue', 'where am I', 'submit my assignment', 'what module am I on', or anything about learning or progressing through the Build on Andamio course. Also handles: resume, go back, skip ahead, review a lesson, retake an assignment, check progress, restart. Do NOT use for general Andamio API questions — those go to /explore-api or /cli-guide."
---

# Build on Andamio — Course Orchestrator

Manage the learner's journey through the "Build on Andamio" course. Track progress, route to the instructor for lessons or assessor for assignments, enforce module gating.

## Execution Mode: Sub-agent

Two agents, called as needed:

| Agent | subagent_type | Role | Skill | When |
|-------|--------------|------|-------|------|
| instructor | instructor | Deliver lessons, guide exercises | deliver-lesson | Learner is working through a lesson |
| assessor | assessor | Evaluate module assignments | assess-assignment | Learner submits assignment evidence |

Both agents use `model: "opus"`.

## Course Structure

7 modules, sequential gating. Each module unlocks the next.

| Module | Name | SLTs | Lessons Available |
|--------|------|------|-------------------|
| 100 | Foundations | 4 | Yes (M100.1–M100.4 + assignment) |
| 200 | Identity | 4 | Yes (M200.1–M200.4 + assignment) |
| 300 | Reading Andamio | 4 | Yes (M300.1–M300.4 + assignment) |
| 400 | TX State Machine | 5 | Yes (M400.1–M400.5 + assignment) |
| 500 | Courses End-to-End | 5 | Yes (M500.1–M500.5 + assignment) |
| 600 | Projects End-to-End | 4 | Yes (M600.1–M600.4 + assignment) |
| 700 | Build Something Real | 5 | Yes (M700.1–M700.5 + assignment) |

Lesson files: `courses/build-on-andamio/lessons/m{N}/`
SLT list: `courses/build-on-andamio/01-slts.md`

## Workflow

### Phase 0: Context Check

1. Determine progress file location:
   - Plugin context: `${CLAUDE_PLUGIN_DATA}/progress.json`
   - Clone context: `./progress.json` (project root)
2. Read progress.json if it exists
3. Determine execution mode:
   - **No progress file** → First run. Initialize progress, start course introduction.
   - **Progress exists** → Returning learner. Show where they left off, ask how to continue.
   - **Learner requests specific action** ("next lesson", "submit assignment", "check progress") → Route directly.

### Phase 1: Route

Based on learner intent:

| Intent | Action |
|--------|--------|
| "Start the course" / first run | Initialize progress → deliver M100.1 |
| "Next lesson" / "Continue" | Read progress → deliver next incomplete lesson |
| "Lesson {N}.{M}" / specific lesson | Check prerequisites → deliver requested lesson |
| "Submit assignment" / "I'm ready" | Check all module lessons complete → launch assessor |
| "Where am I" / "Progress" | Show progress summary |
| "Go back" / "Review {lesson}" | Deliver requested lesson (no gating for review) |

### Phase 2: Deliver Lesson (via instructor agent)

Launch the instructor agent:

```
Agent(
  subagent_type: "instructor",
  model: "opus",
  prompt: "You are the instructor for the Build on Andamio course.
    Read .claude/skills/deliver-lesson/SKILL.md for pedagogy instructions.
    
    Deliver lesson {slt} to the learner.
    Lesson file: courses/build-on-andamio/lessons/m{N}/{slt}-{slug}.md
    
    Learner context: {summary from progress.json — what they've completed, current module}
    
    After delivering the lesson and completing the 'Your turn' section, report back:
    - Did the learner complete the lesson? (yes/no/partial)
    - Any notes on learner level or issues encountered"
)
```

After instructor returns: update progress.json with lesson completion.

### Phase 3: Assess Assignment (via assessor agent)

Pre-check: verify all lessons in the module are marked complete in progress.json. If not, tell the learner which lessons remain.

Collect the learner's evidence. Then launch the assessor:

```
Agent(
  subagent_type: "assessor",
  model: "opus",
  prompt: "You are the assessor for the Build on Andamio course.
    Read .claude/skills/assess-assignment/SKILL.md for assessment instructions.
    
    Evaluate Module {N} assignment.
    Assignment file: courses/build-on-andamio/lessons/m{N}/assignment.md
    SLT list: courses/build-on-andamio/01-slts.md
    
    Learner's evidence:
    {paste learner's submitted evidence}
    
    Return structured assessment with per-SLT verdicts and module verdict (Accept/Revise)."
)
```

After assessor returns:
- **Accept** → Update progress.json (module completed, next module unlocked). Tell the learner. Mention which plugin skills are now contextually relevant.
- **Revise** → Show the assessor's feedback. Tell the learner what to improve. Don't update progress.

### Phase 4: Progress Update

Write progress.json after any state change. Schema in `references/progress-schema.md`.

Key transitions:
- Lesson completed → `modules.{N}.lessons.{slt}: "completed"`
- Module accepted → `modules.{N}.status: "completed"`, next module status → `"unlocked"`
- `current_module` and `current_lesson` always reflect the learner's position

## Module Gating Rules

- M100: Always unlocked (entry point)
- M200–M700: Unlocked only when the previous module's assignment is accepted
- Within a module, lessons are sequential: lesson N+1 unlocks after lesson N is completed
- Exception: reviewing a completed lesson is always allowed regardless of gating

## Plugin Skills Integration

After each module completion, mention the newly relevant operational skills:

| Module Completed | Skills Now Contextual |
|------------------|-----------------------|
| M100 | `/orientation` (if not done), `/start` |
| M200 | `/auth-setup` |
| M300 | `/explore-api` |
| M400 | `/troubleshoot`, `/cost-estimator` |
| M500 | `/course-ops` |
| M600 | `/project-ops` |
| M700 | All skills — full operational access |

## Error Handling

| Situation | Strategy |
|-----------|----------|
| progress.json corrupted/invalid | Back up the broken file, initialize fresh, tell the learner |
| Lesson file missing | Report the gap. All seven modules should have lesson files at `courses/build-on-andamio/lessons/m{N}/`. |
| Assessor returns unclear verdict | Default to Revise, ask learner to resubmit with clearer evidence |
| Learner requests module they haven't unlocked | Explain gating, show what they need to complete first |

## Test Scenarios

### Normal Flow
1. Learner says "Start the course"
2. No progress.json exists → initialize
3. Route to instructor for M100.1
4. Instructor delivers lesson, learner completes "Your turn"
5. Update progress: M100.1 completed
6. Learner says "next" → deliver M100.2
7. After M100.4, learner says "submit assignment"
8. Pre-check: all 4 lessons complete → launch assessor
9. Assessor accepts → M100 completed, M200 unlocked
10. Learner says "continue" → deliver M200.1

### Error Flow
1. Learner says "submit M200 assignment"
2. Progress shows M200.3 not completed
3. Tell learner: "You still need to complete lesson 200.3 before submitting the assignment."
4. Offer to deliver M200.3
