# Project Brief

## Goal
Provide a local privacy proxy that anonymizes sensitive prompt content before forwarding requests upstream, then restores placeholders locally in responses.

## Scope
- Core product is the reusable privacy proxy/runtime.
- Client-specific setup belongs in integration docs, not the core product identity.
- Current documented integrations include Codex CLI and Claude Code.
- The stack is intended to stay client-agnostic so future client integrations can be added without renaming the proxy.

## Key Capabilities
- Detect sensitive values locally.
- Replace detected values with placeholder tokens.
- Forward anonymized requests upstream.
- Restore original values locally before the user sees the response.
- Support local protect/restore proof flows and regression testing.

## Important Constraints
- Windows-first workflow.
- Uses Docker Desktop with Linux containers.
- Local runtime state such as .env and privacy cache should not be treated as portable project artifacts.
