# 14 - Doc: docs/philosophy.md (5-layer explanation)

## What to Build

Create `docs/philosophy.md` — the articulation of harness-tuner's opinion. This doc serves dual purpose: internal anchor for design decisions, and the public-facing "why" for adopters.

Sections:

1. **The 5 layers of the Claude Code harness** — for each (rules, skills, hooks, MCP, subagents): what it is, when it consumes context, when to use it, when NOT to use it.

2. **Why minimal rules** — the always-on cost. The rule of thumb: a rule earns its place only if it's needed in EVERY task. Otherwise it's a skill.

3. **Why hooks for mechanical work** — zero agent-context cost. Examples: formatters, memory protocol lifecycle, git guardrails.

4. **Why subagents for exploration** — isolated context. Use cases: code search across many files, multi-file refactor analysis.

5. **Why workspace-scoped** — portability, predictability, no hidden global state.

6. **The bundle + opinion identity** — harness-tuner is both a curated bundle (skills + hooks + MCP config) and an articulated opinion (this document) on how to compose them.

The doc should be readable as a standalone essay (~800–1200 words) and link to the README for getting started.

## Acceptance Criteria

- [ ] `docs/philosophy.md` exists with the 6 sections above.
- [ ] Each layer section answers the 4 questions (what, when context cost, when to use, when not).
- [ ] No code samples — this is conceptual, not how-to.
- [ ] Reading it makes the design decisions in the rest of the framework feel inevitable.
- [ ] Linked from README (issue 16).

## Blocked By

None — independent of all other slices.

## Type

HITL (human review for tone and clarity — this is the "marketing" face of the framework).

## User Stories Covered

- US 12 (philosophy doc explaining 5 layers)
