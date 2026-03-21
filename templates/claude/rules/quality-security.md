# Quality: Security Principles

## Input / Output
- Never interpolate user input into SQL, shell commands, or HTML — use parameterized queries and escaping
- Validate and sanitize all external inputs (query params, headers, file uploads, webhooks)
- Escape all output rendered in HTML/JS contexts to prevent XSS

## Authentication & Authorization
- Protect state-changing endpoints with CSRF tokens or SameSite cookies
- Hash passwords with bcrypt (cost ≥ 12) or argon2 — never MD5/SHA1 or plaintext
- Rate-limit authentication endpoints and sensitive actions
- Enforce authorization checks on every request — never trust client-provided IDs

## Data Protection
- Encrypt sensitive data at rest (PII, payment data, credentials)
- No secrets, tokens, or passwords in source code, logs, or error messages
- Use environment variables or a secrets manager for all credentials
