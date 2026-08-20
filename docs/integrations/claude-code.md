# Claude Code Setup

Claude Code should be treated as a separate integration, not part of the proxy identity.

## Expected Pattern

1. Start the local proxy stack with `./scripts/start.ps1`.
2. Keep Claude authentication in Claude Code itself.
3. Point Claude Code at the local proxy base URL instead of the upstream provider URL.
4. Run a fake-data prompt through Claude Code and confirm placeholders are restored in the final response.

## Proxy Endpoint

Use the proxy base URL from `.env`. The default is:

```text
http://127.0.0.1:8000
```

## Team Onboarding Checklist

1. Run `./scripts/bootstrap.ps1`
2. Run `./scripts/start.ps1`
3. Confirm `./scripts/status.ps1` reports both services healthy
4. Configure Claude Code to send requests to the local proxy base URL
5. Keep Claude authentication enabled in Claude Code
6. Send a fake prompt containing an email, IP, and test token
7. Confirm the request succeeds and the final Claude response does not leak raw placeholder tokens back to the user

## Configuration Shape

The exact Claude Code keys can vary by version, but the integration should always follow this pattern:

```text
provider base URL -> http://127.0.0.1:8000
authentication -> managed by Claude Code
proxy runtime auth -> none added locally
```

## Notes

- The exact Claude Code configuration keys can change over time, so keep those instructions isolated from the core proxy docs.
- The goal is for the same local anonymization layer to be reusable across Codex, Claude Code, and future LLM CLIs.
