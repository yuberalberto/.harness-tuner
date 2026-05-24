# SDD Process — Workflow Router

Use this guide to decide which workflow applies before starting work.

## Workflow Router

| Type of change | Skill | Purpose |
|---|---|---|
| New feature, API change, data model change | `/create-spec` | Full SDD flow: grills requirements, writes PRD, decomposes into issues |
| Architectural change (new module/layer) | `/grill-with-docs` → `/improve-codebase-architecture` | Evaluate design, propose refactoring |
| Bug fix with identified cause | `/tdd-cycle` | Red-Green-Refactor cycle with Engram saves |
| Testable improvement (refactor with behavior) | `/tdd-cycle` | TDD-driven refactoring |
| Code review | `/review` | Correctness, quality, security, coverage |
| Quality/security audit | `/audit` | Dependencies, linters, secrets, patterns, tests |
| Git workflow (commit/push/PR) | `/git-flow` | Semantic commit, push, optional PR |
| Rename, move, refactor (no behavior change) | Direct (plan + approval) | No skill needed, standard permission protocol |
| Exploration / prototype | `.specs/` folder (gitignored) | Throwaway code; re-enter via create-spec if useful |
| Step back and evaluate | `/zoom-out` | Assess architecture and design decisions |

## Standalone / Escape Hatches

Use these individual skills when you need finer control over a specific step:

| Skill | Purpose |
|---|---|
| `/grill-with-docs` | Requirements grilling only — explore codebase and ask focused questions |
| `/to-prd` | Synthesize conversation context into a PRD |
| `/to-issues` | Decompose an existing PRD into independently-grabbable issues |
