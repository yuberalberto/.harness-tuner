---
name: grill-with-docs
description: Requirements grilling session that challenges your plan against the existing domain model, sharpens terminology, and updates documentation (CONTEXT.md, ADRs) inline as decisions crystallise.
---

# Grill With Docs

Stress-test a plan against the codebase and domain model before any spec or code
is written. Resolve problem, approach, and at least one acceptance criterion.

## Step 1 — Explore the Codebase

Before asking anything, explore:

1. Read `CONTEXT.md` (if it exists) to learn the domain glossary.
2. Read `docs/adr/` (if it exists) to learn past architectural decisions.
3. Scan the codebase structure and key files related to the user's topic.

Answer from code whatever you can. Only ask what the code cannot tell you.

## Step 2 — Grill

Interview the user relentlessly about every aspect of the plan. Walk down each
branch of the design tree, resolving dependencies between decisions one by one.

Rules:

- **One question at a time** — never dump all questions in a single message. Wait
  for the user's answer before continuing.
- **Provide a recommended answer** with each question. Base it on what you
  learned from the codebase.
- If a question can be answered by exploring the codebase, explore instead of
  asking.

Focus on:

1. **Problem** — What root problem does this solve? (not the solution)
2. **Scope** — What is explicitly out of scope?
3. **Approach** — Which modules/files are involved? Any new dependencies?
4. **Acceptance** — What does "done" look like? Testable criteria.

### Challenge Against the Glossary

When the user uses a term that conflicts with `CONTEXT.md`, call it out
immediately:

> "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is
> it?"

### Sharpen Fuzzy Language

When the user uses vague or overloaded terms, propose a precise canonical term:

> "You're saying 'account' — do you mean the Customer or the User? Those are
> different things."

### Discuss Concrete Scenarios

Stress-test domain relationships with specific scenarios. Invent edge cases that
force the user to be precise about boundaries between concepts.

### Cross-Reference with Code

When the user states how something works, verify against the code. Surface
contradictions:

> "Your code cancels entire Orders, but you just said partial cancellation is
> possible — which is right?"

## Step 3 — Update CONTEXT.md Inline

When a domain term is resolved during the conversation, update `CONTEXT.md`
immediately — don't batch updates.

- Create `CONTEXT.md` lazily if it doesn't exist.
- If `CONTEXT-MAP.md` exists, infer which context the term belongs to.
- Follow the format below.

`CONTEXT.md` is a glossary and nothing else. No implementation details, no specs,
no scratch notes.

### CONTEXT.md Format

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request
```

Rules:

- Be opinionated — pick the best term, list others as `_Avoid_`.
- Flag conflicts explicitly in a "Flagged ambiguities" section.
- Keep definitions tight: one or two sentences max.
- Show relationships using bold term names.
- Only include terms specific to this project's domain, not general programming
  concepts.

## Step 4 — Offer ADRs Sparingly

Only propose an ADR when **all three** are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will wonder "why?"
3. **The result of a real trade-off** — genuine alternatives existed and you
   picked one for specific reasons.

If any gate fails, skip the ADR.

### ADR Format

ADRs live in `docs/adr/` with sequential numbering: `0001-slug.md`. Create the
directory lazily when the first ADR is needed.

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

Optional sections (only when they add genuine value):

- **Status** (`proposed | accepted | deprecated | superseded by ADR-NNNN`)
- **Considered Options** — only when rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects exist

## Step 5 — Stop Condition

Stop grilling when all of the following are resolved:

- **Problem** is clearly stated (root cause, not solution)
- **Approach** is agreed upon
- **At least one acceptance criterion** is testable

Summarise what was resolved and suggest the next step (e.g. `/to-prd`, `/to-issues`,
or direct implementation).
