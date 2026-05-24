# Changelog

All notable changes to init-ai are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-05-23

### BREAKING

- **Renamed**: project is now `harness-tuner`; CLI command changes from `init-ai` to `ht`.
- **Dropped Cascade / Windsurf support**: `cascade/` directory and all `.windsurf/` writing are gone.
- **Dropped global junctions**: `install.ps1` no longer creates junctions under `~/.claude/skills/`.
- **Workspace marker moved**: `.windsurf/.init-ai-version` → `.claude/.harness-tuner-version`.
- **SDD working dir renamed**: `.scratch/` → `.specs/`.

### Added

- **5-layer harness model**: philosophy.md documents the conceptual framework (Identity, Memory, Process, Tools, Guardrails).
- **`templates/hooks/`**: 4 lifecycle hooks — `engram-session-start`, `engram-session-end`, `format-post-edit`, `git-guardrails-pre-bash`.
- **MCP declarations**: `engram` and `context7` declared in `templates/settings.json`.
- **3 new skills**: `grill-me`, `code-standards`, `inspect-harness`.
- **`get.ps1`**: one-liner installer (`irm https://... | iex`).
- **`ht self-update`** subcommand: updates the harness from the remote repo.
- **`docs/philosophy.md`**: rationale and design principles.
- **3 ADRs**: recorded under `docs/adr/`.

### Changed

- `install.ps1` simplified to alias-only setup (no junction logic).
- `harness-tuner.ps1` uses subcommand CLI: `ht init` / `ht update` / `ht self-update`.
- `testing.md` rule content moved inline into `tdd-cycle/SKILL.md`; standalone rule removed.
- `sdd-process.md` trimmed to the workflow router table only.

### Removed

- `cascade/` directory.
- All `.windsurf/` file writing.
- Global junction logic from `install.ps1`.
- `testing.md` as a standalone rule file.

### Migration Notes

Existing `init-ai` users:

1. `git clone https://github.com/yuberalberto/harness-tuner.git`
2. Run the new `install.ps1` (registers the `ht` alias).
3. In each project, run `ht init` to deploy the updated harness.

Legacy `.windsurf/` directories are left in place and ignored — there is no auto-migration.

## [0.7.0] — 2026-05-21

### Changed
- **Per-agent native architecture**: replaced `methodology/` + `adapters/` with two
  top-level agent folders — `claude-code/` (deployed to `.claude/`) and `cascade/`
  (deployed to `.windsurf/`), each holding rules and skills in the agent's native format
- Rules reduced to 4 always-on files: `sdd-process`, `testing`, `identity`, `engram`
- Skills migrated to 9 self-contained skills (full inline workflow, no thin wrappers):
  `grill-with-docs`, `to-prd`, `to-issues`, `tdd-cycle`, `zoom-out`,
  `improve-codebase-architecture`, `audit`, `review`, `git-flow`
- Issue tracking moved to local markdown under `.scratch/<feature>/` with an
  `INDEX.md` dependency graph + status table
- `install.ps1` now junctions `claude-code/skills/` instead of the old adapter paths
- `init-ai.ps1` deploys both agent folders and dropped the unused `-ProjectName` parameter

### Removed
- `methodology/`, `adapters/`, `templates/`, and `specs/` directories
- `CLAUDE.md.template` and all CLAUDE.md generation — bootstrap never touches CLAUDE.md
- Eliminated skills: `create-spec`, `spec-to-code`, `wiki-gen`, `handoff`, `safe-delete`,
  `simplify`, `legacy-modernize`, `context-doc`, `task-transition`, `restore-context`,
  `pr-review`

## [0.6.0] — 2026-05-18

### Changed
- Bootstrap: if `.claude/CLAUDE.md` already exists, skip silently — project owns that file
- Update: CLAUDE.md is never touched — not the framework's responsibility
- Updater: shows diff summary (+N/-N lines) instead of full diff; press `d` to see full diff
- Template: removed `<!-- init-ai:hash -->` marker — unnecessary complexity

### Removed
- All CLAUDE.md marker/hash tracking logic

## [0.5.0] — 2026-05-18

### Added
- **`<!-- init-ai:hash -->` marker** in `.claude/CLAUDE.md` — tracks which template version was applied, replaces `.windsurf/.init-ai-template-hash`
- **Project name defaults to current folder** — bootstrap no longer requires typing the name if the folder name matches
- **Diff on demand** — updater shows a summary (+N lines) instead of the full diff; press `d` to see the full diff when needed
- **`--update` double-dash support** — both `-update` and `--update` now work correctly

### Changed
- Bootstrap prompts `Project name [folder-name]:` — press Enter to accept, or type a different name
- Bootstrap: if `.claude/CLAUDE.md` already exists with init-ai marker → skip; without marker → append `## Project Context` section only
- Update: CLAUDE.md tracking now uses template hash marker instead of separate `.windsurf/.init-ai-template-hash` file
- Changelog header when no version stamp found shows `Full changelog (no prior version stamp found)` instead of `Changes since v:`
- Next steps after bootstrap trimmed to two lines — removed redundant `install.ps1` reminder

### Removed
- `.windsurf/.init-ai-template-hash` — superseded by the `<!-- init-ai:hash -->` marker in CLAUDE.md

## [0.4.0] — 2026-05-18

### Added
- **`--help` flag**: `init-ai --help` shows all available commands and usage
- **CLAUDE.md template change detection**: `--update` warns when the CLAUDE.md template has changed and suggests manual review

### Changed
- `.windsurf/.init-ai-version` is now documented as a file to commit (so teammates know the installed version)
- README updated with versioning tracking files documentation

## [0.3.0] — 2026-05-18

### Added
- **Versioning system**: `VERSION` file, `CHANGELOG.md`, and version stamp in projects (`.windsurf/.init-ai-version`)
- **Smart updater**: `--update` now shows changelog entries between your version and the latest before prompting per-file diffs
- **tdd-cycle Step 7 "Document in Spec"**: replaces "Mark Task Complete" — now writes implementation notes, marks acceptance criteria `[x]`, and updates the dependency graph with `✅`
- **Shell alias**: `install.ps1` registers `init-ai` function in PowerShell profile — no more typing the full path
- **`--version` flag**: `init-ai --version` prints current framework version
- **`--changelog` flag**: `init-ai --changelog` prints the full changelog
- **Install guard**: `install.ps1` detects existing installation, shows version, and suggests `--force` to reinstall

### Changed
- `init-ai.ps1` bootstrap writes `.windsurf/.init-ai-version` on install
- `init-ai.ps1 --update` reads project version, displays relevant changelog, and stamps new version after completion
- `install.ps1` accepts `--force` flag to bypass already-installed check
- README updated: simplified commands using `init-ai` alias, added versioning section and `VERSION`/`CHANGELOG.md` to directory tree

## [0.2.0] — 2026-05-18

### Added
- `-ProjectName` and `-Language` parameters for non-interactive bootstrap
- Junior-friendly task format in spec workflow (goal, files, message template, hints, acceptance criteria, depends on)
- Grill process in `/spec-to-code` for resolving design gaps before writing specs
- Security review merged into `/review` workflow

### Changed
- README rewritten: generic, quick start first, commands separated

## [0.1.0] — 2026-05-17

### Added
- Initial release — methodology rules, workflows, skills, adapters for Claude Code and Cascade
- `init-ai.ps1` bootstrap and `--update` with per-file diff approval
- `install.ps1` for Claude Code skill junctions
- CLAUDE.md template with project-specific sections
