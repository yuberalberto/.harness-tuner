---
name: init-ai
description: Initialize or update a project with the AI development methodology (SDD+TDD+Engram)
---

## Bootstrap a new project

Run from your project directory:

```powershell
& "$env:USERPROFILE\init-ai\init-ai.ps1"
```

Copies the full methodology (.windsurf/ rules, workflows, skills) and generates
a `.claude/CLAUDE.md` template ready to customize.

## Update an existing project

```powershell
& "$env:USERPROFILE\init-ai\init-ai.ps1" --update
```

Shows a per-file diff (accept/reject/skip) to pull in methodology improvements
without overwriting project-specific customizations.