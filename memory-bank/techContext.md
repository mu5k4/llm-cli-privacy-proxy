# Technical Context

## Stack
- Windows 11 oriented workflow.
- Docker Desktop with Linux containers.
- PowerShell scripts for lifecycle, validation, packaging, and integration setup.

## Important Repo Areas
- docker-compose.yml: local stack definition.
- pyproject.toml: declared Python dependency source of truth for both runtime environments.
- privacy-service.lock and analyzer.lock: hash-locked Python install artifacts used by Docker builds.
- scripts/: lifecycle, validation, and utility scripts.
- docs/integrations/: per-client setup guides.
- analyzer-config.yaml and recognizers.yaml: analyzer and recognizer configuration.
- VERSION and release metadata files: project release information.

## Notable Script Roles
- env bootstrap script: creates .env from .env.example.
- install/setup script: first-time Codex integration setup.
- start/stop scripts: manage the local stack.
- status and doctor scripts: verify health and readiness.
- demo proof script: proves protect/restore flow.
- regression script: broader runtime coverage.
- packaging script: builds a clean shareable zip.

## Next Technical Work To Support
- Future work should extend the current hardened runtime without reintroducing mutable dependencies, widened request surfaces, or looser restoration boundaries.
