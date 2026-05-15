# init-ai

A standalone Git repo that bootstraps any project with a unified AI development methodology,
targeting Claude Code + Cascade (Windsurf), and future-proof for other agents.

## What it provides

- **Spec-Driven + Test-Driven Development** workflow (SDD+TDD)
- **Engram memory protocol** — persistent context across sessions
- **Permission-based collaboration** — agents ask before acting
- **15 workflows** covering the full development lifecycle
- **3 SDD skills** for spec creation, validation, and test execution
- **CLAUDE.md template** with critical rules + references

## Directory structure

```
init-ai/
├── init-ai.ps1               # Bootstrap + update script
├── install.ps1               # One-time PC setup (Claude Code junctions)
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

## Quick start

### 1. Bootstrap a new project

```powershell
# From inside your project directory:
& "$env:USERPROFILE\init-ai\init-ai.ps1"
```

This copies `methodology/` to `.windsurf/` and generates `.claude/CLAUDE.md` from the template.

### 2. One-time PC setup (Claude Code)

```powershell
& "$env:USERPROFILE\init-ai\install.ps1"
```

Creates junctions in `~/.claude/skills/` so all workflows are accessible as `/workflow-name`
slash commands in Claude Code.

### 3. Update an existing project

```powershell
& "$env:USERPROFILE\init-ai\init-ai.ps1" --update
```

Shows a per-file diff. Accept (a), Reject (r), or Skip (s) each change interactively.

---

## What is project-specific (NOT in init-ai)

These belong in each project's `.windsurf/rules/` as an overlay:

- Language-specific rules (e.g., `python-rules.md`, `typescript-rules.md`)
- Runtime constraints (e.g., Python 3.8, Win7 32-bit, iOS 14+)
- Dependency lists, venvs, package manager config
- `.claude/settings.local.json` (permissions)

## Methodology overview

### For new features → `/spec-to-code`
Write a spec, get approval, implement each task via TDD, archive the spec.

### For bug fixes → `/tdd-cycle`
Red → Green → Refactor → Edge cases → Save observation.

### For code quality → `/simplify`, `/review`, `/security-review`
Post-implementation cleanup, branch review, focused security audit.

### For project health → `/audit`
Pre-push audit covering deps, linters, secrets, dangerous patterns, tests.

### For context continuity → `/handoff`, `/restore-context`
Save and restore thematic context via Engram across sessions.

---

## Relation to workload_app

`workload_app` is the reference project. Its `.windsurf/` rules and workflows are the source
of truth for `methodology/`. When workload_app conventions evolve, run `init-ai.ps1 --update`
in the other direction (or copy manually) to keep init-ai current.
