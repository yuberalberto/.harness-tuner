# Review

Review all changes on the current branch compared to the base branch. Covers correctness, code quality, security, and test coverage. Produces a structured report.

Optionally specify a base branch (e.g., `/review main`); defaults to `main` or `master`.

## Steps

1. **Identify the scope**
   - Run `git branch --show-current` to get the current branch.
   - Run `git log main..HEAD --oneline` (or `master..HEAD`) to list all commits on this branch.
   - Run `git diff main...HEAD` to get the full diff.

2. **Understand the intent**
   - Read the commit messages to understand what the branch is trying to achieve.
   - Summarize the stated purpose in one sentence before proceeding.

3. **Review for correctness**
   - Does the code do what the commit messages claim?
   - Are there edge cases not handled?
   - Are there off-by-one errors, null/undefined issues, or incorrect assumptions?

4. **Review for code quality**
   - Is the code readable and well-named?
   - Are functions doing more than one thing?
   - Is there duplicated logic that could be shared?
   - Are there unnecessary abstractions or premature optimizations?

5. **Review for security**
   - Any unsanitized user input reaching a command, query, or renderer?
   - Any secrets or credentials hardcoded?
   - Any new dependencies introduced? Are they trustworthy and up to date?

6. **Review for test coverage**
   - Are the changed code paths tested?
   - Do the existing tests still make sense after the change?
   - Are there critical branches left untested?

7. **Produce the report**
   Structure:

   ```
   ## Summary
   [One sentence: what this branch does]

   ## Issues — Critical
   [Must fix before merge]

   ## Issues — Minor
   [Should fix; warn if skipped]

   ## Suggestions
   [Optional improvements]

   ## Verdict
   APPROVE / REQUEST CHANGES / DISCUSS
   ```
