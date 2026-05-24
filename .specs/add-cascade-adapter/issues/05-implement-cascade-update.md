# 05 - Implement `ht update -Agent cascade`

## What to Build

Add `Invoke-UpdateCascade` to `harness-tuner.ps1` and extend the entry point routing to support `ht update -Agent cascade`.

`Invoke-UpdateCascade` mirrors `Invoke-Update` but operates on `.windsurf/` using `templates-cascade/` as source for rules and hooks, and `templates/skills/` as source for skills. The `hooks.json` is treated with additive merge (same as `settings.json` in the Claude Code update path).

Routing update:
```
ht update                  → Invoke-Update      (unchanged)
ht update -Agent cascade   → Invoke-UpdateCascade
```

Note: the batch confirmation improvement (Issue 06) applies to both `Invoke-Update` and `Invoke-UpdateCascade`. If 06 is done first, `Invoke-UpdateCascade` should use the same batch flow from the start.

## Acceptance Criteria

- [x] `ht update -Agent cascade` diffs `.windsurf/` against templates and applies approved changes
- [x] Skills updated from `templates/skills/` (all support files included)
- [x] Rules updated from `templates-cascade/rules/`
- [x] Hooks scripts updated from `templates-cascade/hooks/`
- [x] `hooks.json` merged additively on update
- [x] `.windsurf/.harness-tuner-version` stamped after update
- [x] `ht update` (no --agent) unchanged

## Blocked By

- Issue 04 (Invoke-BootstrapCascade infrastructure)

## Type

AFK

## User Stories Covered

- US2: As a Windsurf/Cascade developer, I want `ht update -Agent cascade` to update .windsurf/
