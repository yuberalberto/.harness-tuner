# 15 - Docs: 3 ADRs

## What to Build

Create `docs/adr/` directory with 3 architectural decision records using the standard ADR format (title, status, context, decision, consequences):

### ADR-0001: Drop Cascade / Windsurf support
- **Context**: Maintaining two parallel agent formats (Claude Code + Cascade) doubles the work for every change.
- **Decision**: Single-agent. Claude Code only. A wrapper for other agents may come later.
- **Consequences**: Breaking change for Windsurf users. Faster iteration on Claude Code features.

### ADR-0002: Workspace-scoped distribution, zero global state
- **Context**: Global junctions in `~/.claude/skills/` create implicit state that desyncs with workspace copies.
- **Decision**: Everything ships into `.claude/` of the target project. The ONLY global touchpoint is the `ht` shell alias in `$PROFILE`.
- **Consequences**: Each project must run `ht init` separately. In exchange: perfect portability, no hidden state, no desync.

### ADR-0003: Five-layer harness design
- **Context**: The previous framework used only rules + skills, ignoring hooks, MCP, and subagents. This wasted context (always-on rules) and agent reasoning (mechanical work).
- **Decision**: Treat the Claude Code harness as 5 distinct layers, each with its own cost profile. Distribute opinionated defaults across all 5.
- **Consequences**: More moving parts to maintain. In exchange: lower context cost, less mechanical work in the agent's chain-of-thought, isolated exploration.

## Acceptance Criteria

- [ ] `docs/adr/0001-drop-cascade.md`, `0002-workspace-only.md`, `0003-five-layer-design.md` exist.
- [ ] Each ADR follows the standard format (title, status, context, decision, consequences).
- [ ] Status is `accepted` for all 3 at v1.0.0 release.
- [ ] ADRs link to `docs/philosophy.md` for the longer-form rationale.

## Blocked By

None — independent of all other slices.

## Type

HITL (architectural decisions warrant human review).

## User Stories Covered

- (Implicit — ADRs are not user-facing but support US 12 by anchoring decisions.)
