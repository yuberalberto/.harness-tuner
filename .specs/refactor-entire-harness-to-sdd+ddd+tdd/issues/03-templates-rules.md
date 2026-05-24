# 03 - templates/rules/ (3 minimal always-on rules)

## What to Build

Create `templates/rules/` containing the 3 minimal always-on rules:

- **`identity.md`** — role, default language for everything, chat language interpolated via `{{USER_LANGUAGE}}`, anti-sycophancy, concision, ambiguity (ask 1 clarifying question), decisions (top 2 options + tradeoffs), permission protocol. Mostly the current version, kept compact.

- **`engram.md`** — runtime memory protocol: when to call `mem_save` (decisions, bugs, gotchas, conventions, user preferences), what to include (What/Why/Where/Learned), upsert via `topic_key`. Remove lifecycle wording (`mem_context` at start, `mem_session_summary` at end) — those are now hooks (issues 08, 09).

- **`sdd-process.md`** — RECORTED to only the router table: task type → which skill to invoke. Strip all structural details about `.specs/<feature>/` layout, INDEX.md format, status values — those move into `to-prd` and `to-issues` skill bodies.

## Acceptance Criteria

- [ ] `templates/rules/identity.md` retains `{{USER_LANGUAGE}}` placeholder for `harness-tuner.ps1` to interpolate at bootstrap.
- [ ] `templates/rules/engram.md` no longer references SessionStart / SessionEnd calls (those are hooks).
- [ ] `templates/rules/sdd-process.md` is reduced to the workflow router table + a single line referencing each skill. Total length under 40 lines.
- [ ] No `testing.md` exists in `templates/rules/` (its content lives in `tdd-cycle/SKILL.md` per issue 04).
- [ ] After `ht init`, the 3 rules appear in `.claude/rules/` of the target project.

## Blocked By

None — independent of all other slices.

## Type

AFK

## User Stories Covered

- US 4 (minimal rules always-on)
