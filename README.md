# LLM CLI Privacy Proxy

`LLM CLI Privacy Proxy` is a local privacy layer for coding assistants and other LLM CLIs.
It anonymizes prompt text before forwarding requests upstream, then restores placeholders on the way back.

The current stack is designed around a local HTTP proxy:

1. Your client CLI sends prompt content to the local proxy.
2. The proxy scans text with Presidio, GLiNER, and Nosey Parker.
3. Sensitive values are replaced with local placeholder tokens.
4. The anonymized request is forwarded to the upstream LLM API.
5. Returned placeholder tokens are restored locally before the client sees the response.

## Scope

The project identity is client-agnostic.
Client-specific setup belongs in integration instructions, not in the product name.

Today that means:

- Core product: `LLM CLI Privacy Proxy`
- Example integration: `Codex CLI`
- Example integration: `Claude Code`
- Future integrations: additional LLM CLIs can be added without renaming the proxy itself

## Project Layout

- `docker-compose.yml`: local stack definition
- `privacy-service/`: proxy and anonymization logic
- `privacy-cache/`: persistent Presidio cache data
- `.env.example`: shareable runtime defaults for ports and upstream settings
- `scripts/`: Windows PowerShell lifecycle and smoke-test scripts
- `docs/integrations/`: client-specific setup guides
- `analyzer-config.yaml`: Presidio/GLiNER analyzer config
- `recognizers.yaml`: recognizer configuration/reference material

## Current Scripts

- `scripts/bootstrap.ps1`: create local `.env` and print next steps
- `scripts/start.ps1`: build and start the stack
- `scripts/stop.ps1`: stop the stack
- `scripts/status.ps1`: show stack and health status
- `scripts/test.ps1`: run the default regression suite
- `scripts/regression.ps1`: run expanded regression coverage, optionally including disruptive fail-closed checks
- `scripts/install.ps1`: Codex CLI integration helper
- `scripts/codex-status.ps1`: verify Codex login, provider config, and local proxy health
- `scripts/codex-with-privacy.ps1`: launch Codex against the local privacy provider for a chosen workspace
- `scripts/package.ps1`: build a clean shareable zip without local runtime state

The expanded regression suite covers protect/restore round trips, session reuse, `/responses` guard rails, streaming placeholder restoration at chunk boundaries, and optional fail-closed analyzer outage handling.

## Requirements

- Windows 11
- Docker Desktop with Linux containers
- PowerShell
- An installed client CLI, depending on the integration you want

## First-Time Setup

1. Run `./scripts/bootstrap.ps1`.
2. Review `.env` if you want to override ports, provider naming, or upstream base URL.
3. Run `./scripts/start.ps1`.
4. Run `./scripts/test.ps1`.

If your team is primarily using Codex CLI, continue with [Codex CLI setup](./docs/integrations/codex-cli.md).

For deeper validation, run:

```powershell
./scripts/regression.ps1 -IncludeDisruptive
```

If `.env` does not exist, the PowerShell scripts will create it from `.env.example` automatically.

## Quick Share

If you want to hand the project to a colleague as a clean archive:

```powershell
./scripts/package.ps1
```

That creates a timestamped zip under `./dist/` and excludes local runtime cache plus machine-specific `.env`.

Release metadata lives in `./VERSION`, `./CHANGELOG.md`, and `./CONTRIBUTING.md`.

## Start The Proxy

```powershell
./scripts/start.ps1
```

## Check Status

```powershell
./scripts/status.ps1
```

## Run The Smoke Test

```powershell
./scripts/test.ps1
```

## Stop The Proxy

```powershell
./scripts/stop.ps1
```

## Integrations

- [Codex CLI setup](./docs/integrations/codex-cli.md)
- [Claude Code setup](./docs/integrations/claude-code.md)

The proxy should stay client-agnostic. Any client-specific auth, environment variables, base URL settings, or config file edits belong in the integration guides rather than in the core runtime docs.

Planned future integrations should be added under `docs/integrations/` without renaming the proxy itself.

## Sharing With Colleagues

- Share the project folder without `.env` if you want teammates to start from the documented defaults.
- Do not rely on `privacy-cache/*.json` as a portable artifact; it is local runtime state.
- Keep client-specific setup in `docs/integrations/` so the core runtime remains reusable.
- Prefer `./scripts/package.ps1` when you want a clean handoff artifact instead of a live working folder.

## Naming Note

The runtime and documentation have been rebranded to `LLM CLI Privacy Proxy`.
The on-disk folder has been renamed to `tools/llm-cli-privacy-proxy` to match the product identity.
Older notes and handoffs may still mention `tools/cline-privacy` as the previous path.

