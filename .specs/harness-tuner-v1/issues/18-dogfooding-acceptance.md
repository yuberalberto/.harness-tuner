# 18 - Dogfooding + acceptance verification

## What to Build

Execute the full acceptance protocol defined in the PRD:

1. **Dogfooding** — on a fresh clone of the harness-tuner repo (or a clean checkout of the merge branch), run `ht init`. Verify:
   - `.claude/rules/` contains the 3 expected files (identity interpolated, engram, sdd-process).
   - `.claude/skills/` contains all 12 skill directories.
   - `.claude/hooks/` contains all 4 hook scripts.
   - `.claude/settings.json` has hooks block, MCP block, and permissions baseline.
   - `.claude/.harness-tuner-version` contains the current `VERSION` value.

2. **Pipeline SDD end-to-end** — in a separate fresh project (greenfield), run:
   - `ht init`
   - Invoke `/grill-with-docs` for a small fake feature → confirm CONTEXT.md is created/updated.
   - Invoke `/to-prd` → confirm PRD written to `.specs/<feature>/PRD.md`.
   - Invoke `/to-issues` → confirm issues + INDEX.md generated.
   - Invoke `/tdd-cycle` for one issue → confirm RED/GREEN cycle works and INDEX.md updates.

3. **`/inspect-harness` self-report** — in the dogfooded project, invoke `/inspect-harness` and verify the report correctly enumerates rules, skills, hooks, MCPs.

4. **Hooks verification** — manually trigger each hook:
   - SessionStart in Claude Code → confirm engram mem_context loads (look for prior memory in chat).
   - Edit a JS file in the project → confirm prettier ran (or warning if not installed).
   - Attempt `git push --force` via the agent → confirm guardrail blocks.
   - End the session → confirm `mem_session_summary` ran (check engram for the new entry).

Document any issues found in a report and link the fixes from the relevant issue PRs.

## Acceptance Criteria

- [ ] Dogfooding produces a `.claude/` matching the expected layout.
- [ ] Greenfield project completes the full SDD pipeline without manual intervention.
- [ ] `/inspect-harness` report is accurate.
- [ ] All 4 hooks fire on their respective events.
- [ ] Any regression / bug found is filed as a follow-up issue and resolved before v1.0.0 is tagged.

## Blocked By

All other slices (01–17).

## Type

HITL (manual verification, can't be fully automated).

## User Stories Covered

- US 2 (full layer setup works)
- US 3 (hooks fire)
- US 5 (pipeline SDD works end-to-end)
- US 6 (`/inspect-harness` reports correctly)
- (Acceptance criteria #1, #2, #3 from PRD)
