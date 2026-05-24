Harness-tuner is an opinionated 5-layer Claude Code harness configuration: skills + hooks + MCP + rules + subagent recommendations, distributed per-project.

---

## Install

**One-liner** (recommended):

```powershell
iwr -useb https://raw.githubusercontent.com/yuberalberto/harness-tuner/main/get.ps1 | iex
```

**Manual**:

```powershell
git clone https://github.com/yuberalberto/harness-tuner.git $env:USERPROFILE\harness-tuner
& "$env:USERPROFILE\harness-tuner\install.ps1"
```

After either path, reload your shell profile:

```powershell
. $PROFILE
```

## Quick start

In any project directory:

```powershell
ht init
```

This deploys all five harness layers into `.claude/`. Run `ht --help` to see all subcommands.

## What you get

`ht init` copies a curated set of files into your project's `.claude/`:

**Rules (3)** — minimal, always-on, loaded every session:
- `identity.md` — role, language, anti-sycophancy, permission protocol
- `engram.md` — when and what to save to persistent memory
- `sdd-process.md` — task-type → skill routing table

**Skills (12)** — lazy-loaded, invoked on demand:
- `grill-me` — generic idea interrogation, no SDD commitment
- `grill-with-docs` — SDD entry point; updates CONTEXT.md, proposes ADRs
- `to-prd` — synthesize conversation into a PRD under `.specs/<feature>/`
- `to-issues` — decompose PRD into vertical-slice issues with dependency graph
- `tdd-cycle` — Red-Green-Refactor with Engram saves and spec updates
- `code-standards` — style and naming conventions, best used at Refactor step
- `inspect-harness` — reports loaded rules, skills, hooks, and MCPs
- `audit` — pre-push audit: deps, linters, secrets, dangerous patterns, tests
- `review` — branch review: correctness, quality, security, coverage
- `git-flow` — semantic commit, push, optional PR
- `zoom-out` — step back and map architecture from domain glossary
- `improve-codebase-architecture` — find deepening opportunities; propose refactors

**Hooks (4)** — scripts on Claude Code lifecycle events, zero agent-context cost:
- `engram-session-start` — calls `mem_context` at session start
- `engram-session-end` — calls `mem_session_summary` at Stop
- `format-post-edit` — runs prettier / ruff / gofmt after Edit or Write
- `git-guardrails-pre-bash` — blocks destructive git commands before execution

**MCP servers** — declared in `.claude/settings.json`, merged non-destructively on init:
- `engram` (required) — cross-session memory via `mem_*` tools
- `context7` (recommended) — up-to-date library documentation lookup

Server binaries are the user's responsibility (treat like git or node).

## Updating

Update the current project against the latest templates:

```powershell
ht update
```

Pull the latest framework version to your local clone:

```powershell
ht self-update
```

## Why this exists

Claude Code exposes five distinct extension points. Most projects use one or two. harness-tuner is an opinion about how all five should be composed: three minimal always-on rules (not eight), mechanical work automated as hooks with zero context cost, long exploration delegated to subagents to keep the main session clean, and everything scoped to the project workspace — no global junctions, no hidden state. The full rationale is in [docs/philosophy.md](docs/philosophy.md). Architecture decisions are recorded in [docs/adr/](docs/adr/).

## Supported agents

**Claude Code only.** Wrappers for other agents (Cursor, Windsurf, Antigravity) may come in a later release.

## License

No license file yet — contributions are accepted on an as-is basis until one is added. See [CHANGELOG.md](CHANGELOG.md) for version history.

## Contributing

Open an issue or PR on GitHub. No formal CONTRIBUTING guide yet.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

*Previously known as init-ai.*
