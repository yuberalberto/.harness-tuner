# ADR-0002: Workspace-Scoped Distribution, Zero Global State

**Status**: accepted

## Context

The legacy install created junctions from `~/.claude/skills/` to the cloned repo.
This introduced implicit global state: two copies of each skill existed (the repo
source and the junction target), and editing one silently left the other stale.
Users working across multiple projects could not tell which version was active in
which project. Debugging a skill regression required tracing junction chains instead
of reading a local file.

Additionally, any skill or rule present in `~/.claude/` is always-on for every project
on the machine — even projects that don't use harness-tuner. This violated the
principle of least surprise.

## Decision

All harness-tuner files ship into the target project's `.claude/` directory. The only
global touchpoint is the `ht` shell alias function written to
`$PROFILE.CurrentUserAllHosts` during `install.ps1`. No files are placed in
`~/.claude/`, `~/.windsurf/`, or any other tool-specific global directory.

## Consequences

**Trade-off**: each project must run `ht init` independently. There is no "install once,
use everywhere" bootstrap.

**Gained**:
- Perfect portability: a project's `.claude/` is self-contained and reproducible from
  `templates/`.
- No hidden state: the harness version active in a project is visible in
  `.claude/.harness-tuner-version`.
- No desync: editing `.claude/rules/identity.md` only affects the current project.
- Predictable per-project harness: CI, teammates, and subagents all read the same files.

For the longer-form rationale see [docs/philosophy.md](../philosophy.md).
