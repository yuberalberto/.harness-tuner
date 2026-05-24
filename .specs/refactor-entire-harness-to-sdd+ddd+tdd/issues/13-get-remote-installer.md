# 13 - get.ps1 (remote one-liner installer)

## What to Build

Create `get.ps1` at the repo root — a minimal, human-auditable script designed to be fetched and executed via `iwr -useb <raw-url>/get.ps1 | iex`. Responsibilities:

1. Check `git` is installed; if not, print install instructions and exit 1.
2. If `~/harness-tuner/` already exists and is a git repo → run `git pull origin main`.
3. If `~/harness-tuner/` does not exist → `git clone <repo-url> ~/harness-tuner`.
4. Invoke `~/harness-tuner/install.ps1` to finish the local setup (alias).
5. Print a success message + the next-step hint (`ht init` in your project).

The script must be under ~50 lines so a security-conscious user can audit it in one screen before piping to `iex`.

Include a smoke test in `tests/get.Tests.ps1` (opt-in / network-required) that runs `get.ps1` against a temp `$env:USERPROFILE` and verifies the clone + alias setup.

## Acceptance Criteria

- [ ] `get.ps1` exists at repo root, is under 50 lines of executable code.
- [ ] Script fails gracefully if git is missing.
- [ ] Idempotent: running `get.ps1` twice does not duplicate clones or alias entries.
- [ ] After execution, `~/harness-tuner/` is a working clone and `ht` is in `$PROFILE`.
- [ ] Smoke test passes in CI when network is available.

## Blocked By

- 01 (`install.ps1` must exist for `get.ps1` to invoke).

## Type

AFK

## User Stories Covered

- US 1 (one-line install)
