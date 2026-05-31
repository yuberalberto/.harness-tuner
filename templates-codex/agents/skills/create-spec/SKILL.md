---
name: create-spec
description: >
  End-to-end SDD flow in a single skill. Grills the developer, writes a PRD,
  and decomposes into vertical issues — with explicit HITL checkpoints at each
  stage transition. Suggests the first tdd-cycle without executing it.
allowed-tools: Read Glob Grep Bash Edit Write
effort: high
---

# Create Spec

Orchestrate the full SDD flow from grilling to issues without handoff or
intermediate user invocations.

## Stage 1 — Grill

Run `grill-with-docs` inline. Do NOT ask the user to invoke it separately.

Follow the full `grill-with-docs` protocol:

1. Read `CONTEXT.md` and `docs/adr/` before asking anything.
2. Ask one question at a time with a recommended answer.
3. Update `CONTEXT.md` inline as domain terms crystallise.
4. Stop when problem, approach, and at least one acceptance criterion are resolved.
5. Summarise what was resolved.

## Checkpoint A — Proceed to PRD?

After grilling is complete, present this checkpoint to the user:

> Grilling complete. Proceed to write `PRD.md`? [Y/n]

- **Y** (or Enter): continue to Stage 2.
- **n**: stop here. Do not write any files. Inform the user they can resume by
  invoking `/to-prd` when ready.

## Stage 2 — PRD

Run `to-prd` inline. Follow the full `to-prd` protocol:

1. Draft the PRD using the standard template (Problem, User Stories, Behaviors,
   Constraints, Out of Scope).
2. Present the draft for approval before writing.
3. Write `.specs/<NNN>-<feature>/PRD.md`.

## Checkpoint B — Proceed to Issues?

After `PRD.md` is written, present this checkpoint:

> `PRD.md` written. Proceed to generate issues? [Y/n]

- **Y** (or Enter): continue to Stage 3.
- **n**: stop here. Do not create the `issues/` directory. Inform the user they
  can resume by invoking `/to-issues` when ready.

## Stage 3 — Issues

Run `to-issues` inline. Follow the full `to-issues` protocol:

1. Read `.specs/<NNN>-<feature>/PRD.md` written in Stage 2 as the primary input.
2. Draft vertical slices (tracer bullets) from the PRD's Behaviors.
3. Present the breakdown for approval (granularity, dependencies, HITL/AFK).
4. Iterate until the user approves.
5. Write each issue to `.specs/<NNN>-<feature>/issues/<NNN>-<NN>-<slug>.md`.
6. Write `.specs/<NNN>-<feature>/INDEX.md` with the dependency graph and status table.

## Final Step — Suggest Next Action

After all issues are published, output the following suggestion — do NOT execute
it:

> Issues ready. Start implementation with:
>
> `/tdd-cycle <NNN>-01`
>
> where `<NNN>-01` is the full ID of the first issue.

Do not invoke `/tdd-cycle` or any other skill automatically.
