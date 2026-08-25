# System Patterns

## Architecture Pattern
- The client sends content to the local privacy proxy.
- The proxy uses local analyzers and recognizers to detect sensitive values.
- The proxy replaces sensitive values with placeholders.
- The proxy must construct an explicit allowlisted outbound request instead of forwarding caller payloads wholesale.
- The proxy forwards only validated structural fields and scanned content-bearing fields upstream.
- The proxy must parse the upstream protocol structurally and restore originals only in approved passive human-visible assistant text fields.

## Current Remediation Direction
- Replace pass-through request forwarding with explicit schema construction and field classification.
- Add canonical cross-slot scanning so fragmented secrets are detected across adjacent text segments.
- Preserve the full union of overlapping sensitive spans instead of letting inner spans drop outer sensitive characters.
- Tighten session ownership, TTL, delete-after-use behavior, and other fail-closed restoration controls.
- Keep unknown content-bearing fields, unsafe attachments, and unsupported representations fail-closed.

## Documentation Pattern
- Core runtime documentation stays in the main README.
- Client-specific instructions live under docs/integrations.
- Integration-specific auth, environment variables, and config edits should not leak into core runtime docs.

## Operational Pattern
- Scripts handle setup, start, stop, uninstall, and packaging.
- Validation scripts cover smoke checks, doctor/readiness checks, demo proof, and regression testing.
- Shareable artifacts exclude machine-specific runtime state.
- Audit findings in .audit/ now feed directly into implementation planning and regression coverage.
