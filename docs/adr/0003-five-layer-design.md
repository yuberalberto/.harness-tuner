# ADR-0003: Five-Layer Harness Design

**Status**: accepted

## Context

The previous framework used only two Claude Code layers: rules (always-on markdown
loaded into every context window) and skills (on-demand slash commands). The three
remaining layers — hooks, MCP servers, and subagents — were unused.

This produced two concrete problems:

1. **Context waste**: rules like `testing.md` were loaded on every request, consuming
   tokens even during requirements grilling, git operations, or file search — tasks
   where TDD conventions are irrelevant.
2. **Agent reasoning waste**: mechanical tasks (running formatters, bookkeeping memory
   protocol calls, session start/end lifecycle) were handled via agent chain-of-thought
   instead of being automated. This consumed reasoning capacity that could be spent on
   actual problem-solving.

## Decision

Treat the Claude Code harness as five distinct layers, each chosen for its cost profile:

| Layer | Loaded | Cost | Best for |
|---|---|---|---|
| Rules | Always | High (context tokens) | Identity, memory protocol, skill router only |
| Skills | On demand | Zero until invoked | Structured workflows |
| Hooks | On event | Zero agent context | Mechanical automation |
| MCP servers | Runtime | Tool-call only | Persistent memory, live docs |
| Subagents | On demand | Isolated context | Exploration, long analysis |

Distribute opinionated defaults across all five rather than loading everything as
always-on rules.

## Consequences

**Trade-off**: more moving parts — scripts, event wiring, MCP declarations — compared to
rules-only configuration.

**Gained**:
- Always-on rules reduced to 3 files (identity, engram, SDD router).
- Formatter runs and memory lifecycle happen via hooks with zero agent-context cost.
- Long exploratory work is delegated to subagents, keeping the main context clean.

For the longer-form rationale see [docs/philosophy.md](../philosophy.md).
