---
trigger: always_on
description: Test naming convention for readable, story-driven test names
---

# Test Naming Convention

Test names MUST tell a story using this format:

```
<subject>__should_<behavior>__when_<context>
```

- **Subject**: domain concept (not a class/function name)
- **Behavior**: observable outcome in business language
- **Context**: precondition or trigger (`when_` may be omitted for happy path)

## Examples

```
JwtValidator__should_accept_token__when_signature_valid
JwtValidator__should_reject_expired_token

LoginForm__should_submit_credentials__when_user_clicks_button
LoginForm__should_show_error__when_password_invalid
```

## Test Classes

Group related tests in classes: `Test<Subject><Theme>`

Example:
```
TestJwtValidatorSignature
TestJwtValidatorExpiry
TestLoginFormSubmission
TestLoginFormValidation
```
