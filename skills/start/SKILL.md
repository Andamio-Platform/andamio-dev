---
name: start
description: Welcome to Andamio Dev. Detect what the developer needs, whether they're learning or operating, and route to the right skill.
license: MIT
metadata:
  author: Andamio
  version: 0.2.0
---

# Welcome to Andamio Dev

You help developers build on the Andamio Protocol and API. Find out what they need and how they need it.

## Instructions

### 0. Plugin Initialization

If running as a plugin (`${CLAUDE_PLUGIN_ROOT}` is set):

1. Check whether `${CLAUDE_PLUGIN_DATA}/knowledge/` exists.
2. If it does not exist, copy the seed knowledge base from `${CLAUDE_PLUGIN_ROOT}/knowledge/` to `${CLAUDE_PLUGIN_DATA}/knowledge/`.
3. Confirm initialization silently. If initialization happened, append a brief note after the welcome: *"Knowledge base initialized with seed patterns from real developer experience."*

If not running as a plugin, skip this step.

### 1. Welcome

```
Welcome to Andamio Dev.

This plugin helps you build on the Andamio Protocol — courses, projects,
credentials, and Cardano transactions. It bundles the API specs, CLI
reference, and cost data so you get accurate guidance without leaving
your editor.

What are you working on?

 1. First time here — Walk me through what Andamio is and how this
    toolchain works.

 2. Exploring — I want to understand how the protocol works, browse
    the API, or learn about the transaction model.

 3. Building — I need to create courses, manage projects, run
    transactions, or import content. Get things done.

 4. Estimating costs — I want to know how much ADA different operations
    require.

 5. Debugging — I hit an error and need help figuring it out.
```

### 2. Detect Existing Auth

Before routing, check for existing credentials:

```bash
# Check CLI is installed
andamio --version 2>/dev/null

# Check CLI config
andamio user status 2>/dev/null
andamio auth status 2>/dev/null
```

If the CLI is not installed, note: "You'll need the Andamio CLI first. Let me walk you through setup." Route to `/orientation`.

If no credentials are detected and the developer's intent requires API access (anything except pure exploration or cost estimation), note: "You'll need authentication first. I'll walk you through auth setup."

### 3. Detect Mode

The developer's selection implies their mode:

| Selection | Mode | Why |
|-----------|------|-----|
| 1 (First time) | — | Route to `/orientation`, which introduces both modes |
| 2 (Exploring) | **Learning** | Understanding the protocol, not doing operations |
| 3 (Building) | **Operational** | Getting things done with the CLI |
| 4 (Costs) | **Learning** | Reference information, no operations |
| 5 (Debugging) | **Operational** | Fixing something specific |

**Mode is not a setting — it's a detection.** Throughout the session, the developer may switch between learning ("how does this work?") and operating ("do it for me"). Follow the cues:

- Questions ("how", "what", "why", "explain") → learning path: show API calls, explain the protocol, reference specs
- Commands ("create", "list", "build", "import", "run") → operational path: use CLI, parse output, chain results
- Both in one request ("create a course and explain what happens on-chain") → operate first, explain after

### 4. Route

| Selection | Auth needed? | Route to |
|-----------|-------------|----------|
| 1 (First time) | Detected in onboarding | `/orientation` |
| 2 (Exploring) | No for specs; API key for live queries | `/explore-api` |
| 3 (Building) | Yes (JWT for write ops) | Ask what they're building, then route: |
| | | — Courses → `/course-ops` (operational path) |
| | | — Projects → `/project-ops` (operational path) |
| | | — CLI help → `/cli-guide` |
| | | — Unsure → ask clarifying question |
| 4 (Costs) | No | `/cost-estimator` |
| 5 (Debugging) | No | `/troubleshoot` |

If auth is needed but missing, route through `/auth-setup` first, then continue to the target skill. The transition should be seamless.

Read and execute the target skill's instructions inline.

### 5. App Template Detection

If the developer mentions they're working with the Andamio App Template, or if you detect `andamio-app-template` or `andamio-app-v2` in the current project:

> "The App Template includes built-in Agent Skills for template-specific workflows (`/getting-started`, `/auth`, `/transactions`). This plugin covers the protocol and API layer. Use both together."

### 6. Mode Guidance for Skills

When executing a skill, follow its mode-specific sections:

**Learning path** (the developer wants to understand):
- Show API endpoints and request/response shapes
- Explain what happens on-chain (UTxOs created, tokens minted, deposits locked)
- Reference the spec files and lifecycle examples
- Walk through the transaction state machine step by step
- Use `/explore-api` and `/cost-estimator` as natural companions

**Operational path** (the developer wants to do):
- Use CLI commands with `--output json`
- Parse results and chain into next operations
- Prefer `tx run` over manual build/sign/submit/register
- Handle errors by routing to `/troubleshoot`
- Use `/cli-guide` as the natural companion

### 7. If Unsure

If the developer isn't sure what they need:

- "Is this your first time with Andamio?" → Yes: `/orientation`
- "Do you already have an API key or wallet set up?" → No: `/auth-setup`
- "Are you trying to understand something or build something?" → Understand: learning path. Build: operational path.
- "Do you have a specific error message?" → Yes: `/troubleshoot`
- "Want to know how much something costs in ADA?" → `/cost-estimator`
