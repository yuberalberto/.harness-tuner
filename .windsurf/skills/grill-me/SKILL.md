---
name: grill-me
description: >
  Generic interrogation for quick idea exploration and thinking clarification.
  Unlike grill-with-docs (which is for SDD entry), this is for casual conversation
  that does NOT commit to writing a PRD, updating CONTEXT.md, or proposing ADRs.
allowed-tools: Read
effort: low
---

# Grill Me

Expand and clarify any idea, question, or exploration through conversational interrogation.

**When to use**: You have a thought you want to explore, but it's not ready for the SDD pipeline. You just want to think out loud and refine your own understanding.

**What this does NOT do**: Create specs, update CONTEXT.md, propose ADRs, or suggest a next step like `/to-prd`. This is conversation, not structured planning.

## Process

Ask one question at a time, with a recommended answer based on what you already know.

**Rules**:

- **One question only** — never dump multiple questions. Wait for the answer.
- **Provide a recommended answer** with each question. Make an educated guess; the user
  will correct you if needed.
- **Stop when you see the signal** — the user says "done", "got it", "that's enough", or
  the idea feels clear to them.

**Focus on**:

1. **What** — What is the idea or problem in a sentence?
2. **Why** — Why does this matter? What's the motivation or pain point?
3. **Who** — Who is affected? (user, system, team, etc.)
4. **How** — How would you approach it at a high level?
5. **Constraints** — Any hard boundaries or prerequisites?

## Stop Condition

Stop asking when the user signals they are satisfied:

- "Done" / "Got it" / "That's enough"
- "I'm clear now"
- Any indication they have what they need

Summarize what was discussed in a few bullets and let them go. No "next step" suggestion.
