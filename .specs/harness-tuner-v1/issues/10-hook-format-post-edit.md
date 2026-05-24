# 10 - Hook: format-post-edit

## What to Build

Create `templates/hooks/format-post-edit.ps1` — a PowerShell script invoked by Claude Code on the PostToolUse event for Edit / Write / NotebookEdit tools. The hook receives the modified file path from the payload and runs the language-appropriate formatter:

- `*.js`, `*.jsx`, `*.ts`, `*.tsx`, `*.json`, `*.md` → prettier (if installed).
- `*.py` → ruff format (if installed), else black.
- `*.go` → gofmt.
- `*.rs` → rustfmt.
- `*.ps1` → no-op (PowerShell has no widely-adopted formatter).
- Unknown extension → no-op with silent exit.

The hook should NOT fail if the formatter binary is missing — it logs a warning and exits 0. The user installs formatters per project as preferred.

Include Pester tests in `tests/hooks/format-post-edit.Tests.ps1` covering:
- JS file → prettier invocation.
- Python file → ruff invocation.
- Unknown extension → silent no-op.
- Missing formatter binary → warning + exit 0 (no crash).

## Acceptance Criteria

- [ ] `templates/hooks/format-post-edit.ps1` exists and parses PostToolUse payload to extract the modified file path.
- [ ] Formatter dispatch table covers JS/TS/Python/Go/Rust extensions.
- [ ] Missing formatter does not break the script.
- [ ] Pester tests cover dispatch + missing-binary cases.
- [ ] After bootstrap, editing a JS file in a project triggers prettier (verified manually in issue 18).

## Blocked By

None — independent of all other slices.

## Type

AFK

## User Stories Covered

- US 3 (hooks for formatters)
