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
   - **Exposed secrets**: High-entropy strings, patterns (`AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`, `sk-[A-Za-z0-9]{20,}`, `-----BEGIN`), sensitive files (`.env*`, `*.pem`, `id_rsa*`, `credentials.json`). Log file:line — never display secret values.
   - **Injection vulnerabilities**: SQL (string concatenation into queries instead of parameterized statements), command injection (unsanitized user input passed to shell), path traversal (user-controlled file paths without sanitization), XSS (user input rendered as HTML without escaping).
   - **Dangerous patterns**: JS/TS: `eval(`, `innerHTML =`, `dangerouslySetInnerHTML`, `document.write`. Python: `eval(`, `exec(`, `pickle.loads`, `subprocess.*shell=True`, `yaml.load` without SafeLoader. Any language: hardcoded credentials, plaintext `http://` for sensitive endpoints, disabled TLS verification.
   - **Auth and authorization**: New routes or endpoints protected by auth middleware? Missing authorization checks (any user accessing another user's data)? Session tokens or JWTs handled securely?
   - **New dependencies**: List any new packages. Are they well-maintained with no known critical CVEs?

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
