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

Prompts for chat language, then deploys both agents into your project:
`claude-code/` → `.claude/` and `cascade/` → `.windsurf/` (rules + skills).
Your `CLAUDE.md` is never generated or touched.

To skip the prompt:

```powershell
init-ai -Language "English"
```

### Step 3 — Update an existing project

```powershell
init-ai -update
```

The updater:
1. Compares your project's installed version against the latest
2. Shows the changelog entries since your version
3. For each changed file: shows a summary and prompts Accept (a), Reject (r), Skip (s), or Diff (d)
4. Stamps the new version in `.windsurf/.init-ai-version`

---

## What it provides

- **Spec-Driven + Test-Driven Development** (SDD+TDD)
- **Engram memory protocol** — persistent context across sessions
- **Permission-based collaboration** — agents ask before acting
- **Per-agent native architecture** — each agent gets rules and skills in its own format,
  no thin wrappers
- **4 always-on rules** — `sdd-process`, `testing`, `identity`, `engram`
- **9 skills** — `grill-with-docs`, `to-prd`, `to-issues`, `tdd-cycle`, `zoom-out`,
  `improve-codebase-architecture`, `audit`, `review`, `git-flow`
- **Local markdown issue tracking** — PRDs, issues, and an INDEX.md dependency graph
  under `.scratch/<feature>/`
- **Never touches CLAUDE.md** — everything ships via rules and skills

---

## Versioning

The framework uses [semantic versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for the full history.

Each bootstrapped project stores:
- `.windsurf/.init-ai-version` — framework version last applied (commit this so teammates know)

---

## Directory structure

```
init-ai/
├── init-ai.ps1               # Bootstrap + update script
├── install.ps1               # One-time PC setup (Claude Code junctions)
├── VERSION                   # Current framework version (semver)
├── CHANGELOG.md              # Release history
│
├── claude-code/              # Claude Code native format → deployed to .claude/
│   ├── rules/                # sdd-process, testing, identity, engram (always-on)
│   └── skills/               # 9 skills, each a self-contained SKILL.md
│
└── cascade/                  # Cascade (Windsurf) native format → deployed to .windsurf/
    ├── rules/                # same 4 rules with `trigger: always_on` frontmatter
    └── skills/               # same 9 skills in Cascade format
```

---

## Methodology overview

### New features → `/grill-with-docs` → `/to-prd` → `/to-issues`
Grill the requirements, synthesize a PRD, then decompose it into vertical-slice issues
with a dependency graph in `.scratch/<feature>/INDEX.md`.

### Implementation → `/tdd-cycle`
Vertical TDD: one test → one implementation → repeat. Includes a planning gate, Engram
saves, and "Document in Spec" on completion.

### Architecture → `/zoom-out`, `/improve-codebase-architecture`
Step back to evaluate design, then drive refactoring toward deeper modules.

### Code quality → `/review`, `/audit`
Branch review (correctness, quality, security, coverage) and pre-push audit (deps,
linters, secrets, dangerous patterns, tests).

### Git → `/git-flow`
Semantic commit, push, optional PR.
