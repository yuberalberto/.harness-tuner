# 11 - Hook: git-guardrails-pre-bash

## What to Build

Create `templates/hooks/git-guardrails-pre-bash.ps1` — a PowerShell script invoked by Claude Code on the PreToolUse event for the Bash tool. The hook intercepts dangerous git commands and blocks them unless the user has just given explicit approval in the current turn.

Blocked commands (exit non-zero with a clear deny message that Claude Code surfaces to the user):
- `git push --force` / `git push -f` (any force-push variant).
- `git push ... main` / `git push ... master` (push to protected branches without `--allow-protected` env var).
- `git reset --hard`.
- `git clean -f` / `git clean -fd`.
- `git checkout .` / `git restore .` (mass discard).
- `git branch -D` (force-delete branches).
- `git commit --no-verify`, `--no-gpg-sign`, `-c commit.gpgsign=false` (bypass hooks/signing).

Inspired by Matt Pocock's `git-guardrails-claude-code` skill but implemented as a hook (no agent context cost).

Include Pester tests in `tests/hooks/git-guardrails-pre-bash.Tests.ps1`:
- `git push --force` → blocked (exit non-zero).
- `git status` → allowed (exit 0, passthrough).
- `git reset --hard` → blocked.
- `git commit -m "msg"` → allowed.

## Acceptance Criteria

- [ ] `templates/hooks/git-guardrails-pre-bash.ps1` exists, parses PreToolUse(Bash) payload, dispatches on the command string.
- [ ] Blocked commands exit non-zero with a stderr message explaining why.
- [ ] Allowed commands pass through (exit 0, no output).
- [ ] Pester tests cover representative blocked and allowed cases.
- [ ] After bootstrap, attempting `git push --force` from the agent prompts the block (verified manually in issue 18).

## Blocked By

None — independent of all other slices.

## Type

AFK

## User Stories Covered

- US 10 (git guardrails as hooks)
