# 02 - harness-tuner.ps1 (CLI with all subcommands)

## What to Build

Rewrite `init-ai.ps1` → `harness-tuner.ps1` as the framework's main CLI entry point. Drop all Cascade/`.windsurf/` logic. Drop global state writes. Implement subcommand-based CLI (git/docker style):

- `ht` (no args) → show help.
- `ht init` → bootstrap: copy `templates/rules/`, `templates/skills/`, `templates/hooks/`, and merge `templates/settings.json` into the target project's `.claude/`. Stamp `.claude/.harness-tuner-version` with the current `VERSION` file contents.
- `ht update` → file-by-file interactive diff/merge between `templates/` and the project's `.claude/`. Accept/reject/diff per file.
- `ht self-update` → `git pull origin main` inside `$HARNESS_TUNER_HOME`.
- `ht --version`, `ht --changelog`, `ht --help` → meta-flags.
- **Coexistence**: if `.claude/` exists WITHOUT `.harness-tuner-version`, treat as foreign; prompt per file collision (accept/reject/diff). If `.harness-tuner-version` already present, abort `ht init` and suggest `ht update`. Legacy `.windsurf/` is ignored silently.

Fix the pre-existing parser bugs from the legacy script (em-dash encoding, malformed regex).

## Acceptance Criteria

- [ ] Script parses clean under both Windows PowerShell 5.1 and PowerShell 7+.
- [ ] `ht` with no args prints a help summary listing all subcommands.
- [ ] `ht init` in a temp project creates `.claude/.harness-tuner-version` matching the framework's `VERSION`.
- [ ] `ht init` aborts gracefully with a suggestion when the marker already exists.
- [ ] `ht init` on a foreign `.claude/` (no marker) prompts per collision.
- [ ] `ht update` diffs `templates/` against the project, respects accept/reject decisions per file.
- [ ] `ht self-update` runs `git pull origin main` in `$HARNESS_TUNER_HOME` and prints the output.
- [ ] Pester suite in `tests/harness-tuner.Tests.ps1` covers bootstrap, update, self-update, coexistence, and the foreign-`.claude/` path.

## Blocked By

None — can start immediately. (Tests reference `templates/` which is built in 03 and 04, but the script logic can be developed against a stub `templates/` first; tests are run end-to-end once dependencies land.)

## Type

AFK

## User Stories Covered

- US 2 (one command configures all layers)
- US 7 (workspace portability)
- US 8 (coexistence with foreign `.claude/`)
- US 9 (`ht self-update`)
- US 14 (legacy `.windsurf/` ignored)
