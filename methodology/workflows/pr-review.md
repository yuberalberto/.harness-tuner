---
description: Structured pull request review against team standards and SDD traceability
---

# PR Review — Structured Code Review

This workflow guides through a structured pull request review against team standards.

## Trigger

Invoke this workflow when reviewing code before merging. Usage: `/pr-review [branch or PR reference]`

## Steps

### Step 1: Spec Traceability Check

- Is the code change covered by a spec?
- Do changed files trace back to specific tasks/requirements?
- Are there any changes not covered by the spec (scope creep)?
- **Output**: Traceability assessment (Pass / Gaps identified)

### Step 2: Test Coverage Review

- Are there tests for all acceptance criteria?
- Are tests meaningful (testing behavior, not implementation)?
- Is coverage sufficient (≥ 80%, critical paths ≥ 95%)?
- Are edge cases covered?
- Do test names follow the naming convention?
- **Output**: Test assessment (Pass / Issues identified)

### Step 3: Code Quality Review

- Naming: Are names descriptive and intention-revealing?
- Structure: Are functions ≤ 30 lines? Single responsibility?
- Types: Are types used correctly? Any `any` or unsafe casts?
- Documentation: Do public functions have proper docstrings?
- DRY: Any copy-paste code that should be extracted?
- **Output**: Quality assessment with specific suggestions

### Step 4: Security Review

- **Exposed secrets**: High-entropy strings, patterns (`AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`, `sk-[A-Za-z0-9]{20,}`, `-----BEGIN`), sensitive files (`.env*`, `*.pem`, `id_rsa*`, `credentials.json`). Log file:line — never display secret values.
- **Injection vulnerabilities**: SQL (string concatenation into queries instead of parameterized statements), command injection (unsanitized user input passed to shell), path traversal (user-controlled file paths without sanitization), XSS (user input rendered as HTML without escaping).
- **Dangerous patterns**: JS/TS: `eval(`, `innerHTML =`, `dangerouslySetInnerHTML`, `document.write`. Python: `eval(`, `exec(`, `pickle.loads`, `subprocess.*shell=True`, `yaml.load` without SafeLoader. Any language: hardcoded credentials, plaintext `http://` for sensitive endpoints, disabled TLS verification.
- **Auth and authorization**: New routes or endpoints protected by auth middleware? Missing authorization checks (any user accessing another user's data)? Session tokens or JWTs handled securely? Sensitive data logged?
- **Dependencies**: List any new packages. Are they well-maintained with no known critical CVEs?
- **Output**: Security assessment (Risk Level: CRITICAL / HIGH / MEDIUM / LOW / CLEAN) with file:line for each finding.

### Step 5: Architecture Review

- Does the code follow established patterns?
- Are dependency directions correct (no circular deps)?
- Is separation of concerns maintained?
- Are boundaries between layers clear?
- Will this change scale?
- **Output**: Architecture assessment

### Step 6: Generate Review Summary

Compile findings into a structured review:

```
## PR Review Summary

### Verdict: Approve / Request Changes / Needs Discussion

### Findings
- 🟢 [What's good]
- 🟡 [Suggestions (non-blocking)]
- 🔴 [Required changes (blocking)]

### Traceability: [Pass/Gaps]
### Tests: [Pass/Issues]
### Security: [Pass/Issues]
### Architecture: [Pass/Issues]
```

- **Output**: Complete review summary with actionable items

## Output

At completion:
- Structured review summary
- Clear verdict (Approve / Request Changes)
- Specific, actionable feedback
- Security and traceability verification
