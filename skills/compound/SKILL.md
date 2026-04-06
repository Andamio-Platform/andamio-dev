---
name: compound
description: Extract patterns from developer sessions into knowledge files. Captures gotchas, FAQ, endpoint usage, and cost scenarios.
license: MIT
metadata:
  author: Andamio
  version: 0.1.0
---

# Skill: Compound Knowledge

## Description

Extracts patterns from developer interaction sessions and writes them to the knowledge base. Makes each session smarter than the last by capturing gotchas, FAQ, endpoint usage patterns, and cost scenarios.

## Invocation Modes

```
/compound                    # Interactive: asks what to compound
/compound gotchas            # Compound gotchas from this session
/compound faq                # Compound FAQ entries
/compound costs              # Compound cost scenarios
/compound --rollup           # Full session retrospective
```

## Instructions

### Path Resolution

- **Plugin context** (`${CLAUDE_PLUGIN_ROOT}` is set): Read knowledge from `${CLAUDE_PLUGIN_DATA}/knowledge/` (user data), falling back to `${CLAUDE_PLUGIN_ROOT}/knowledge/` (seed data). **Write all updates to `${CLAUDE_PLUGIN_DATA}/knowledge/`** — never modify the plugin's bundled seed data.
- **Clone/symlink context** (default): Read and write knowledge at `knowledge/` relative to project root.

All `knowledge/` paths below follow this resolution.

### Phase Selection

If invoked without arguments, present options:

```
What would you like to compound from this session?

| # | Phase | Source | Extracts |
|---|-------|--------|----------|
| 1 | gotchas | Errors encountered + fixes applied | Error patterns, root causes, verified fixes |
| 2 | faq | Questions asked + answers given | Question-answer pairs by category |
| 3 | endpoints | API endpoints used | Usage patterns, context, gotchas per endpoint |
| 4 | costs | Cost calculations performed | Scenario inputs, breakdowns, totals |
| 5 | rollup | Everything above | Full session retrospective |

Which phase?
```

### Extraction Logic by Phase

#### Phase: gotchas

**Source:** Errors encountered during this session and their resolutions.

**Extract for each new error pattern:**
```yaml
- id: gotcha-NNN
  error_pattern: "exact error text or pattern"
  root_cause: "why this happens"
  fix: "what to do about it"
  category: auth | cli | transactions | content | rate-limits | network
  frequency: 1
  confirmed: true
```

**Rules:**
- Check if a matching gotcha already exists. If so, increment `frequency` instead of duplicating.
- Only capture errors that were actually resolved — don't add unresolved issues.
- The `fix` must be a concrete action, not "investigate further."

Append to `knowledge/gotchas.yaml`.

#### Phase: faq

**Source:** Questions the developer asked and answers that were helpful.

**Extract for each new FAQ:**
```yaml
- id: faq-NNN
  question: "the question as asked"
  answer: "the answer that worked"
  category: getting-started | auth | costs | architecture | environments | transactions | cli | content
  frequency: 1
```

**Rules:**
- Generalize questions (replace specific IDs with placeholders).
- Only capture questions that would be useful to other developers.
- Check for existing FAQ entries that cover the same topic.

Append to `knowledge/faq.yaml`.

#### Phase: endpoints

**Source:** API endpoints used during this session.

**Extract for each endpoint used in a notable way:**
```yaml
- id: endpoint-NNN
  endpoint: "GET /v2/course/user/courses/list"
  method: GET
  context: "when and why a developer would use this"
  gotchas: "anything surprising about this endpoint"
  frequency: 1
```

Append to `knowledge/endpoint-usage.yaml`.

#### Phase: costs

**Source:** Cost calculations performed during this session.

**Extract:**
```yaml
- id: cost-NNN
  scenario: "course with 3 teachers and 10 modules, 50 students"
  inputs:
    teachers: 3
    modules: 10
    students: 50
    assignments_per_student: 5
  breakdown:
    setup: 158.15
    operational: 190.50
    recoverable: 51.50
  total_ada: 348.65
  cost_per_user: 3.81
  timestamp: "2026-03-23"
```

Append to `knowledge/cost-scenarios.yaml`.

#### Phase: rollup

Run all extraction phases. Produce a summary report:

```
## Compound Report

### Knowledge Captured

| Category | New Entries | Updated | Files Modified |
|----------|-----------|---------|---------------|
| Gotchas | 2 | 1 | gotchas.yaml |
| FAQ | 3 | 0 | faq.yaml |
| Endpoints | 4 | 0 | endpoint-usage.yaml |
| Cost Scenarios | 1 | 0 | cost-scenarios.yaml |

### Aggregate Stats Update

- Sessions processed: [n]
- Total gotchas: [n]
- Total FAQ entries: [n]
- Total endpoint patterns: [n]
- Total cost scenarios: [n]

### Top Insights

1. [Most impactful pattern from this session]
2. [Second most impactful]
```

### Output Format

After extraction, always report:

```
## Compound Complete

**Phase:** [phase name]

### Extracted

| Knowledge Type | Count | Status |
|----------------|-------|--------|
| [type] | [n] | Added / Updated / Unchanged |

### Files Modified

- `knowledge/gotchas.yaml` - Added 2 entries
- `knowledge/index.yaml` - Updated stats

### Index Updated

- `last_updated`: [today]
- `sessions_processed`: [new total]
```

### Knowledge Consumption Check

Before modifying knowledge files, read the current state. When updating:
- **Increment counts** (don't reset)
- **Append to entries** (don't overwrite)
- **Merge patterns** (same error from different sessions = one entry with higher frequency)
- **Deduplicate** (check existing entries before adding)

### Integration Points

This skill produces knowledge that other skills consume:

| Skill | Reads From | Uses For |
|-------|------------|----------|
| `/troubleshoot` | gotchas.yaml | Known error patterns and verified fixes |
| `/explore-api` | endpoint-usage.yaml | Usage context and gotchas per endpoint |
| `/cost-estimator` | cost-scenarios.yaml | Reference scenarios for estimation |
| `/start` | faq.yaml | Common developer questions |

### Guidelines

- **Always read before writing.** Load current YAML state before appending.
- **Preserve existing data.** Never overwrite — merge and increment.
- **Be specific in patterns.** Vague patterns don't compound.
- **Update the index.** Always update `knowledge/index.yaml` stats after any extraction.
- **Report what changed.** The developer should see exactly what knowledge was captured.
- **Only compound verified knowledge.** Don't capture speculative fixes or unresolved errors.
