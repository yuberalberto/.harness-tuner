# init-ai

Bootstrap any project with a structured AI development methodology.
Works with Claude Code + Cascade (Windsurf). Future-proof for other agents.

---

## Quick start

### Step 1 — Install (once per machine)

Clone this repo and run the installer:

```powershell
git clone https://github.com/your-username/init-ai.git $env:USERPROFILE\init-ai
& "$env:USERPROFILE\init-ai\install.ps1"
```

This sets up Claude Code skill shortcuts and adds the `init-ai` command to your shell. Reload your profile to use it immediately:

```powershell
. $PROFILE
```

### Step 2 — Bootstrap a new project

Navigate to your project directory, then run:

```powershell
init-ai
```

Prompts for project name (defaults to the current folder name) and chat language.
Copies the methodology to `.windsurf/` and generates `.claude/CLAUDE.md`.

To skip the prompts:

```powershell
init-ai -ProjectName "my-app" -Language "English"
```

### Step 3 — Update an existing project

```powershell
init-ai -update
```

The updater:
1. Compares your project's installed version against the latest
2. Shows the changelog entries since your version
3. For each changed file: shows a diff and prompts Accept (a), Reject (r), or Skip (s)
4. Stamps the new version in `.windsurf/.init-ai-version`
5. Detects changes to the CLAUDE.md template and warns if manual review is needed

---

## What it provides

- **Spec-Driven + Test-Driven Development** (SDD+TDD)
- **Engram memory protocol** — persistent context across sessions
- **Permission-based collaboration** — agents ask before acting
- **14 workflows** covering the full development lifecycle
- **3 SDD skills** for spec creation, validation, and test execution
- **CLAUDE.md template** with critical rules inline + workflow references

---

## Versioning

The framework uses [semantic versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for the full history.

Each bootstrapped project stores:
- `.windsurf/.init-ai-version` — framework version last applied (commit this so teammates know)
- `.claude/CLAUDE.md` — contains an `<!-- init-ai:hash -->` marker tracking the template version applied

---

## Directory structure

```
init-ai/
├── init-ai.ps1               # Bootstrap + update script
├── install.ps1               # One-time PC setup (Claude Code junctions)
├── VERSION                   # Current framework version (semver)
├── CHANGELOG.md              # Release history
│
├── methodology/              # Source of truth (agent-agnostic)
│   ├── rules/                # code-standards, sdd-process, security, testing
│   ├── workflows/            # 15 development workflows
│   └── skills/               # create-spec, run-tests, validate-spec
│
├── adapters/
│   ├── cascade/              # (empty — methodology/ is already Cascade format)
│   └── claude-code/
│       ├── CLAUDE.md.template
│       └── skills/           # Thin wrappers: one per workflow + init-ai meta
│
└── templates/
    └── specs/                # Empty specs/ directory seed
```

---

## Methodology overview

### New features → `/spec-to-code`
Write a spec, get approval, implement each task via TDD, archive the spec.

### Bug fixes → `/tdd-cycle`
Red → Green → Refactor → Edge cases → Save observation.

### Code quality → `/simplify`, `/review`
Post-implementation cleanup and branch review (correctness, quality, security, coverage).

### Project health → `/audit`
Pre-push audit: deps, linters, secrets, dangerous patterns, tests.

### Context continuity → `/handoff`, `/restore-context`
Save and restore thematic context via Engram across sessions.
