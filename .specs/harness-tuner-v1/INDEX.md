# Harness-Tuner v1.0.0 — Issues

## Dependency Graph

```
Independent (ready from day 0):
─────────────────────────────────
[01] install.ps1            ─→ [13] get.ps1                      ┐
[02] harness-tuner.ps1                                            │
[03] templates/rules/                                             │
[04] templates/skills/      ─┬─→ [05] grill-me                    │
                             ├─→ [06] code-standards              │
                             └─→ [07] inspect-harness             │
[08] hook engram-start ─┐                                         ├─→ [17] CHANGELOG ─→ [18] Dogfooding
[09] hook engram-end   ─┤                                         │
[10] hook format       ─┼─→ [12] settings.json                    │
[11] hook git-guards   ─┘                                         │
[14] docs/philosophy.md ──────────┐                               │
                                  ├─→ [16] README                 │
[13] get.ps1 ─────────────────────┘                               │
[15] ADRs                                                         ┘
```

**Parallelization windows**:
- **Day 0**: 01, 02, 03, 04, 08, 09, 10, 11, 14, 15 (10 issues simultaneously, no deps).
- **After 01**: 13.
- **After 04**: 05, 06, 07 simultaneously.
- **After 08+09+10+11**: 12.
- **After 13+14**: 16.
- **Final**: 17 → 18.

## Status Table

| Issue | Title | Type | Status | Blocked By |
|-------|-------|------|--------|-----------|
| 01 | `install.ps1` simplified (alias only) | AFK | `done` | — |
| 02 | `harness-tuner.ps1` (subcommands + coexistence) | AFK | `done` | — |
| 03 | `templates/rules/` (3 rules) | AFK | `done` | — |
| 04 | `templates/skills/` migration + `.specs/` rename + inline testing | AFK | `done` | — |
| 05 | New skill: `grill-me` | AFK | `done` | 04 ✓ |
| 06 | New skill: `code-standards` | AFK | `done` | 04 ✓ |
| 07 | New skill: `inspect-harness` | AFK | `done` | 04 ✓ |
| 08 | Hook: `engram-session-start` | AFK | `done` | — |
| 09 | Hook: `engram-session-end` | AFK | `done` | — |
| 10 | Hook: `format-post-edit` | AFK | `done` | — |
| 11 | Hook: `git-guardrails-pre-bash` | AFK | `done` | — |
| 12 | `templates/settings.json` declarations | AFK | `ready` | 08-11 ✓ |
| 13 | `get.ps1` remote installer | AFK | `done` | 01 ✓ |
| 14 | Doc: `docs/philosophy.md` | HITL | `done` | — |
| 15 | Docs: 3 ADRs | HITL | `done` | — |
| 16 | README rewrite | AFK | `ready` | 13 ✓, 14 ✓ |
| 17 | CHANGELOG v1.0.0 entry | AFK | `ready` | most ✓ |
| 18 | Dogfooding + acceptance verification | HITL | `blocked` | all |

## Status Legend

- `ready` — dependencies met, can be started.
- `blocked` — waiting on another issue.
- `in-progress` — actively being worked.
- `done` — completed and merged.

## Agent Workflow

1. Agent reads this INDEX.
2. Picks all `ready` issues (initially: 01, 02, 03, 04, 08, 09, 10, 11, 14, 15).
3. For each, launches `/tdd-cycle` (or appropriate workflow for HITL/docs).
4. On completion, the worker updates this INDEX (status → `done`), and unblocks any dependents (changes `blocked` → `ready` where deps are met).
