# Harness-Tuner — v1.0.0 PRD

**Project**: Harness-Tuner — an opinionated 5-layer Claude Code harness configuration.
**Status**: Initial release (rebrand from the legacy `init-ai` project).
**CLI**: `ht` (alias function in `$PROFILE`).

## Problem Statement

The current harness-tuner framework only uses two layers of the Claude Code harness (rules + skills), ignoring three available capabilities: hooks (automation), MCP servers (runtime tools), and subagents (isolated context). The consequences:

- Always-on rules consume context tokens regardless of the current task. For example, `testing.md` is loaded even when the agent is doing requirements grilling or git operations — situations where TDD conventions are irrelevant.
- The agent's reasoning capacity is spent on mechanical tasks (running formatters, lint checks, memory protocol bookkeeping) that could be automated via hooks with zero context cost.
- Long exploratory work contaminates the main agent's context instead of being delegated to isolated subagents (Explore, Plan).

Secondary problems compounding this:

- Maintaining two parallel agent formats (Claude Code + Cascade) doubles the work for any change to a skill or rule.
- Global installation (junctions in `~/.claude/skills/`) creates implicit state that desynchronizes with workspace copies: the user edits one and forgets it has a twin elsewhere.
- Onboarding requires manual `git clone` + script execution; there is no zero-friction install path.

## Solution

Refactor harness-tuner into a **workspace-scoped, single-agent, five-layer-aware framework** for Claude Code.

The framework distributes a curated, opinionated harness configuration to each project. Running `ht init` in any project deploys all five layers correctly into `.claude/`:

- **Rules** (3): minimal always-on — identity, engram protocol, SDD router.
- **Skills** (12): lazy-loaded workflows including the SDD pipeline, a generic `/grill-me` for open-ended exploration, and `/inspect-harness` for context visibility.
- **Hooks** (4): mechanical automation with zero agent-context cost — engram lifecycle, code formatting, git guardrails.
- **MCP servers**: declared per-project in `.claude/settings.json` (engram + context7). Server installation remains the user's responsibility (treated like git or node — a system tool).
- **Subagents**: leverage Claude Code's native Explore/Plan from within skills; no custom subagents.

Two installation paths converge on the same state:

1. One-liner remote installer: `iwr | iex` fetches `get.ps1`, which clones the repo to `~/harness-tuner/` and invokes `install.ps1`.
2. Manual: `git clone ... ~/harness-tuner && ~/harness-tuner/install.ps1`.

Both result in `~/harness-tuner/` cloned locally + `ht` alias function in `$PROFILE`. Project bootstrap is workspace-only — zero global state in `~/.claude/`, `~/.windsurf/`, `~/.antigravity/`, or any other tool-specific directory.

## User Stories

1. As a new user discovering harness-tuner, I want a one-line install command, so that I can start using the framework without reading multi-step setup instructions.

2. As a harness-tuner user starting a new project, I want to run `ht init` and have all 5 harness layers configured at workspace level, so that I get a consistent and complete AI development environment from a single command.

3. As a Claude Code user, I want hooks that automatically run formatters and engram memory captures, so that the agent's reasoning context is preserved for actual problem-solving instead of mechanical tasks.

4. As a developer concerned about context efficiency, I want the framework to load minimal rules always-on (only identity, engram protocol, and a skill router), so that more context is available for the actual task at hand.

5. As a developer following the SDD process, I want skills for each phase (`/grill-with-docs`, `/to-prd`, `/to-issues`, `/tdd-cycle`), so that I can move through requirements gathering, decomposition, and implementation with structured prompts.

5b. As a developer with a quick idea or exploration that does NOT warrant a formal SDD pipeline, I want a generic `/grill-me` skill that interrogates me to expand the idea, so that I can clarify my own thinking without committing to write a PRD or update CONTEXT.md.

6. As a harness-tuner user, I want a `/inspect-harness` skill, so that I can see what rules, skills, hooks, MCP servers, and subagents are currently configured in my project's harness without leaving the agent.

7. As a harness-tuner user with multiple projects, I want my projects to be completely portable, so that running `ht init` in a new project gives me the exact same harness without depending on any global configuration.

8. As a harness-tuner user with an existing `.claude/` from other tools, I want `ht init` to coexist non-destructively, so that I don't lose my pre-existing configuration when adopting the framework.

9. As a harness-tuner user, I want to update the framework with `ht self-update`, so that I can pull the latest version of the framework from inside any project without manual git navigation.

10. As a developer, I want git guardrails as hooks (blocking `push --force`, `reset --hard`, etc. without explicit approval), so that destructive operations don't happen accidentally during agent-driven workflows.

11. As a developer doing TDD, I want a `/code-standards` skill invoked in the Refactor step, so that style decisions are applied at the right phase without polluting the earlier RED/GREEN phases.

12. As a developer reading the framework's source, I want a `docs/philosophy.md` explaining the five layers and when to use each, so that I understand the opinion behind the framework and can adapt it for my own purposes.

13. As a Cascade/Windsurf user, I want a clear note that harness-tuner targets Claude Code only (with a wrapper potentially coming later), so that I don't waste time trying to use it with the wrong agent.

14. As a user who installed an older version of harness-tuner (with `.windsurf/`), I want the new framework to ignore the legacy folder gracefully, so that I can adopt the new version without being forced into manual cleanup.

## Implementation Decisions

### Architecture

- **Single-agent**: Claude Code only. Cascade (Windsurf) support is dropped. A wrapper for other agents (Cursor, Windsurf, Antigravity) may come in a later release but is not part of this refactor.
- **Workspace-scoped**: zero state in any global location (`~/.claude/`, `~/.windsurf/`, etc.). The only thing touching the user profile is the `ht` shell alias function in `$PROFILE.CurrentUserAllHosts`.
- **Coexistence**: when `.claude/` exists without an `.harness-tuner-version` marker, harness-tuner treats it as a foreign installation and prompts file-by-file on collisions (accept / reject / diff).

### Distribution

- **Two installation paths converge to same state**:
  - One-liner: `iwr -useb <raw-url>/get.ps1 | iex` fetches `get.ps1`, which clones the repo to `~/harness-tuner/` (if absent) and invokes `install.ps1`.
  - Manual: `git clone <repo-url> ~/harness-tuner && ~/harness-tuner/install.ps1`.
- **`install.ps1` responsibility**: only adds the `ht` function to `$PROFILE.CurrentUserAllHosts` (which delegates to `~/harness-tuner/harness-tuner.ps1`). No global junctions, no skill installation, no MCP setup.
- **`get.ps1` responsibility**: detects git, clones the repo, invokes `install.ps1`. Designed to be human-auditable in a single screen (~30 lines).
- **`ht` CLI structure** (subcommand-based, like git/docker/kubectl):
  - `ht` (no args): show help (list subcommands + brief description).
  - `ht init`: bootstrap the current project — copy `templates/` to `.claude/`.
  - `ht update`: interactive diff/merge with current `.claude/` files (file-by-file accept/reject/diff).
  - `ht self-update`: `git pull origin main` in `$HARNESS_TUNER_HOME`.
  - `ht --version`, `ht --changelog`, `ht --help`: meta-flags.

### Templates directory structure

```
templates/
├── rules/
│   ├── identity.md          # role, language, anti-sycophancy, permission protocol
│   ├── engram.md             # runtime memory protocol (when/what to save)
│   └── sdd-process.md        # router only: task type → skill mapping
├── skills/                   # 12 dirs, one per skill
│   ├── grill-me/             # NEW — generic grilling, no SDD commitment
│   ├── grill-with-docs/      # SDD entry point — updates CONTEXT.md, proposes ADRs
│   ├── to-prd/
│   ├── to-issues/
│   ├── tdd-cycle/            # testing convention now inlined here
│   ├── code-standards/       # NEW
│   ├── inspect-harness/      # NEW
│   ├── audit/
│   ├── review/
│   ├── git-flow/
│   ├── zoom-out/
│   └── improve-codebase-architecture/
├── hooks/                    # 4 scripts triggered by Claude Code events
│   ├── engram-session-start.ps1
│   ├── engram-session-end.ps1
│   ├── format-post-edit.ps1
│   └── git-guardrails-pre-bash.ps1
└── settings.json             # declares hooks, MCPs, default permissions
```

### Layer decisions

**Rules** (3): the minimum set required for the agent to function with identity, memory protocol, and a way to find the right skill for any task.
- `testing.md` is REMOVED as a rule — its content moves inline into `tdd-cycle/SKILL.md`.
- `sdd-process.md` is RECORTED to only the task→skill mapping table; structural details about `.specs/` move into `to-prd/` and `to-issues/`.

**Skills** (12): each is self-contained markdown invoked on-demand. Lazy-loaded by Claude Code (only `name` + `description` consumed until invoked).
- The 9 current skills remain: grill-with-docs, to-prd, to-issues, tdd-cycle, zoom-out, improve-codebase-architecture, audit, review, git-flow.
- `grill-me` (NEW): generic interrogation skill for open-ended exploration and idea expansion. Does NOT touch CONTEXT.md or docs/adr/. Does NOT suggest a next pipeline step. Distinct from `grill-with-docs`, which is the SDD entry point.
- `code-standards` (NEW): style and naming conventions, invoked at Step 4 (Refactor) of tdd-cycle or standalone for legacy cleanup.
- `inspect-harness` (NEW): reports loaded rules + their approximate token cost, available skills, registered hooks, connected MCPs, and accessible subagents.

**Hooks** (4): scripts executed by Claude Code on lifecycle events. Zero agent-context cost.
- `engram-session-start`: calls `mem_context` MCP tool to load prior session memory at SessionStart.
- `engram-session-end`: calls `mem_session_summary` at Stop event.
- `format-post-edit`: on PostToolUse(Edit|Write), runs language-appropriate formatter (prettier/ruff/gofmt) detected from file extension.
- `git-guardrails-pre-bash`: on PreToolUse(Bash), blocks `git push --force`, `git reset --hard`, `git clean -f`, etc., unless explicit user approval was just given. Inspired by Matt Pocock's `git-guardrails-claude-code` skill.

**MCP servers** (declared in `templates/settings.json`, merged into `.claude/settings.json` on bootstrap):
- `engram` (required): provides memory persistence via `mem_*` tools.
- `context7` (recommended): provides up-to-date library docs lookup.
- Server installation is the user's responsibility (docs link to engram repo + context7 install instructions).

**Subagents**: zero custom. Skills that need isolated exploration (e.g., `audit`, `review`, `improve-codebase-architecture`) invoke Claude Code's native `Explore` or `Plan` subagents with curated prompts written into the SKILL.md.

### Versioning

- `.claude/.harness-tuner-version` is the workspace marker. Its presence indicates harness-tuner is installed; its contents indicate which version.
- This file replaces the legacy `.windsurf/.init-ai-version`.
- Legacy `.windsurf/` directories are IGNORED by `ht update` (no migration, no cleanup, no error).

### Settings.json template

The distributed `templates/settings.json` is merged (not overwritten) into the project's `.claude/settings.json` on bootstrap. It declares:
- Hooks: paths to the 4 scripts under `.claude/hooks/`.
- MCP servers: engram (required), context7 (recommended) with stdio config.
- Permissions: baseline allowlist of safe read-only operations (`Read(**)`, `Bash(ls)`, `Bash(git status)`, `Bash(git diff)`, etc.).

When merging into an existing `.claude/settings.json`:
- Hooks: additive (prompt on conflict for the same trigger).
- MCPs: additive (prompt on name conflict).
- Permissions: union with user's existing list.

### Coexistence behavior

| State | Action |
|---|---|
| `.claude/` does not exist | Clean bootstrap (copy entire `templates/`). |
| `.claude/.harness-tuner-version` exists | harness-tuner already installed — abort, suggest `ht update`. |
| `.claude/` exists WITHOUT `.harness-tuner-version` | Foreign installation. For each file collision (e.g., `.claude/rules/identity.md` already exists), prompt user: accept / reject / diff. Write `.harness-tuner-version` only after successful merge. |

### Self-update

- `ht self-update` runs `git pull origin main` in `$HARNESS_TUNER_HOME` (typically `~/harness-tuner/`).
- Requires git installed (same prerequisite as `get.ps1`).
- Prints `git pull` output for transparency.
- Does NOT auto-apply changes to existing projects — user runs `ht update` per project to pull updates.

## Testing Decisions

The framework is largely declarative markdown and shell scripts, not application code. Testing focuses on integration and acceptance rather than unit tests.

### What makes a good test

- Tests verify observable behavior (file system state, script exit codes, script stdout), not internal implementation.
- Tests run in a fresh, isolated environment (temp directory, no shared global state, no dependency on user's actual `~/harness-tuner/`).
- Tests are deterministic and don't depend on network (except `get.ps1` smoke test, which is opt-in).

### Modules to be tested

1. **`harness-tuner.ps1` bootstrap** (`Invoke-Bootstrap`):
   - Bootstrap in temp project dir → assert `.claude/rules/`, `.claude/skills/`, `.claude/hooks/`, `.claude/settings.json`, `.claude/.harness-tuner-version` are created with correct contents.
   - Bootstrap aborts cleanly when `.claude/.harness-tuner-version` already exists.
   - Coexistence: prompts on file collisions when `.claude/` exists without version stamp.

2. **`harness-tuner.ps1` update** (`Invoke-Update`):
   - After modifying a template file in `~/harness-tuner/templates/`, running `--update` shows the diff and respects accept/reject decisions.
   - Legacy `.windsurf/` directories are ignored without errors.

3. **`harness-tuner.ps1` self-update**:
   - In a fresh local clone → simulate a remote commit → run `--self-update` → verify the local repo advances to the new HEAD.

4. **Hooks** (each script):
   - Each hook is invoked with mock input matching Claude Code's event payload format and verified to produce expected stdout/stderr and exit codes.
   - `format-post-edit`: JS file triggers prettier, Python triggers ruff, unknown extension is a no-op.
   - `git-guardrails-pre-bash`: `git push --force` is blocked (non-zero exit), `git status` is allowed (exit 0).

5. **`get.ps1` remote installer** (smoke test, opt-in):
   - In a temp `$env:USERPROFILE` → execute `get.ps1` → verify `~/harness-tuner/` exists with expected files and `$PROFILE` contains the alias.

6. **`/inspect-harness` skill** (manual acceptance):
   - In a freshly bootstrapped project, invoke the skill → verify the agent reports the correct rules, skills, hooks, MCPs.

### Prior art

There are no existing tests in the current harness-tuner repo. Tests will be new. Adopt Pester (PowerShell-native testing framework) for `harness-tuner.ps1`, `get.ps1`, `install.ps1`, and the hook scripts. Tests live in `tests/` at the repo root.

## Out of Scope

- **Cascade/Windsurf support**: explicitly dropped. A wrapper for other agents may come in a later release but is not part of this refactor.
- **Custom subagents**: this refactor relies on Claude Code's native Explore/Plan. Custom subagents (e.g., a `code-reviewer` agent) are deferred to a future iteration.
- **MCP server installation automation**: the framework configures which MCPs to use per-project but does not install the server binaries. Users install engram/context7 manually following docs links.
- **Mac/Linux PowerShell Core verification**: scripts target both Windows PowerShell and PowerShell Core, but only Windows is the verified target for this refactor. Cross-platform testing is deferred.
- **Migration of active projects with `.windsurf/`**: the refactor ignores legacy installs. Users with active projects from prior versions must reapply bootstrap manually (no automated migration).
- **Backward compatibility of skill names**: legacy `create-spec` and other removed skills are not aliased. The transition is a clean break.

## Further Notes

- **CHANGELOG entry**: historical entries (v0.5.0–v0.7.0) referencing Cascade remain untouched (truth of past). A new entry for this refactor is added at the end of the file.
- **Version bump**: this is a breaking change for any user with an existing harness-tuner install (drops Cascade, restructures dirs, removes global junctions, introduces hooks/MCPs). Recommend bumping to **v1.0.0** to signal the breaking nature and the framework's transition to "stable opinion".
- **Dogfooding plan**: after the refactor lands on a branch, run `ht init` on the harness-tuner repo itself. The resulting `.claude/` should match the new structure with all 5 layers. This is acceptance step #1.
- **Philosophy doc as marketing**: `docs/philosophy.md` doubles as both internal documentation and the way to communicate the framework's value (the "opinion" half of the bundle+opinion identity).
- **`/inspect-harness` future evolution**: v1 reports what's loaded. Future versions could compute approximate token costs per layer to help users right-size their harness.
- **Pre-existing bug in `harness-tuner.ps1`**: PowerShell 5.x parser fails on the em-dash at line 232 and a malformed regex at line 277. These bugs disappear when the script is rewritten as part of this refactor.
- **Rename `.scratch/` → `.specs/`**: the SDD working directory (PRDs + issues + INDEX) is renamed from Matt Pocock's `.scratch/` to `.specs/` for semantic clarity (the contents are specifications, not throwaway). This affects `templates/rules/sdd-process.md`, `templates/skills/to-prd/`, `templates/skills/to-issues/`, `templates/skills/tdd-cycle/`, and `README.md` — all need updating to reference `.specs/<feature>/` instead of `.scratch/<feature>/`.
- **Rebrand naming summary**: product name `harness-tuner`, CLI command `ht` (alias function), script `harness-tuner.ps1`, clone path `~/harness-tuner/`, workspace marker `.claude/.harness-tuner-version`, env var `$HARNESS_TUNER_HOME`.
