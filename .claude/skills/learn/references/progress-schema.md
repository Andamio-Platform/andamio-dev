# Progress Schema

## File Location

- Plugin context: `${CLAUDE_PLUGIN_DATA}/progress.json`
- Clone context: `./progress.json` (project root)

## Schema

```json
{
  "version": 1,
  "course": "build-on-andamio",
  "started_at": "2026-04-05T10:00:00Z",
  "last_active": "2026-04-05T14:30:00Z",
  "current_module": 100,
  "current_lesson": "100.3",
  "modules": {
    "100": {
      "status": "in_progress",
      "started_at": "2026-04-05T10:00:00Z",
      "completed_at": null,
      "lessons": {
        "100.1": "completed",
        "100.2": "completed",
        "100.3": "in_progress",
        "100.4": "not_started"
      },
      "assignment": "not_submitted"
    },
    "200": {
      "status": "locked",
      "started_at": null,
      "completed_at": null,
      "lessons": {
        "200.1": "not_started",
        "200.2": "not_started",
        "200.3": "not_started",
        "200.4": "not_started"
      },
      "assignment": "not_submitted"
    }
  }
}
```

## Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `version` | number | Schema version. Currently 1. |
| `course` | string | Course slug. Always `build-on-andamio`. |
| `started_at` | ISO 8601 | When the learner first started the course |
| `last_active` | ISO 8601 | Last interaction timestamp. Update on every state change. |
| `current_module` | number | Module the learner is currently working on (100–700) |
| `current_lesson` | string | SLT number of the current/next lesson (e.g., "100.3") |

## Module Status Values

| Status | Meaning |
|--------|---------|
| `locked` | Prerequisites not met. Cannot access. |
| `unlocked` | Prerequisites met. Not started. |
| `in_progress` | At least one lesson started. |
| `completed` | Assignment accepted by assessor. |

## Lesson Status Values

| Status | Meaning |
|--------|---------|
| `not_started` | Lesson not yet delivered |
| `in_progress` | Lesson started but "Your turn" not completed |
| `completed` | Lesson fully delivered including "Your turn" |

## Assignment Status Values

| Status | Meaning |
|--------|---------|
| `not_submitted` | No submission yet |
| `submitted` | Evidence submitted, awaiting assessment |
| `revision_requested` | Assessor asked for revision |
| `accepted` | Assessor accepted — module complete |

## Initialization

On first run, create progress.json with:
- M100 status: `unlocked`
- M200–M700 status: `locked`
- All lessons: `not_started`
- All assignments: `not_submitted`
- `current_module`: 100
- `current_lesson`: "100.1"

## Lesson Inventory per Module

Used to initialize and validate progress:

| Module | Lessons |
|--------|---------|
| 100 | 100.1, 100.2, 100.3, 100.4 |
| 200 | 200.1, 200.2, 200.3, 200.4 |
| 300 | 300.1, 300.2, 300.3, 300.4 |
| 400 | 400.1, 400.2, 400.3, 400.4, 400.5 |
| 500 | 500.1, 500.2, 500.3, 500.4, 500.5 |
| 600 | 600.1, 600.2, 600.3, 600.4 |
| 700 | 700.1, 700.2, 700.3, 700.4, 700.5 |
