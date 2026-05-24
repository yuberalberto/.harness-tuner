# 16 - README rewrite

## What to Build

Rewrite `README.md` from scratch to reflect harness-tuner v1.0.0. Sections:

1. **What is harness-tuner?** — 2–3 sentences. A bundle + opinion for tuning the Claude Code harness with SDD+TDD+DDD workflows.

2. **Install** — two paths:
   - One-liner: `iwr -useb <raw-url>/get.ps1 | iex`
   - Manual: `git clone <repo-url> ~/harness-tuner && ~/harness-tuner/install.ps1`

3. **Quick start** — in a project directory, run `ht init`. Then `ht --help` to see subcommands.

4. **What it gives you** — bullet list of the 5 layers + what lands per layer (3 rules, 12 skills, 4 hooks, MCP declarations).

5. **Updating** — `ht update` for the project, `ht self-update` for the framework itself.

6. **Why this exists** — 1 paragraph + link to `docs/philosophy.md`.

7. **Supported agents** — Claude Code only. Note about possible future wrappers.

8. **License**, **Contributing**, **Changelog** — links.

Replace ALL references to `init-ai`, `.windsurf/`, junctions, Cascade. Use only the new naming.

## Acceptance Criteria

- [ ] README starts with one-sentence value prop.
- [ ] Install section shows both paths, copy-paste-ready.
- [ ] No mention of `init-ai`, Cascade, Windsurf, or global junctions (except possibly a "Previously known as init-ai" footer line for SEO).
- [ ] Links to `docs/philosophy.md`, `docs/adr/`, `CHANGELOG.md` are present and resolve.
- [ ] Length under ~150 lines (concise).

## Blocked By

- 13 (`get.ps1` URL must be known to document the one-liner).
- 14 (`docs/philosophy.md` exists to link to).

## Type

AFK

## User Stories Covered

- US 1 (install instructions for new users)
- US 13 (clear note that target is Claude Code only)
