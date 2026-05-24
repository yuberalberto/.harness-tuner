# 05 - New skill: grill-me (generic)

## What to Build

Create `templates/skills/grill-me/SKILL.md` — a generic, open-ended grilling skill distinct from `grill-with-docs`.

Purpose: interrogate the developer about any idea, exploration, or question to help them articulate their thinking. No commitment to producing a PRD, updating CONTEXT.md, or proposing ADRs. No suggestion of a "next pipeline step".

Frontmatter `description` must clearly distinguish it from `grill-with-docs` so the agent knows when to pick which.

Body should encode the interrogation pattern:
- One question at a time, with a recommended answer.
- Stop condition based on user signaling completion ("done", "got it", "that's enough").
- No file outputs.

## Acceptance Criteria

- [ ] `templates/skills/grill-me/SKILL.md` exists with valid frontmatter (`name: grill-me`, distinguishing `description`).
- [ ] Description explicitly mentions it is for casual exploration, not SDD entry.
- [ ] Skill body does NOT touch `CONTEXT.md`, `docs/adr/`, `.specs/`, or recommend `/to-prd`.
- [ ] Invoking `/grill-me` in a project with the framework installed triggers the interrogation behavior.

## Blocked By

- 04 (`templates/skills/` directory must exist).

## Type

AFK

## User Stories Covered

- US 5b (generic grill-me for quick exploration)
