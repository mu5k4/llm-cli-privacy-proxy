# Active Context

## Current Focus
The core runtime and PowerShell workflow are in a working state. The current public-facing cleanup effort keeps repository metadata, examples, and helper scripts safe to publish without exposing machine-local details or scanner-noisy fake secrets.

## Recent Decisions
- Keep the proxy product client-agnostic while documenting per-client setup separately.
- Keep the `/responses` request surface intentionally narrow and fail-closed.
- Protect the local HTTP hop with an install-generated secret path in the provider URL.
- Keep public tracked project context high level and avoid machine-local operational detail.
- Keep public-facing docs aligned with the secret-scoped local proxy path and current tracked files.

## Immediate Next Useful Work
- Preserve the current runtime hardening, request filtering, restore-boundary controls, and dependency pinning.
- Keep scripts runnable from either the repo root or the `scripts/` directory.
- Keep public documentation and tracked examples free of real secrets and low-value secret-scanner noise.
- The full script retest passed on September 2, 2026 and the restored stack is currently healthy.
- On September 2, 2026, fixed a live `/responses` compatibility regression by allowing bounded `client_metadata` through the proxy request sanitizer and revalidated the stack with the regression suite.
- On September 2, 2026, changed `/responses` request scanning to fan out across configured languages sequentially, preserving explicit-language `/protect` behavior while avoiding self-contention on the Presidio scan semaphore.
- On September 2, 2026, replaced blanket dual-language `/responses` scanning with a heuristic fallback: scan English first and only add Lithuanian when the text contains Lithuanian characters or enough Lithuanian hint words. Regression coverage now proves English-only, Lithuanian-triggered, and mixed-language cases.
- On September 2, 2026, replaced `/responses` deep Presidio scanning with a fast path that combines Nosey Parker and in-process deterministic recognizers for common secrets and PII. `/protect` remains the explicit deep-scan route. The rebuilt stack returned a live `/responses` smoke request to the upstream auth boundary in about 0.9 seconds, and the regression suite passed.
- On September 2, 2026, widened `client_metadata` value handling for opaque Codex turn metadata with a separate bounded limit, verified a live long-`client_metadata` `/responses` smoke request reached the upstream auth boundary in about 1.2 seconds, and revalidated with the full regression suite.
- On September 2, 2026, widened the safe `/responses` tool allowlist from bare hosted tool names to bounded passthrough validation for known OpenAI/Codex tool types, including `function`, `mcp`, and hosted tool configs. Rebuilt stack verification passed through the live smoke path and the regression suite passed.
- On September 2, 2026, removed the named `/responses` tool-type allowlist entirely. Tool definitions now pass through with bounded structural validation as long as they include a non-empty `type`, which preserves Codex-native tool access without scanning `tools` content. The rebuilt stack and full regression suite both passed.
- On September 2, 2026, added structured `/responses` timing logs for raw body read, JSON parse, sanitize time, upstream connect time, first chunk, and stream completion. Rebuilt stack verification and the full regression suite passed. A live timed request showed about 483 ms in local sanitization and about 182 ms to reach upstream 401.
- On September 2, 2026, extended `/responses` tracing with a stable `trace_id`, `queue_wait_ms`, request-size metadata, tool/include counts, and an `x-privacy-proxy-trace-id` response header so a real successful Codex request can be correlated end to end across proxy logs and the client-visible response. The rebuilt stack and full regression suite passed.
- On September 2, 2026, optimized large `/responses` payload handling by skipping Nosey Parker unless the payload is small or contains strong secret-like markers. Rebuilt stack verification and the full regression suite passed. A post-change traced live request dropped local sanitize time from about 2647 ms to about 12 ms, shifting the dominant delay to upstream response time.
- On September 2, 2026, identified the stray `/responses` 400 as a compatibility gap in `body.text.format` for Codex JSON-schema output mode. Widened the sanitizer to accept `type=json_schema` with bounded pass-through of `name`, `schema`, and `strict`, corrected the stale regression expectation for unsupported text formats, and revalidated with the full regression suite.
