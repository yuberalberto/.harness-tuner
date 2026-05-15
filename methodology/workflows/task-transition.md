# Task Transition

Archive a completed task and set up the next one. Updates the project context file and moves task docs to archive. Use when finishing a feature and starting the next.

Specify the completed task and the new task after the command (e.g., `/task-transition "gui redesign" "session logging"`).

## Steps

1. **Validate completion**
   - Read the current task doc if it exists (look in `docs/` or the project root).
   - Confirm all checklist items are done.
   - Ask user for confirmation before proceeding.

2. **Archive completed task**
   - If a task doc exists in `docs/`, move it to `docs/archive/` with filename: `archived-[task-name]-YYYY-MM-DD.md`
   - Create `docs/archive/` if it doesn't exist.

3. **Update the project context file**
   Look for the main context/documentation file at the repo root (common names: `CONTEXT.md`, `README.md`, `AGENTS.md`). Update it:
   - Set "current task" to the new task.
   - Clear completed items from the next steps section.
   - Add the first steps for the new task.

4. **Create new task doc** (if the task is non-trivial)
   Create `docs/[new-task-name].md` with:
   - Progress checklist
   - Key technical decisions to make
   - Files likely to be modified
   - Risks or open questions

5. **Summary**
   - Confirm what was archived.
   - Show the updated context file state.
   - List the first 2–3 concrete next steps for the new task.
