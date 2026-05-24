# 06 - Fix `ht update` Batch Confirmation

## What to Build

Refactor `Invoke-Update` (and `Invoke-UpdateCascade` when it exists) to collect all pending changes first, display a single summary table, and prompt the user once instead of per file.

New UX flow:
1. Scan all files silently — collect list of (file, action, +lines, -lines)
2. Display summary table:
   ```
   File                          Action    +lines  -lines
   ─────────────────────────────────────────────────────
   .claude/rules/identity.md     update    +3      -2
   .claude/skills/tdd-cycle/...  update    +0      -5
   ...
   ```
3. Single prompt: `Apply all changes? [Y/n/review]`
   - `Y` (default, Enter) — apply all, no further prompts
   - `n` — abort, nothing applied
   - `review` — enter per-file diff flow (current behavior)
4. New `--force` flag: skip prompt entirely, apply all (implies Y)

The per-file diff flow (current behavior) is preserved as the `review` path — no existing logic is deleted.

## Acceptance Criteria

- [x] `ht update` shows summary table before any changes are applied
- [x] Single confirmation prompt regardless of file count
- [x] `Y` / Enter applies all changes without further interaction
- [x] `n` exits cleanly with no files modified
- [x] `review` falls through to current per-file approval flow
- [x] `ht update --force` applies all with zero prompts
- [x] Behavior is identical for both `ht update` and `ht update -Agent cascade`

## Implementation Notes

- Added `Get-ChangeSummary` helper function to parse git diff --shortstat for line counts
- Added `Show-ChangeSummaryTable` helper function to display formatted summary table
- Refactored `Invoke-Update` to collect all changes in Phase 1 (silent scan)
- Phase 2 displays summary table before any prompts
- Phase 3 shows single confirmation prompt with Y/n/review options
- Phase 4 applies changes: if Y/Enter, applies all without further prompts; if review, falls through to per-file flow
- Added `--force` parameter to script and `Invoke-Update` function
- Updated help text to document new behavior
- Added 6 Pester tests covering all acceptance criteria
- Refactored `Invoke-UpdateCascade` to use identical batch mode pattern as `Invoke-Update`
- Added `Force` parameter to `Invoke-UpdateCascade` and updated entry point routing
- Both `ht update` and `ht update -Agent cascade` now have identical batch confirmation behavior

## Blocked By

None — can start immediately (independent of cascade work).

## Type

AFK

## User Stories Covered

- US3: `ht update` shows single summary and confirms once
- US4: `--force` flag skips all confirmations
