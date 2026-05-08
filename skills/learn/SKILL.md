---
name: learn
description: "Learn to build on Andamio — take the course, get lessons delivered, do exercises, submit assignments, and track progress across 7 modules (31 SLTs). Use when the learner says 'learn', 'start the course', 'teach me', 'next lesson', 'continue', 'where am I', 'submit my assignment', 'what module am I on', or anything about learning or progressing through the Build on Andamio course. Also handles: resume, go back, skip ahead, review a lesson, retake an assignment, check progress, restart."
license: MIT
metadata:
  author: Andamio
  version: 0.2.0
---

# Skill: Learn

Manage the learner's journey through the "Build on Andamio" course. Track progress, deliver lessons, assess assignments, and enforce module gating.

This skill is agent-neutral. In Claude Code it may be paired with specialized agents, but in Codex and other single-agent environments, execute the same workflow inline:

- use `skills/deliver-lesson/SKILL.md` as the teaching protocol
- use `skills/assess-assignment/SKILL.md` as the assessment protocol
- read and update `progress.json` directly
- do not depend on `.claude/agents/*` or Claude `Agent(...)` calls

## Path Resolution

- Plugin context (`${CLAUDE_PLUGIN_ROOT}` is set): read course content from `${CLAUDE_PLUGIN_ROOT}/courses/`; write learner state to `${CLAUDE_PLUGIN_DATA}/progress.json` when `${CLAUDE_PLUGIN_DATA}` is set.
- Clone/symlink context: read course content from `courses/` and write learner state to `./progress.json` at the project root.

Read `skills/learn/references/progress-schema.md` for the progress schema.

## Course Structure

7 modules, sequential gating. Each module unlocks the next.

| Module | Name | Lessons |
| --- | --- | --- |
| 100 | Foundations | 100.1-100.4 + assignment |
| 200 | Identity | 200.1-200.4 + assignment |
| 300 | Reading Andamio | 300.1-300.4 + assignment |
| 400 | TX State Machine | 400.1-400.5 + assignment |
| 500 | Courses End-to-End | 500.1-500.5 + assignment |
| 600 | Projects End-to-End | 600.1-600.4 + assignment |
| 700 | Build Something Real | 700.1-700.5 + assignment |

Lesson files live at `courses/build-on-andamio/lessons/m{N}/`.
The canonical SLT list is `courses/build-on-andamio/01-slts.md`.

## Workflow

### Phase 0: Context Check

1. Determine progress file location.
2. Read `progress.json` if it exists.
3. If missing, initialize it using the schema in `skills/learn/references/progress-schema.md`.
4. If present but missing newer schema fields, migrate it in place without losing learner state.
5. Determine learner intent:
   - first run or "start the course": initialize and deliver M100.1
   - "next lesson" or "continue": deliver the next incomplete lesson
   - "lesson 100.2" or "review 100.2": deliver that lesson if allowed
   - "submit assignment": verify module lesson completion, then assess evidence
   - "where am I" or "progress": summarize progress
   - "restart": ask for confirmation before resetting progress

### Phase 1: Progress Initialization

When creating `progress.json`, use these modules and lesson inventories:

```json
{
  "100": ["100.1", "100.2", "100.3", "100.4"],
  "200": ["200.1", "200.2", "200.3", "200.4"],
  "300": ["300.1", "300.2", "300.3", "300.4"],
  "400": ["400.1", "400.2", "400.3", "400.4", "400.5"],
  "500": ["500.1", "500.2", "500.3", "500.4", "500.5"],
  "600": ["600.1", "600.2", "600.3", "600.4"],
  "700": ["700.1", "700.2", "700.3", "700.4", "700.5"]
}
```

Initial state:
- M100 status: `unlocked`
- M200-M700 status: `locked`
- all lessons: `not_started`
- all assignments: `not_submitted`
- `current_module`: `100`
- `current_lesson`: `"100.1"`

Update `last_active` whenever progress changes.

### Phase 1b: Legacy Progress Migration

Older progress files may be missing `version`, `started_at`, `last_active`, `started_at` per module, or `completed_at` per module. They may also use `locked` as a lesson or assignment status.

Handle legacy progress conservatively:

- Add `version: 1` if missing.
- Add `started_at` and `last_active` with the current timestamp if missing.
- Add missing module metadata fields without changing completed work.
- Keep `completed` lesson and `accepted` assignment statuses as-is.
- For lessons in unlocked or in-progress modules, treat `locked` as `not_started` except lessons gated by sequential order.
- For assignments in unlocked or in-progress modules, treat `locked` as `not_submitted` once all module lessons are complete.
- For modules that remain locked, lesson-level `locked` is acceptable for display, but normalize to `not_started` when the module unlocks.

Tell the learner only if migration changes the file. Keep the note brief.

### Phase 2: Route

| Intent | Action |
| --- | --- |
| Start course | Initialize progress if needed, then deliver `100.1` |
| Continue / next lesson | Find next incomplete lesson in the first unlocked or in-progress module |
| Specific lesson | Check gating, then deliver requested lesson |
| Review completed lesson | Deliver requested lesson without changing gating |
| Submit assignment | Require all lessons in the module completed, collect evidence, assess |
| Check progress | Show module status, current lesson, and next action |

### Phase 3: Deliver Lesson Inline

Read `skills/deliver-lesson/SKILL.md`, then:

1. Find the requested lesson file by module directory and SLT prefix.
2. Read the full lesson file.
3. Mark the lesson `in_progress` before delivery if it was `not_started`.
4. Teach the lesson section by section.
5. Guide the "Your turn" exercise.
6. Ask whether the learner completed the exercise when completion is ambiguous.
7. If complete, mark the lesson `completed` and advance `current_lesson`.
8. If partial, leave the lesson `in_progress`.

Do not dump the whole lesson file. Teach it conversationally and preserve the lesson's intent.

### Phase 4: Assess Assignment Inline

Read `skills/assess-assignment/SKILL.md`, then:

1. Identify the current or requested module.
2. Check that every lesson in the module is `completed`.
3. If lessons remain, list them and offer to deliver the next one.
4. Read `courses/build-on-andamio/lessons/m{N}/assignment.md`.
5. Read `courses/build-on-andamio/01-slts.md`.
6. Ask the learner to paste evidence if it is not already provided.
7. Evaluate evidence per SLT and return the structured assessment.
8. If module verdict is `Accept`, mark assignment `accepted`, module `completed`, unlock the next module, and move `current_lesson` to the first lesson of the next module.
9. If module verdict is `Revise`, mark assignment `revision_requested` and do not unlock the next module.

## Module Gating Rules

- M100 is always unlocked.
- M200-M700 unlock only after the previous module assignment is accepted.
- Within a module, lessons are sequential: lesson N+1 unlocks after lesson N is completed.
- Reviewing a completed lesson is always allowed.
- Do not skip ahead unless the learner explicitly asks and understands that progress state will still enforce assignment gating.

## Progress Summary Format

When asked "where am I?", respond with:

```markdown
## Build on Andamio Progress

Current module: M{N} — {name}
Current lesson: {lesson}

| Module | Status | Lessons | Assignment |
| --- | --- | --- | --- |
| M100 | in_progress | 2/4 complete | not_submitted |

Next step: {specific next action}
```

## Operational Skill Integration

After each module completion, mention the skills that are now contextually relevant:

| Module Completed | Skills Now Contextual |
| --- | --- |
| M100 | `orientation`, `start` |
| M200 | `auth-setup` |
| M300 | `explore-api` |
| M400 | `troubleshoot`, `cost-estimator` |
| M500 | `course-ops` |
| M600 | `project-ops` |
| M700 | all skills |

## Error Handling

| Situation | Strategy |
| --- | --- |
| `progress.json` corrupted or invalid | Back up the broken file, initialize fresh, and tell the learner. |
| Lesson file missing | Report the missing file and do not mark progress. |
| Assignment file missing | Report the missing file and do not assess. |
| Unclear assessment verdict | Default to `Revise` and ask for clearer evidence. |
| Locked module requested | Explain gating and show what must be completed first. |
| CLI/API error during exercise | Use `troubleshoot` guidance and keep teaching the diagnostic process. |

## Direct Invocation Examples

Learner says:

```text
Start the course.
```

Action:
- initialize progress if missing
- deliver `100.1`

Learner says:

```text
Teach me lesson 300.2.
```

Action:
- check M300 is unlocked unless this is explicitly a review/preview
- deliver `courses/build-on-andamio/lessons/m300/300.2-*.md`

Learner says:

```text
Submit my M100 assignment.
```

Action:
- ensure `100.1` through `100.4` are complete
- collect evidence
- assess inline using `assess-assignment`
