# Security Standards

These security requirements apply to all code. Security rules ALWAYS take priority over other rules.

## Authentication & Authorization

- Never assume auth exists — verify explicitly at every boundary
- Use established auth libraries; never roll your own crypto
- Tokens MUST have expiration times
- Refresh tokens need separate rotation logic
- Session invalidation MUST be immediate (not eventually consistent)
- Role-based access: default to deny, whitelist allowed actions

## Secrets Management

- NEVER hardcode secrets, API keys, or credentials in source code
- NEVER commit secrets to version control (even in "private" repos)
- Use environment variables or dedicated secret stores (Vault, AWS Secrets Manager)
- Rotate secrets on any suspected compromise
- Different secrets for each environment (dev, staging, prod)

## Input Validation

- Validate ALL external inputs at the system boundary
- Use allowlists over denylists when possible
- Validate types, ranges, lengths, and formats
- Sanitize inputs before database queries (use parameterized queries)
- Reject invalid input early with descriptive error messages (without leaking internals)

## Output Encoding

- Encode output appropriate to context (HTML, URL, SQL, OS command)
- Never interpolate user input into queries, commands, or templates without encoding
- Use templating engines with auto-escaping enabled

## Logging & Monitoring

- Log security-relevant events: login attempts, permission denials, input validation failures
- NEVER log sensitive data: passwords, tokens, PII, credit card numbers
- Include correlation IDs for request tracing
- Log at appropriate severity levels (INFO for normal, WARN for suspicious, ERROR for failures)
- Ensure logs are tamper-evident in production

## Data Protection

- Encrypt sensitive data at rest
- Use TLS for all data in transit
- Minimize data collection (only collect what you need)
- Implement data retention policies
- Provide data deletion capabilities (right to be forgotten)

## Dependency Security

- Keep dependencies up to date
- Run vulnerability scanning (e.g., `pip audit`, `npm audit`) regularly
- Pin dependency versions for reproducible builds
- Review changelogs before major version upgrades

## Error Handling (Security Context)

- Never expose stack traces, internal paths, or system details in error responses
- Use generic error messages for end users
- Log detailed errors server-side only
- Handle all error paths — unhandled exceptions are security vulnerabilities
