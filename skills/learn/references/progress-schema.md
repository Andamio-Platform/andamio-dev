# Progress Schema

## File Location

- Plugin context: `${CLAUDE_PLUGIN_DATA}/progress.json` when available, otherwise `${CLAUDE_PLUGIN_ROOT}/progress.json` is not used for writes.
- Clone/symlink context: `./progress.json` at the project root.

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
    }
  }
}
```

## Status Values

Module status:
- `locked`
- `unlocked`
- `in_progress`
- `completed`

Lesson status:
- `not_started`
- `in_progress`
- `completed`

Assignment status:
- `not_submitted`
- `submitted`
- `revision_requested`
- `accepted`

## Initialization

On first run:
- M100 status is `unlocked`
- M200-M700 status is `locked`
- all lessons are `not_started`
- all assignments are `not_submitted`
- `current_module` is `100`
- `current_lesson` is `100.1`

## Lesson Inventory

| Module | Lessons |
| --- | --- |
| 100 | 100.1, 100.2, 100.3, 100.4 |
| 200 | 200.1, 200.2, 200.3, 200.4 |
| 300 | 300.1, 300.2, 300.3, 300.4 |
| 400 | 400.1, 400.2, 400.3, 400.4, 400.5 |
| 500 | 500.1, 500.2, 500.3, 500.4, 500.5 |
| 600 | 600.1, 600.2, 600.3, 600.4 |
| 700 | 700.1, 700.2, 700.3, 700.4, 700.5 |

