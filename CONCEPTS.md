# Concepts

Shared domain vocabulary for this project — entities, named processes, and status concepts with project-specific meaning. Seeded with core domain vocabulary, then accretes as ce-compound and ce-compound-refresh process learnings; direct edits are fine. Glossary only, not a spec or catch-all.

## Public contribution

### Contribution front door
The public entry point, hosted in andamio-dev, where external contributors discover Andamio's public repos, see what work is open, and file new work. It is a *map and router*, not where work is hosted or decided.
*Avoid:* public face.

It reflects only public state — what is already visible on the public repos. How work is triaged, prioritized, or delegated is coordinated privately and never appears on the front door; the front door tells a contributor what is open and how to plug in, not what to work on first.

### Leaf repo
A public repo where contribution work actually lands and executes in its own flow (for example, the credential-badges repo). The contribution front door routes contributors to a leaf repo rather than owning the work; code-quality and security accountability for a leaf repo stay with the Andamio Development team.

### External-only content
The rule that everything shipped in the andamio-dev package must be derivable from public specs, docs, and the CLI — no internal-only details, internal coordination names, or internal policy IDs in shipped files (`skills/`, `reference/`, and root docs listed in `package.json`).
