# Decisions

## Recorded Decisions
- The privacy runtime is treated as the core product, while Codex CLI, Claude Code, and future clients are separate integrations.
- Client-specific authentication and config instructions belong in docs/integrations rather than in the core runtime documentation.
- The stack is designed to remain client-agnostic so additional integrations can be added without renaming the runtime.
- Shareable handoff artifacts should exclude local runtime state such as .env and privacy cache data.
- The August 25, 2026 audit remediation cycle is now the main implementation driver for the next project improvement pass.
- Phase 1 must prioritize the two high-severity confidentiality issues before medium- and low-severity hardening work.
- The outbound request path must move from partial pass-through forwarding to explicit allowlisted schema construction.
- Placeholder restoration must become protocol-aware and limited to approved passive human-visible text fields only.
- .audit/ is active planning input for remediation work, not disposable generated output.
