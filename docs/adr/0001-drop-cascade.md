# ADR-0001: Drop Cascade / Windsurf Support

**Status**: accepted

## Context

harness-tuner previously shipped rules and skills for two agent runtimes: Claude Code
and Cascade (Windsurf). Every change to a skill prompt or rule required updating two
parallel copies — one under `claude-code/`, one under `cascade/`. The files diverged in
practice because Claude Code and Cascade have different tool APIs, hook systems, and
context-loading mechanisms. This doubled the maintenance surface with no shared
abstraction to reduce it.

A wrapper for non-Claude-Code agents (Cursor, Windsurf, Antigravity) may come later
as a separate project, once the five-layer design is stable.

## Decision

harness-tuner v1.0.0 targets Claude Code only. The `cascade/` directory is dropped.
No compatibility shim or migration path is provided.

## Consequences

**Breaking**: Windsurf/Cascade users cannot use v1.0.0 without switching agents.

**Gained**:
- Every skill and hook is written once, for Claude Code's actual event model.
- Faster iteration: PRs, tests, and docs cover one runtime.
- Cleaner mental model: the five-layer design (rules, skills, hooks, MCP, subagents)
  maps directly to Claude Code primitives with no impedance mismatch.

For the longer-form rationale see [docs/philosophy.md](../philosophy.md).
