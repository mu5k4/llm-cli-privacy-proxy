# Technical Context

## Stack
- Windows 11 oriented workflow.
- Docker Desktop with Linux containers.
- PowerShell scripts for lifecycle, validation, packaging, and integration setup.

## Important Repo Areas
- docker-compose.yml: local stack definition.
- scripts/: lifecycle, validation, and utility scripts.
- docs/integrations/: per-client setup guides.
- analyzer-config.yaml and recognizers.yaml: analyzer and recognizer configuration.
- VERSION and release metadata files: project release information.
- .audit/: current audit artifacts and the source material for the next remediation cycle.

## Notable Script Roles
- env bootstrap script: creates .env from .env.example.
- install/setup script: first-time Codex integration setup.
- start/stop scripts: manage the local stack.
- status and doctor scripts: verify health and readiness.
- demo proof script: proves protect/restore flow.
- regression script: broader runtime coverage.
- packaging script: builds a clean shareable zip.

## Next Technical Work To Support
- Dependency, image, and model pinning with immutable versions and hashes.
- Cache invalidation keyed to recognizer, model, config, threshold, and version changes.
- Resource limits for request size, JSON depth, slot count, chunk count, concurrency, TTLs, and retained session state.
- TOML-safe config editing and post-write verification for install and uninstall flows.
- Additional regression coverage for outbound request shapes, cross-slot detection, overlap handling, long-entity boundaries, and protocol-aware restoration.
