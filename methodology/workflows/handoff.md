# Handoff

Save a thematic context handoff to Engram for later restoration. Each handoff captures the current state of a specific topic/task — not the entire session.

Usage: `/handoff [topic description]`

## Steps

1. **Capture git state**
   - Run `git status`
   - Run `git branch --show-current`
   - Run `git log --oneline -5`

2. **Analyze changes**
   - Run `git diff --name-only` (unstaged)
   - Run `git diff --cached --name-only` (staged)
   - Read diffs only for files relevant to the topic being handed off.

3. **Synthesize context**
   Combine git state, relevant diffs, and current conversation context. Focus ONLY on the topic provided by the user. Identify:
   - What is being built or fixed (for this topic)
   - What works and what is missing
   - Technical decisions made
   - Approaches that were tried and failed (important to preserve)
   - Pending decisions or next actions

4. **Save to Engram**
   Call `mem_save` with:
   - **title:** `Handoff: [topic description]`
   - **type:** `decision`
   - **topic_key:** `handoff/[kebab-case-topic]`
   - **content:** Use this structure:

   ```
   ## Current State
   **Branch:** [branch-name]
   **Task:** [what is being built or fixed]
   **Status:** [what works / what is missing]

   ## Changed Files
   - `path/to/file` — [technical explanation of the change]

   ## Next Actions
   *(to be executed only upon user confirmation)*
   1. [immediate next step]
   2. [following priority]

   ## Important Context
   - [key technical decisions]
   - [problems encountered]
   - [approaches that did NOT work and must be avoided]
   ```

5. **Emit reference**
   Output a short confirmation with both references:

   ```
   ✅ Handoff saved
      ID: #[id]
      Topic key: handoff/[topic]

      To restore: /restore-context #[id]
      Or: /restore-context handoff/[topic]
   ```

## Rules

- One handoff = one topic. If the session covered multiple topics, the user should call `/handoff` once per topic.
- If no topic description is provided, ask the user what topic to hand off before proceeding.
- Never include unrelated diffs or context from other topics discussed in the same session.
- If a handoff with the same topic_key already exists, Engram will upsert (update in place).
