# Changelog

All notable changes to init-ai are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

## [0.3.0] — 2026-05-18

### Added
- **Versioning system**: `VERSION` file, `CHANGELOG.md`, and version stamp in projects (`.windsurf/.init-ai-version`)
- **Smart updater**: `--update` now shows changelog entries between your version and the latest before prompting per-file diffs
- **tdd-cycle Step 7 "Document in Spec"**: replaces "Mark Task Complete" — now writes implementation notes, marks acceptance criteria `[x]`, and updates the dependency graph with `✅`

### Changed
- `init-ai.ps1` bootstrap writes `.windsurf/.init-ai-version` on install
- `init-ai.ps1 --update` reads project version, displays relevant changelog, and stamps new version after completion

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
