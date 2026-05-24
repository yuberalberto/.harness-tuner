# PRD: Cascade Adapter + Update UX Fix

## Problem Statement

El harness-tuner solo soporta Claude Code. Usuarios de Windsurf/Cascade no pueden beneficiarse del mismo harness (rules, skills, hooks, MCP). Además, `ht update` solicita confirmación archivo por archivo — en proyectos con 25+ archivos desplegados esto es inutilizable. Por último, el servidor MCP `context7` fue incluido por error en el harness y debe eliminarse de todas las configuraciones generadas.

## Solution

1. Eliminar `context7` de todo el proyecto (`templates/settings.json`, `README.md`, `CHANGELOG.md`).
2. Añadir `--agent cascade` a `ht init` y `ht update` para desplegar el harness en `.windsurf/` usando una nueva carpeta `templates-cascade/`.
3. Rediseñar `ht update` para confirmar en batch (resumen + una sola confirmación) en lugar de archivo por archivo.

## User Stories

1. As a Windsurf/Cascade developer, I want to run `ht init -Agent cascade` to deploy rules, skills, hooks, and MCP into `.windsurf/`, so that I get the same harness behavior I would get in Claude Code.
2. As a Windsurf/Cascade developer, I want to run `ht update -Agent cascade` to update my `.windsurf/` harness against the latest templates-cascade/, so that I stay current with framework improvements.
3. As any developer, I want `ht update` to show me a single summary table of all pending changes and confirm once, so that I don't have to approve 25 files individually.
4. As any developer, I want a `--force` flag on `ht update` to skip all confirmations, so that I can automate updates in scripts or CI.
5. As any developer, I want context7 absent from all generated harness configs, so that only tools I actually use (engram) are declared.

## Implementation Decisions

1. **`templates-cascade/` folder (6 files)** — contains only what differs from Claude Code:
   - `rules/identity.md`, `rules/engram.md`, `rules/sdd-process.md` — same content as `templates/rules/` but with YAML frontmatter (`trigger: always_on`, `description: ...`)
   - `hooks/format-post-edit.ps1` — adapted: reads `tool_info.file_path` instead of `tool_input.file_path`
   - `hooks/git-guardrails.ps1` — adapted: reads `tool_info.command_line` instead of `tool_input.command`; block response is plain text (not JSON)
   - `hooks.json` — Cascade hooks config: `post_write_code` → format script, `pre_run_command` → guardrails script

2. **Skills reuse** — Cascade's native skill format (`.windsurf/skills/<name>/SKILL.md` + support files) is identical to Claude Code's. `Invoke-BootstrapCascade` copies `templates/skills/<name>/` directly to `.windsurf/skills/<name>/` without transformation.

3. **Hooks mapping**:
   - `PostToolUse(Edit|Write|NotebookEdit)` → `post_write_code`
   - `PreToolUse(Bash)` → `pre_run_command`
   - `SessionStart` / `Stop` → no equivalent in Cascade (omitted; session memory handled via `identity.md` rule)

4. **MCP** — Cascade MCP is global-only (`~/.codeium/windsurf/mcp_config.json`). A new `Merge-McpConfigJson` function performs an additive merge of the `engram` server entry only. context7 removed from `templates/settings.json` (Claude Code) as well.

5. **`ht update` batch mode** — `Invoke-Update` (and `Invoke-UpdateCascade`) will:
   - Collect all changed files first (no prompts during scan)
   - Display a summary table: `file | +N | -N | action`
   - Ask once: `Apply all changes? [Y/n/review]`
   - `Y` (default) — applies all without further prompts
   - `n` — aborts, no changes applied
   - `review` — falls back to the current per-file diff flow
   - `--force` flag skips the summary prompt entirely (implies Y)

6. **New `--agent` parameter** — `[string]$Agent = "claude-code"` added to CLI params. Routing in entry point:
   ```
   init   + claude-code → Invoke-Bootstrap
   init   + cascade     → Invoke-BootstrapCascade
   update + claude-code → Invoke-Update
   update + cascade     → Invoke-UpdateCascade
   ```

7. **New PS functions in `harness-tuner.ps1`**:
   - `Invoke-BootstrapCascade` — deploys templates-cascade/ + templates/skills/ to .windsurf/
   - `Invoke-UpdateCascade` — updates .windsurf/ against templates
   - `Merge-HooksJson` — additive merge for .windsurf/hooks.json
   - `Merge-McpConfigJson` — additive merge for ~/.codeium/windsurf/mcp_config.json

8. **Spec folder naming convention** — `to-prd` skill updated to enforce verb-first slugs: `add-*`, `fix-*`, `remove-*`, `refactor-*`, `improve-*`. This makes the purpose of a spec immediately clear from its folder name (e.g., `add-cascade-support`, `fix-update-prompts`).

## Testing Decisions

- Verify `ht init -Agent cascade` creates `.windsurf/rules/`, `.windsurf/skills/`, `.windsurf/hooks/`, `.windsurf/hooks.json`, and merges `~/.codeium/windsurf/mcp_config.json`
- Verify skills are copied with all support files intact (SKILL.md + all .md siblings)
- Verify hook scripts correctly parse Cascade payload format (tool_info.*)
- Verify `ht update` in batch mode issues exactly one confirmation prompt regardless of file count
- Verify `ht update --force` applies all changes with zero prompts
- Verify context7 is absent from all files in templates/ and generated output

## Out of Scope

- JetBrains / other non-Windsurf IDEs
- Automatic migration of existing `.windsurf/` deployments from prior versions
- `.windsurf/workflows/` — harness-tuner uses Skills, not Workflows, for Cascade
- Per-project MCP config in Cascade (not supported by the platform)
- Cursor, Antigravity, or any other agent
