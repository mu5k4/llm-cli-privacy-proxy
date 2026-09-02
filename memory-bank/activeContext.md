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
