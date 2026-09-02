# Decisions

## Recorded Decisions
- The privacy runtime is treated as the core product, while Codex CLI, Claude Code, and future clients are separate integrations.
- Client-specific authentication and config instructions belong in docs/integrations rather than in the core runtime documentation.
- The stack is designed to remain client-agnostic so additional integrations can be added without renaming the runtime.
- Shareable artifacts should exclude local runtime state such as `.env` and privacy cache data.
- The outbound request path must use explicit allowlisted schema construction rather than partial pass-through forwarding.
- The nested `/responses` request schema stays intentionally narrow and fail-closed.
- Cross-slot detection uses a canonical concatenated logical text stream with offset-based mapping back into the original slots.
- Placeholder restoration is protocol-aware and limited to approved passive human-visible text fields.
- Local endpoint authentication uses a per-install random secret embedded in the local provider path.
- Codex config mutation uses top-level TOML-aware edits plus parser-backed validation.
- Request/session/cache controls remain bounded and fail-closed.
- Tracked project context in a public repository should stay high level and avoid machine-local paths, detailed operational history, or scanner-noisy example values.
