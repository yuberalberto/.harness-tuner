# 12 - templates/settings.json (hooks + MCPs + baseline permissions)

## What to Build

Create `templates/settings.json` — the merged settings file that `ht init` copies into the project's `.claude/settings.json`. Contents:

**Hooks block** — declare all 4 hooks from issues 08–11 with their event triggers:
- `SessionStart` → `.claude/hooks/engram-session-start.ps1`
- `Stop` → `.claude/hooks/engram-session-end.ps1`
- `PostToolUse(Edit|Write|NotebookEdit)` → `.claude/hooks/format-post-edit.ps1`
- `PreToolUse(Bash)` → `.claude/hooks/git-guardrails-pre-bash.ps1`

**MCP servers block** — declare engram (required) and context7 (recommended) with stdio transport config. Server installation remains the user's responsibility — `README.md` (issue 16) explains how.

**Permissions baseline** — a curated allowlist of safe read-only operations to reduce prompt fatigue:
- `Read(**)`, `Glob(**)`, `Grep(**)`.
- `Bash(ls *)`, `Bash(pwd)`, `Bash(git status)`, `Bash(git diff *)`, `Bash(git log *)`, `Bash(git branch)`.
- Engram MCP read-only tools (`mem_search`, `mem_context`, `mem_get_observation`).

**Merging behavior** in `ht init` (defined in issue 02): if the target's `.claude/settings.json` already exists, merge additively — hooks and MCP entries are added if absent; permissions are unioned with the existing list.

## Acceptance Criteria

- [ ] `templates/settings.json` is valid JSON and parses without error.
- [ ] All 4 hook entries reference paths under `.claude/hooks/` (relative to the project root).
- [ ] Engram and context7 MCP server entries are present with correct command/args.
- [ ] Permission allowlist contains at least the entries listed above.
- [ ] After `ht init` into a fresh project, `.claude/settings.json` contains all of the above.
- [ ] After `ht init` into a project with a pre-existing `.claude/settings.json`, the merge is additive (existing entries preserved).

## Blocked By

- 08, 09, 10, 11 (hook scripts must exist so the paths in settings.json are real).

## Type

AFK

## User Stories Covered

- US 3 (hooks declared)
- US 6 (MCPs declared so `/inspect-harness` finds them)
- US 10 (git guardrails wired up)
