# Product Context

## User-Facing Behavior
Users run a local privacy layer in front of an upstream model provider. Their prompt text is anonymized locally, forwarded upstream in tokenized form, and restored locally on the way back.

## Product Boundaries
- The runtime itself is the product.
- Codex CLI, Claude Code, and future clients are integrations.
- Authentication and client-specific configuration should stay inside the integration guides.

## Main User Flows
- Core runtime/manual proxy testing: create .env, start the stack, run regression checks.
- Codex CLI integration: run the one-time setup script, then use the status/doctor scripts for readiness checks.
- Manual privacy proof: call local /protect and /restore endpoints and verify placeholder round trips.

## Expected Outcomes
- Sensitive values never need to leave the machine in raw form.
- Final user-visible responses should have originals restored rather than placeholder tokens.
- Day-to-day Codex usage should work through the proxy after one-time install.
