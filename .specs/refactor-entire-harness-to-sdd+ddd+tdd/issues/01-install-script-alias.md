# 01 - install.ps1 simplified (alias only)

## What to Build

Rewrite `install.ps1` from its current state (creating global junctions in `~/.claude/skills/` + alias setup) into a minimal script that ONLY adds the `ht` alias function to `$PROFILE.CurrentUserAllHosts`. The function delegates to `harness-tuner.ps1` inside `$HARNESS_TUNER_HOME` (the local clone).

Remove all junction creation logic, `Test-AlreadyInstalled` junction checks, `New-Junction` function, and the skill enumeration loop.

Keep / add: idempotency check (skip if `ht` function already in profile), create `$PROFILE` directory if missing, add the `ht` function block, print confirmation + reload instruction.

## Acceptance Criteria

- [ ] `install.ps1` is under 50 lines of executable code.
- [ ] Running `install.ps1` in a fresh shell adds `ht` function to `$PROFILE.CurrentUserAllHosts`.
- [ ] Running `install.ps1` twice does not duplicate the alias entry.
- [ ] No directories are created in `~/.claude/`.
- [ ] Pester smoke test in `tests/install.Tests.ps1` covers a temp `$env:USERPROFILE` install + idempotency.

## Blocked By

None — can start immediately.

## Type

AFK

## User Stories Covered

- US 1 (one-line install ergonomics)
- US 7 (workspace-only portability)
