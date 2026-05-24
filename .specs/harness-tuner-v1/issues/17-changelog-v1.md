# 17 - CHANGELOG v1.0.0 entry

## What to Build

Add a new entry at the top of `CHANGELOG.md` (after the `# Changelog` header, before the existing v0.7.0 entry) describing the v1.0.0 release. Use Keep-a-Changelog format.

Sections within the entry:

- **BREAKING** — clearly marked. Items:
  - Renamed from `init-ai` to `harness-tuner`. New CLI command `ht`.
  - Dropped Cascade / Windsurf support.
  - Dropped global junctions in `~/.claude/skills/`.
  - Workspace marker moved from `.windsurf/.init-ai-version` to `.claude/.harness-tuner-version`.
  - SDD working dir renamed from `.scratch/` to `.specs/`.

- **Added** — 5-layer harness model, `templates/hooks/`, MCP declarations, new skills `grill-me` / `code-standards` / `inspect-harness`, `get.ps1` one-liner installer, `ht self-update` subcommand, `docs/philosophy.md`, 3 ADRs.

- **Changed** — `install.ps1` simplified to alias-only setup. `harness-tuner.ps1` uses subcommand CLI (`ht init`/`update`/`self-update`). `testing.md` rule content moved inline into `tdd-cycle/SKILL.md`. `sdd-process.md` recortated to the router table.

- **Removed** — `cascade/` directory. `.windsurf/` writing. Global junction logic in `install.ps1`. `testing.md` standalone rule.

- **Migration notes** — pointer for existing init-ai users: `git clone` the new repo, run new `install.ps1`, run `ht init` in each project. Legacy `.windsurf/` is ignored (no auto-migration).

Historical entries (v0.5.0–v0.7.0) referencing Cascade are NOT modified — they remain truth of past.

## Acceptance Criteria

- [ ] CHANGELOG.md has a new v1.0.0 entry at the top, dated.
- [ ] All 5 subsections (BREAKING, Added, Changed, Removed, Migration notes) are present.
- [ ] Historical entries are untouched.
- [ ] Entry contains no references to features still in development at the time of release (only what's actually shipped).

## Blocked By

Most slices (the entry describes what they collectively land). In practice this is the LAST writing task before issue 18.

## Type

AFK

## User Stories Covered

- (Implicit — supports adoption by communicating changes clearly.)
