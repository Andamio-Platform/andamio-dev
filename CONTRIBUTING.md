# Contributing to andamio-dev

Thank you for your interest in improving the Andamio developer experience.

## How to Contribute

1. Fork this repository
2. Create a feature branch (`git checkout -b feat/my-improvement`)
3. Make your changes
4. Test skills by cloning the repo and invoking them in Claude Code
5. Submit a pull request

## What to Contribute

- **Skill improvements**: Better guidance, clearer instructions, additional examples
- **Knowledge entries**: New gotchas, FAQ entries, cost scenarios from real developer experience
- **Spec updates**: When Andamio API versions change, bundled specs need refreshing
- **New skills**: Propose via an issue first — describe the developer need it addresses

## Conventions

- Skills follow the [Agent Skills](https://agent-skills.cc) open standard
- Knowledge files use YAML with append-only semantics (increment counts, don't overwrite)
- All content targets external developers — no internal-only details

## Releasing

Releases are coordinated by the Andamio team. If your contribution changes skill behavior or bundled specs, note it in your PR description.
