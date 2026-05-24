## Problem Statement

The harness distributes templates for two IDE agents — Claude Code and Cascade. The source
directories use inconsistent names: `templates-cascade/` clearly signals its target agent,
but `templates/` is generic and gives no indication that it contains Claude Code–specific
files. A developer reading the repo or the script cannot tell at a glance which directory
maps to which agent.

## Solution

Rename `templates/` to `templates-claude/`, establishing a consistent `templates-<agent>`
convention across both source directories. No behavior changes — only paths and their
references.

## User Stories

1. As a harness-tuner contributor, I want source directories named by their target agent,
   so that I can navigate the repo without needing to recall which `templates/` is for.
2. As a contributor adding a new agent adapter, I want a clear naming convention to follow,
   so that I know to create `templates-<agent>/` without asking.
3. As a code reviewer, I want path references in `harness-tuner.ps1` to be self-documenting,
   so that I can audit bootstrap and update logic without tracing directory names back to
   their purpose.

## Implementation Decisions

- Rename the physical directory `templates/` → `templates-claude/` at the repo root.
- Update all string references from `"templates"` to `"templates-claude"` in: the main
  script and the full test suite (unit + hook tests). No logic changes — path variables only.
- The `templates-cascade/` directory is unchanged.
- `.specs/` documents (PRDs, issues, INDEX files) are treated as historical record and are
  not updated — they reference the old name by design.
- `README.md` prose ("Update the current project against the latest templates") refers to
  the concept, not the path — no change needed there.
- The `templates-<agent>` convention opens the door cleanly to future adapters
  (e.g. `templates-cursor/`, `templates-copilot/`) without any further naming decisions.

## Testing Decisions

- Tests are path-reference updates only; no new test cases are needed.
- All existing tests must pass unchanged after the rename — they are the verification gate.
- Prior art: `tests/harness-tuner.Tests.ps1` constructs stub directories matching the repo
  layout; those stubs must reference `templates-claude/`.

## Out of Scope

- Renaming `templates-cascade/`.
- GitHub repo URL updates (`yuberalberto/.harness-tuner` → `yuberalberto/harness-tuner`).
- Sparse-checkout in `get.ps1` for cleaner installation.
- Any behavior change to `ht init` or `ht update`.

## Further Notes

The GitHub remote was renamed from `.harness-tuner` to `harness-tuner` (dot removed so
Windsurf can index the dev folder). The installation directory `~/.harness-tuner` is
intentionally kept with the leading dot — it is hardcoded in `get.ps1` as the clone target,
independent of the remote name. Only the GitHub URL references in `get.ps1` and `README.md`
need updating to reflect the new remote name (tracked separately).
