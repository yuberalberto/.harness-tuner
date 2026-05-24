# Harness-Tuner Domain

Harness-tuner is a 5-layer Claude Code configuration framework distributed per-project via a CLI tool (`ht`). This context captures the domain language used across skills, rules, and documentation.

## Language

**Harness**:
The full set of Claude Code (or Cascade) configuration layers installed in a project: rules, skills, hooks, MCP servers, and subagent recommendations.
_Avoid_: config, setup, scaffold

**Layer**:
One of the five extension points of Claude Code — rules, skills, hooks, MCP servers, subagents. Each layer has a distinct cost profile and loading strategy.
_Avoid_: component, module (when referring to Claude Code extension points)

**Template**:
Source files in `templates-claude/` or `templates-cascade/` that `ht init` / `ht update` deploy into a target project. A template is the canonical version; the deployed copy is the project's installed version.
_Avoid_: scaffold, boilerplate

**Skill**:
An on-demand slash command (`/skill-name`) loaded lazily by Claude Code. Lives in `.claude/skills/<name>/SKILL.md`. Zero context cost until invoked.
_Avoid_: command, plugin, tool (when referring to Claude Code skills)

**SDD (Spec-Driven Development)**:
The harness-tuner workflow for implementing features: requirements grilling → PRD → issue decomposition → TDD implementation. Enforced by the `/create-spec` skill.
_Avoid_: spec-first, design-first

**HITL (Human In The Loop)**:
A workflow stage that requires explicit human confirmation before proceeding. In `/create-spec`, every transition between stages is HITL — no automatic advancement.
_Avoid_: manual, interactive (when referring to the HITL pattern)

**AFK (Away From Keyboard)**:
A workflow stage or issue that can be implemented without human interaction. Used in issue decomposition to classify slices.
_Avoid_: automated, unattended

**Bootstrap**:
The `ht init` operation that deploys harness templates into a fresh project's `.claude/` (or `.windsurf/`) directory for the first time.
_Avoid_: install (reserved for the one-time `install.ps1` shell alias setup), init

**Workspace Marker**:
The `.harness-tuner-version` file stamped inside `.claude/` (or `.windsurf/`) after a successful bootstrap or update. Its presence signals harness-tuner is installed; its content is the framework version.
_Avoid_: version file, stamp file

**create-spec**:
The `/create-spec` orchestrator skill that runs the full SDD pre-implementation flow: `grill-with-docs` → `to-prd` → `to-issues`. Stops at issues and suggests `/tdd-cycle` — never starts it automatically.
_Avoid_: sdd (as a command name), plan, design

**Spec Number**:
A zero-padded 3-digit integer (`001`–`999`) embedded in the spec folder name: `001-add-cascade-adapter/`. Assigned sequentially at spec creation time. Permanent — does not change if other specs are deleted or reordered.
_Avoid_: spec ID, feature number

**Issue ID**:
A globally unique reference of the form `NNN-NN` — spec number + 2-digit issue sequence within that spec. Example: `005-03` = spec 5, issue 3. Embedded in both the issue filename (`005-03-slug.md`) and usable as a standalone reference in commits and PRs.
_Avoid_: issue number (ambiguous without spec context)

**Legacy Spec**:
A spec folder created before the `NNN-slug` naming convention was adopted. Left as-is — renaming legacy specs breaks commit history references and adds no value.
_Avoid_: old spec, unnumbered spec
