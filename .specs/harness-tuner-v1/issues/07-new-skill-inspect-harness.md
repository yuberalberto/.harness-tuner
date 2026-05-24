# 07 - New skill: inspect-harness

## What to Build

Create `templates/skills/inspect-harness/SKILL.md` — a skill that, when invoked, makes the agent report what is currently loaded in the project's Claude Code harness across all 5 layers.

The agent (when running this skill) should:
1. Read `.claude/rules/*.md` and list each rule with its rough character/token count.
2. List the skills available in `.claude/skills/` (name + description from frontmatter).
3. Read `.claude/settings.json` and list:
   - Hooks declared (event → script path).
   - MCP servers declared (name + transport).
   - Permissions baseline (count of allow/deny entries).
4. List native subagents available in Claude Code (Explore, Plan, etc.).
5. Output a structured markdown report in the chat.

## Acceptance Criteria

- [ ] `templates/skills/inspect-harness/SKILL.md` exists with valid frontmatter.
- [ ] Invoking `/inspect-harness` in a bootstrapped project produces a report covering all 5 layers.
- [ ] If a layer is absent (e.g., no hooks declared), the report says "none" rather than failing.
- [ ] The report includes file paths so the user can navigate from the report.

## Blocked By

- 04 (`templates/skills/` must exist).

## Type

AFK

## User Stories Covered

- US 6 (`/inspect-harness` reports loaded harness)
