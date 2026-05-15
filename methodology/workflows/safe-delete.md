# Safe Delete

Safely delete a file, component, route, or block of code without breaking the project. Use when removing features, cleaning up unused code, or refactoring with deletions.

Specify what to delete after the command (e.g., `/safe-delete UserCard component`).

## Steps

1. **Confirm target and intent**
   - Clarify exactly what will be deleted and what the expected end state is.
   - If ambiguous, ask before proceeding.

2. **Dependency scan**
   - Search for all imports, references, and usages of the target across the codebase.
   - Check routes, tests, and documentation that mention it.

3. **Impact report**
   - List every file that will break or need updating after deletion.
   - Categorize: breaking changes vs. cleanup-only.
   - Present the report and wait for explicit approval before continuing.

4. **Execute deletion** (only after approval)
   - Delete the target.
   - Remove orphaned imports, routes, and assets.
   - Update or delete related tests and docs.

5. **Verify**
   - Confirm no broken references remain.
   - If applicable, run lint or build to verify the project still compiles.

6. **Summary**
   - List files deleted and files modified.
   - Note anything left for the user to review manually.
