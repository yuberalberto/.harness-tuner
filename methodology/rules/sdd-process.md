# SDD Process — When to Use What

This project uses Spec-Driven Development (SDD) combined with Test-Driven
Development (TDD), but ceremony scales with the size of the change. Use the
guide below to decide what workflow applies before starting work.

## Decision Guide

| Type of change                                  | Workflow                          |
|-------------------------------------------------|-----------------------------------|
| New feature, API change, data model change      | `/spec-to-code`                   |
| Architectural change (new module/layer)         | `/spec-to-code`                   |
| Bug fix with identified cause                   | `/tdd-cycle`                      |
| Testable improvement (refactor with behavior)   | `/tdd-cycle`                      |
| Rename, move, refactor (no behavior change)     | Direct (plan + user approval)     |
| Update of error/UI messages                     | Direct (plan + user approval)     |
| Dependency update                               | Direct (plan + user approval)     |
| Typo, formatting, .gitignore, README            | Direct (no approval needed)       |
| Exploration / prototype                         | `scratch/` folder (gitignored)    |

## Workflow Summaries

### `/spec-to-code` (full SDD+TDD)
- Writes a single `specs/[feature]/spec.md` (no EARS, no separate design doc)
- Requires explicit user approval before coding
- Forces `mem_save` after approval and again at completion
- Implements each task via `/tdd-cycle`
- Archives the spec to `specs/archived/` when all tasks are done

### `/tdd-cycle` (TDD only)
- No spec required
- Red → Green → Refactor → Edge cases → Save observation → Mark complete
- Forces `mem_save` at Step 6 unless the task was purely mechanical

### Direct (Permission Protocol)
- Propose a concise plan (2-6 lines)
- List exact files to be modified
- Wait for user approval before editing
- Run existing tests after the change to confirm no regression
- No new tests required

### Exploration (`scratch/`)
- Add `scratch/` to `.gitignore` (the bootstrap does this)
- Throwaway code lives there
- If the experiment proves useful, re-enter via `/spec-to-code` or `/tdd-cycle`
- Otherwise delete the scratch file

## Living Documentation

This project does NOT maintain:
- `implementation-log.md` (Engram replaces it)
- Separate `design.md` and `requirements.md` (consolidated into `spec.md`)
- EARS-format requirements (free-form text in `spec.md` is fine)
- `PROJECT_MAP.md` (the agent explores the repo on demand)

What IS the living documentation:
- **Tests** — executable spec, always in sync with code (CI breaks if not)
- **Engram observations** — decision trail, accumulated via workflow-forced saves
- **Git log** — chronological history
- **Archived specs** — original intent and trade-offs in `specs/archived/`

## Ceremony Anti-Patterns

Avoid:
- Writing a spec for a typo fix
- Skipping `mem_save` "because it's obvious" (it won't be in 3 months)
- Treating an archived spec as something to maintain (it's a historical record)
- Letting `specs/` accumulate completed features (archive them)
