# Security Review

Run a focused security review of all pending changes on the current branch. Checks for OWASP Top 10 vulnerabilities, secrets, dangerous patterns, and dependency issues. Produces a risk-rated report.

## Steps

1. **Identify changed files**
   - Run `git diff main...HEAD --name-only` (or `master...HEAD`) to list all files changed on this branch.
   - Run `git diff main...HEAD` to get the full diff for analysis.

2. **Check for exposed secrets**
   Search staged and changed files for:
   - High-entropy strings that look like API keys or tokens
   - Patterns: `AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`, `sk-[A-Za-z0-9]{20,}`, `-----BEGIN`
   - Files that should never be committed: `.env*`, `*.pem`, `id_rsa*`, `credentials.json`

   Log file paths and line numbers. **Never display the secret value.**

3. **Check for injection vulnerabilities**
   - SQL injection: string concatenation into queries instead of parameterized statements
   - Command injection: unsanitized user input passed to shell commands
   - Path traversal: user-controlled file paths without sanitization
   - XSS: user input rendered as HTML without escaping

4. **Check for dangerous patterns by language**
   - JS/TS: `eval(`, `innerHTML =`, `dangerouslySetInnerHTML`, `document.write`
   - Python: `eval(`, `exec(`, `pickle.loads`, `subprocess.*shell=True`, `yaml.load` without SafeLoader
   - Any language: hardcoded credentials, plaintext `http://` for sensitive endpoints, disabled TLS verification

5. **Check authentication and authorization**
   - Are new routes or endpoints protected by auth middleware?
   - Are there missing authorization checks (e.g., any user can access another user's data)?
   - Are session tokens or JWTs handled securely?

6. **Check new dependencies**
   - List any new packages added in this branch.
   - Check if they are well-maintained and have no known critical CVEs.

7. **Produce the report**
   Structure:

   ```
   ## Risk Level
   CRITICAL / HIGH / MEDIUM / LOW / CLEAN

   ## Findings
   [Each finding with: severity, file:line, description, recommended fix]

   ## Dependencies Added
   [Any new dependencies and their risk assessment]

   ## Verdict
   SAFE TO MERGE / FIX BEFORE MERGE / NEEDS DISCUSSION
   ```
