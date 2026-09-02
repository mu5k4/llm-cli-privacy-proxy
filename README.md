# LLM CLI Privacy Proxy

`LLM CLI Privacy Proxy` is a local privacy layer for coding assistants and other LLM CLIs.
It anonymizes prompt text before forwarding requests upstream, then restores placeholders on the way back.

The current stack is designed around a local HTTP proxy:

1. Your client CLI sends prompt content to the local proxy.
2. The proxy scans text with Presidio, GLiNER, and Nosey Parker.
3. Sensitive values are replaced with local placeholder tokens.
4. The anonymized request is forwarded to the upstream LLM API.
5. Returned placeholder tokens are restored locally before the client sees the response.

The local HTTP hop is protected by an install-generated secret path segment.
Users do not log in to the proxy separately; the secret is configured automatically in the local provider URL.

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
- `pyproject.toml`: declared Python dependency source of truth for both runtime environments
- `privacy-service.lock`: hash-locked install artifact for the proxy runtime
- `analyzer.lock`: hash-locked install artifact for the analyzer-side Python additions
- `privacy-service/`: proxy and anonymization logic
- `privacy-cache/`: persistent Presidio cache data
- `.env.example`: shareable runtime defaults for ports and upstream settings
- `scripts/`: Windows PowerShell lifecycle and smoke-test scripts
- `docs/integrations/`: client-specific setup guides
- `analyzer-config.yaml`: Presidio/GLiNER analyzer config
- `recognizers.yaml`: recognizer configuration/reference material

## Current Scripts

### Lifecycle

- `scripts/bootstrap.ps1`
  - purpose: create `.env` from `.env.example` if it does not exist
  - changes: writes `.env`
  - depends on: PowerShell only
  - does not: build containers, start the stack, or change Codex config
- `scripts/install.ps1`
  - purpose: perform first-time Codex integration setup
  - changes: may build/start the stack, runs the smoke test, writes the provider block to `~/.codex/config.toml`, sets `model_provider`, and marks this repo as trusted in Codex config
  - depends on: Docker, Codex CLI, PowerShell
  - expects: Docker Desktop running and `codex login` completed
  - use when: plain `codex` should route through the proxy by default
- `scripts/start.ps1`
  - purpose: build and start the Docker stack
  - changes: may build images, start containers, create `.env` if missing
  - depends on: Docker, PowerShell
  - does not: configure Codex to use the proxy
  - use when: the proxy stack is already installed and you only need it running again
- `scripts/stop.ps1`
  - purpose: stop and remove the running compose stack
  - changes: stops containers and removes the compose network
  - depends on: Docker, PowerShell
- `scripts/status.ps1`
  - purpose: show compose container state plus proxy/analyzer health
  - changes: none
  - depends on: Docker, PowerShell
- `scripts/uninstall.ps1`
  - purpose: remove the local proxy integration
  - changes: tears down the stack, removes local images unless told not to, removes `.env` unless told not to, removes privacy-specific Codex config unless told not to
  - depends on: Docker, PowerShell
  - optional flags: `-WhatIf`, `-KeepImages`, `-KeepEnv`, `-KeepCodexConfig`, `-FallbackProvider`

### Validation

- `scripts/codex-status.ps1`
  - purpose: verify Codex login, installed provider config, default `model_provider`, and local stack health
  - changes: none
  - depends on: Docker, Codex CLI, PowerShell
- `scripts/doctor.ps1`
  - purpose: run the broad readiness check in one command, including the `codex-status.ps1`-style status summary
  - changes: none
  - depends on: Docker, Codex CLI, PowerShell, healthy stack for the demo-proof step
  - checks: Codex login, provider presence, default provider, analyzer health, proxy health, `demo-proof.ps1`
- `scripts/demo-proof.ps1`
  - purpose: prove the local `/protect` and `/restore` flow is working
  - changes: creates temporary protection sessions inside the running service
  - depends on: PowerShell, healthy running stack
  - does not: prove Codex is configured to use the proxy
- `scripts/regression.ps1`
  - purpose: run regression coverage for the local stack
  - changes: none outside the running local stack
  - depends on: PowerShell, healthy running stack
  - optional flags: `-IncludeDisruptive`

### Utilities

- `scripts/codex-with-privacy.ps1`
  - purpose: one-shot explicit provider override for Codex instead of relying on the installed default provider
  - changes: none to persistent config
  - depends on: Codex CLI, PowerShell
  - use when: you want an explicit per-run override
- `scripts/package.ps1`
  - purpose: create a clean shareable zip under `dist/`
  - changes: writes a zip artifact in `dist/`
  - depends on: PowerShell
  - excludes: local runtime state such as `.env` and cache data

The expanded regression suite covers protect/restore round trips, session reuse, `/responses` guard rails, streaming placeholder restoration at chunk boundaries, and optional fail-closed analyzer outage handling.

## Requirements

- Windows 11
- Docker Desktop with Linux containers
- PowerShell
- An installed client CLI, depending on the integration you want

## First-Time Setup

Choose the setup path that matches what you are doing:

### Core Runtime Or Manual Proxy Testing

Use this when you want to work on the local stack itself, validate `/protect` and `/restore`, or prepare the project for another client integration.

1. Run `./scripts/bootstrap.ps1`.
2. Review `.env` if you want to override ports, provider naming, or upstream settings.
3. Run `./scripts/start.ps1`.
4. Run `./scripts/regression.ps1`.

If `.env` does not exist, the lifecycle scripts will create it from `.env.example` automatically.

### Codex CLI Integration

Use this when you want plain `codex` to route through the proxy by default.

1. Follow [Codex CLI setup](./docs/integrations/codex-cli.md).
2. Run `./scripts/doctor.ps1` after install for the full readiness check, or `./scripts/codex-status.ps1` for the lighter status-only check.

For deeper validation, run:

```powershell
./scripts/regression.ps1 -IncludeDisruptive
```

## Quick Share

If you want a clean archive of the project:

```powershell
./scripts/package.ps1
```

That creates a timestamped zip under `./dist/` and excludes local runtime cache plus machine-specific `.env`.

Release metadata lives in `./VERSION` and `./CHANGELOG.md`.

## Python Dependency Management

- `pyproject.toml` is the declared source of truth for Python dependencies.
- `privacy-service.lock` and `analyzer.lock` are the hash-locked install artifacts used by Docker builds.
- Do not reintroduce handwritten `requirements.txt` files for these runtime environments.

## Codex Quickstart

For a first-time Codex user on Windows:

1. Clone or unpack the repo.
2. Run `./scripts/install.ps1`.
3. Run `./scripts/codex-status.ps1`.
4. When the stack is healthy, open any repo and run `codex` normally.

On Windows, run `./scripts/install.ps1` while the Codex CLI is closed. This script rewrites `~/.codex/config.toml`, and an active Codex session can hold that file long enough to trigger an `os error 32` config-lock failure.

```powershell
cd C:\path\to\your\repo
codex
```

Day-to-day usage after setup:

1. Start the privacy stack with `./scripts/start.ps1`.
2. Open the repo you want.
3. Run `codex`.

Important distinction:

- `scripts/start.ps1` only starts the local Docker services
- `scripts/install.ps1` is the step that tells Codex to use the proxy by writing the provider config and default `model_provider`
- if you skip `install.ps1`, a healthy local stack by itself does not make plain `codex` use the proxy

## Start The Proxy

```powershell
./scripts/start.ps1
```

Use this when:

- you already ran `./scripts/install.ps1` earlier and just need the stack running again for Codex
- you want to test the proxy manually through `/protect` and `/restore`

Do not treat `start.ps1` as a substitute for `install.ps1` when setting up Codex for the first time.

## Check Status

```powershell
./scripts/status.ps1
```

## Run The Demo Proof

```powershell
./scripts/demo-proof.ps1
```

## Run The Doctor Check

```powershell
./scripts/doctor.ps1
```

This is the clearest single-command check when you want to confirm:

- Codex is logged in
- the `privacy` provider is installed
- `model_provider` points at `privacy`
- the analyzer and proxy are healthy
- the `/protect` and `/restore` proof still works

It also prints the same high-level status summary as `./scripts/codex-status.ps1` before the structured PASS/FAIL output.

## Run The Regression Test

```powershell
./scripts/regression.ps1
```

## Privacy Proof Demo

Use this when you want to prove that the proxy is anonymizing sensitive values locally before upstream use.

Fastest path:

```powershell
./scripts/demo-proof.ps1
```

Manual path:

1. Start the stack with `./scripts/start.ps1`.
2. Send a sample prompt to the local `/protect` endpoint.
3. Confirm the response replaces sensitive values with `GP_*` tokens.
4. Send a tokenized message plus the returned `session_id` to `/restore`.
5. Confirm the original values are restored locally.

Protect example:

```powershell
$body = @{
  text = "My name is Jonas, email jonas@example.com, phone +37061234567, and demo credential DEMO_SECRET_VALUE"
  language = "en"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:8000/local/<redacted>/protect" -Method Post -ContentType "application/json" -Body $body
```

Expected result:

- `text` contains placeholder tokens such as `GP_PERSON_0001`, `GP_EMAIL_ADDRESS_0001`, or other `GP_*` replacements chosen by the detectors
- `session_id` is returned for local restoration

Restore example:

```powershell
$restoredBody = @{
  session_id = "<session_id from protect>"
  text = "<protected text returned by /protect>"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:8000/local/<redacted>/restore" -Method Post -ContentType "application/json" -Body $restoredBody
```

Expected result:

- `text` contains the original values again

If you also want transport proof, run `docker logs -f llm-cli-privacy-proxy` in another terminal and then send a Codex prompt. A `POST /responses` log entry proves the request went through the proxy, while the `/protect` and `/restore` demo proves the anonymization and restoration behavior. Recent builds also emit structured `/responses` timing events plus an `x-privacy-proxy-trace-id` response header so you can separate local proxy time from upstream model time during live troubleshooting.

## Troubleshooting

- `docker` or `codex` not found: install the missing tool and ensure it is on `PATH`, then rerun `./scripts/install.ps1`.
- `Failed to read config file ... os error 32` during install or uninstall: close any running Codex CLI sessions, then rerun `./scripts/install.ps1` or `./scripts/uninstall.ps1`.
- `Analyzer health: unreachable` or `Proxy health: unreachable`: run `./scripts/start.ps1`, then recheck with `./scripts/status.ps1` or `./scripts/codex-status.ps1`.
- Port already in use on `127.0.0.1:8000` or `127.0.0.1:5001`: change `PROXY_PORT` or `ANALYZER_PORT` in `.env`, restart the stack, then rerun `./scripts/install.ps1`.
- `Default model_provider` is not `privacy`: rerun `./scripts/install.ps1`, then confirm with `./scripts/codex-status.ps1`.
- `codex-status.ps1` healthy output should show `Provider configured: True`, `Default model_provider: privacy`, `Analyzer health: ok`, and `Proxy health: ok`.
- `demo-proof.ps1` fails: fix stack health first with `./scripts/start.ps1`, then rerun the proof. If it still fails, use `./scripts/doctor.ps1` for a broader check.
- `./scripts/doctor.ps1` is the fastest full readiness check because it bundles the `codex-status.ps1`-style status summary, provider checks, health, and protect/restore proof into one command.
- intermittent `/responses` `400` errors about `body.text.format`: update to the latest proxy build. The proxy now accepts Codex JSON-schema response format payloads and no longer rejects `name`, `schema`, or `strict` under `body.text.format`.
- `/responses` feels slow: recent builds keep large benign Codex payloads on the fast regex path and expose structured `/responses` timing logs so you can see request sanitize time, time to first chunk, and total stream duration separately.

## Stop The Proxy

```powershell
./scripts/stop.ps1
```

## Uninstall The Proxy Integration

```powershell
./scripts/uninstall.ps1
```

By default this will:

- stop the local stack
- remove the local Docker images built by this project
- remove the project `.env`
- remove the privacy provider block from `~/.codex/config.toml`
- switch `model_provider` back to `openai` if it currently points at the privacy provider
- remove the trusted-project entry for this proxy repo

On Windows, run `./scripts/uninstall.ps1` while the Codex CLI is closed for the same reason: uninstall also rewrites `~/.codex/config.toml`, so an active Codex session can interfere with the update.

Useful options:

- `./scripts/uninstall.ps1 -WhatIf`: preview the changes
- `./scripts/uninstall.ps1 -KeepImages`: keep the built Docker images
- `./scripts/uninstall.ps1 -KeepEnv`: keep the local `.env`
- `./scripts/uninstall.ps1 -KeepCodexConfig`: tear down only the Docker stack and local files

## Integrations

- [Codex CLI setup](./docs/integrations/codex-cli.md)
- [Claude Code setup](./docs/integrations/claude-code.md)

The proxy should stay client-agnostic. Any client-specific auth, environment variables, base URL settings, or config file edits belong in the integration guides rather than in the core runtime docs.

For Codex CLI specifically, the intended daily workflow after installation is:

1. start the privacy stack
2. open the repo you want
3. run `codex` normally

Planned future integrations should be added under `docs/integrations/` without renaming the proxy itself.

## Advanced Usage

Most users should ignore the wrapper and run plain `codex` after the one-time install.

- `scripts/codex-with-privacy.ps1`: explicit one-shot provider override for interactive runs
- `scripts/codex-with-privacy.ps1 -Exec`: explicit one-shot provider override for non-interactive runs

## Sharing

- Share the project folder without `.env` if you want recipients to start from the documented defaults.
- Do not rely on `privacy-cache/*.json` as a portable artifact; it is local runtime state.
- Keep client-specific setup in `docs/integrations/` so the core runtime remains reusable.
- Prefer `./scripts/package.ps1` when you want a clean handoff artifact instead of a live working folder.
- For zipped-project startup, send [docs/teammate-handoff.md](./docs/teammate-handoff.md).

## Naming Note

The runtime and documentation have been rebranded to `LLM CLI Privacy Proxy`.
The on-disk folder has been renamed to `tools/llm-cli-privacy-proxy` to match the product identity.
Older notes and handoffs may still mention `tools/cline-privacy` as the previous path.
