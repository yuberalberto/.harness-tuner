---
name: inspect-harness
description: >
  Report what is currently loaded in the project's Claude Code harness across
  all 5 layers: rules, skills, hooks, MCP servers, and subagents. Useful for
  understanding your harness configuration without leaving the agent.
allowed-tools: Read Glob
effort: low
---

# Inspect Harness

Report what is currently configured in your project's Claude Code harness across all 5 layers.

**When to use**: You want to understand what rules, skills, hooks, MCPs, and subagents are available in your harness without manually navigating the filesystem.

## Process

### 1. List Rules

Read `.claude/rules/*.md` files and report:
- File path
- Rough character count (size indicator: small ~1KB, medium ~5KB, large >10KB)

If no rules files exist, report "none".

### 2. List Skills

Glob `.claude/skills/*/SKILL.md` (or `.claude/skills/*/` directories). For each:
- Parse the YAML frontmatter (`---...---` block)
- Extract `name:` and `description:` fields
- Report directory name, name, and first line of description

If no skills exist, report "none".

### 3. Read Hooks and MCPs from Settings

Read `.claude/settings.json` and extract:

**Hooks section** (if present):
- List event → script path mappings
- Example: `"SessionStart" → "./.claude/hooks/engram-session-start.ps1"`

**MCP Servers section** (if present):
- List server name + transport method
- Example: `"engram" (stdio), "context7" (stdio)`

**Permissions section** (if present):
- Count and summarize allow/deny entries
- Example: `"6 allow rules, 2 deny rules"`

If any section is absent or empty, report "none" for that section.

### 4. List Native Subagents

Report the native Claude Code subagents available for this harness:
- Explore (for open-ended investigation)
- Plan (for decomposition and sequencing)

These are built-in and always available.

### 5. Produce Markdown Report

Format output as structured markdown with file paths and counts:

```
# Harness Configuration Report

## Rules Layer
- `.claude/rules/identity.md` (~2 KB)
- `.claude/rules/engram.md` (~3 KB)
- `.claude/rules/sdd-process.md` (~2 KB)

## Skills Layer
- grill-me (Generic interrogation for quick idea exploration...)
- grill-with-docs (SDD entry point...)
...

## Hooks
- SessionStart → ./.claude/hooks/engram-session-start.ps1
- SessionEnd → ./.claude/hooks/engram-session-end.ps1
...

## MCP Servers
- engram (stdio)
- context7 (stdio)

## Permissions
- 8 allow rules
- 2 deny rules

## Native Subagents
- Explore (investigate and discover)
- Plan (decompose and sequence)
```

**Navigation**: Include full `.claude/` paths so the user can click/navigate to any file from the report.

