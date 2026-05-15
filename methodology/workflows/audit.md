# Audit

Run a comprehensive pre-push audit covering dependency vulnerabilities, linters, secrets, dangerous patterns, and tests. Use before pushing changes or when reviewing code safety. Optionally specify a path to limit scope; otherwise the whole repo is audited.

**Critical:** do not stop on intermediate findings. Collect everything and present a consolidated report at the end.

## Steps

1. **Detect project stack**
   Identify the manifest(s) present in the repo root:
   - `package.json` → Node.js (npm/yarn/pnpm)
   - `requirements.txt` / `pyproject.toml` / `Pipfile` → Python
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pom.xml` / `build.gradle` → Java/Kotlin
   - `composer.json` → PHP
   - `Gemfile` → Ruby

   If no manifest is found, skip dependency and test steps and note it in the report.

2. **Dependency vulnerability scan**
   Run the matching tool for the detected stack:
   - Node: `npm audit` / `yarn audit` / `pnpm audit`
   - Python: `pip-audit` (fallback: `safety check`)
   - Rust: `cargo audit`
   - Go: `govulncheck ./...`
   - Ruby: `bundle audit`
   - PHP: `composer audit`
   - Java (Maven): `mvn dependency-check:check`

   Verify the lockfile is in sync with the manifest. Log critical/high findings.

3. **Static analysis (linters)**
   Detect configured linters by config files:
   - `.eslintrc*`, `biome.json` → run ESLint / Biome
   - `pyproject.toml` with ruff/flake8 sections → run the configured linter
   - `.rubocop.yml` → run RuboCop
   - `.golangci.yml` → run golangci-lint
   - `clippy.toml` or Rust project → run `cargo clippy`

   If no linter is configured, note it and skip.

4. **Secret detection**
   Search the working tree and staged area for:
   - High-entropy strings (API keys, tokens)
   - Common credential patterns: `AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`, `sk-[A-Za-z0-9]{20,}`, private key headers (`-----BEGIN`)
   - Sensitive files staged for commit: `.env*`, `*.pem`, `id_rsa*`, `*.pfx`, `credentials.json`

   Log file paths and line numbers. **Never display the secret value itself.**

5. **Dangerous pattern search (SAST)**
   Scan changed files for language-appropriate anti-patterns:
   - JS/TS: `eval(`, `new Function(`, `innerHTML =`, `dangerouslySetInnerHTML`, `document.write`
   - Python: `eval(`, `exec(`, `pickle.loads`, `subprocess.*shell=True`, `yaml.load` without SafeLoader
   - Shell/any: hardcoded IPs, plaintext `http://` endpoints, SQL string concatenation, OS command injection via unsanitized input
   - Go: `exec.Command` with user input, `unsafe.Pointer`
   - Java: `Runtime.exec`, `ObjectInputStream` on untrusted data

   Log matches with file:line.

6. **Test execution**
   Detect a test runner and run the suite:
   - `package.json` `test` script → `npm test`
   - `pytest.ini` / `pyproject.toml` → `pytest`
   - `cargo test`, `go test ./...`, `bundle exec rspec`, `mvn test`

   Log pass/fail counts. If no tests exist, note it.

7. **AI review of staged diff**
   Run `git diff --cached` (fallback to `git diff` if nothing staged).
   - Summarize what the change does.
   - Flag SOLID violations, new tech debt, missing error handling at boundaries, broken invariants.

8. **Consolidated report**
   Present findings grouped by severity:
   - **Critical** (secrets, failed tests, high-severity vulns): recommend addressing before push.
   - **Minor** (style warnings, low-priority debt): warn, let the user decide.
   - **Clean**: confirm ready to push.

   End with an explicit verdict: **READY** / **FIX FIRST** / **REVIEW NEEDED**.
