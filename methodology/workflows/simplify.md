# Simplify

Review recently changed code for quality, unnecessary complexity, and duplication — then fix the issues found. Use after completing a feature or fix to clean up before committing.

Optionally specify a file or path to limit scope; otherwise reviews all changes since the last commit.

## Steps

1. **Identify changed code**
   - Run `git diff` and `git diff --cached` to see all changes.
   - If a specific file or path was specified, focus only on that scope.

2. **Review for simplification opportunities**
   Look for:
   - Duplicated logic that could be extracted into a shared function
   - Unnecessary abstractions or indirection added prematurely
   - Over-engineered solutions for simple problems
   - Unused variables, imports, or dead code branches
   - Functions doing more than one thing (Single Responsibility)
   - Magic numbers or strings that should be named constants
   - Comments that just describe what the code does (remove them; keep only "why" comments)

3. **Report findings**
   List each issue with:
   - File and line reference
   - What the problem is
   - The simpler alternative

   Present the full list and wait for user approval before making changes.

4. **Apply fixes** (only after approval)
   - Make only the approved changes.
   - Do not refactor code outside the approved scope.

5. **Verify**
   - If a linter or test suite is configured, run it to confirm nothing broke.

6. **Summary**
   - List what was changed and why.
   - Note anything intentionally left for a future pass.
