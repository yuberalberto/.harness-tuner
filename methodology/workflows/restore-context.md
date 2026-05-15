# Restore Context

Restore a specific topic's context from a previous handoff saved in Engram. Use at the start of a new session when resuming work on a specific topic.

Usage: `/restore-context [#id | topic_key]`

**Critical:** never auto-execute the "Next Actions" from the handoff. Only present and await direction.

## Steps

1. **Retrieve the handoff**
   The user provides one of:
   - **Engram ID** (e.g., `#52`) → Call `mem_get_observation(id: 52)`
   - **Topic key** (e.g., `handoff/sdd-tdd-methodology`) → Call `mem_search(query: "handoff/sdd-tdd-methodology")`

   If none provided, ask the user which handoff to restore and stop.

2. **Present the handoff**
   Display the retrieved content organized as:
   - **Task** and **Status**
   - **Changed Files** (if any)
   - **Next Actions** — labeled as **proposed, not executed**
   - **Important Context** — decisions, problems, approaches to avoid

3. **Await direction**
   Offer 2–4 concrete options based on the handoff content (e.g., "continue with next action 1", "review a specific file first"). Do nothing until the user picks one.
