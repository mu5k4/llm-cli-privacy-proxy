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
  - purpose: run the broad readiness check in one command
  - changes: none
  - depends on: Docker, Codex CLI, PowerShell, healthy stack for the demo-proof step
  - checks: Codex login, provider presence, default provider, analyzer health, proxy health, `demo-proof.ps1`
- `scripts/demo-proof.ps1`
  - purpose: prove the local `/protect` and `/restore` flow is working
  - changes: creates temporary protection sessions inside the running service
  - depends on: PowerShell, healthy running stack
  - does not: prove Codex is configured to use the proxy
- `scripts/test.ps1`
  - purpose: run the default regression entrypoint
  - changes: none outside the running local stack
  - depends on: PowerShell, healthy running stack
- `scripts/regression.ps1`
  - purpose: run expanded regression coverage
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

1. Run `./scripts/bootstrap.ps1`.
2. Review `.env` if you want to override ports, provider naming, or upstream base URL.
3. Run `./scripts/start.ps1` if you want the stack available for manual `/protect` and `/restore` testing.
4. Run `./scripts/test.ps1`.

If you are using Codex CLI, continue with [Codex CLI setup](./docs/integrations/codex-cli.md).

For deeper validation, run:

```powershell
./scripts/regression.ps1 -IncludeDisruptive
```

If `.env` does not exist, the PowerShell scripts will create it from `.env.example` automatically.

## Quick Share

If you want a clean archive of the project:

```powershell
./scripts/package.ps1
```

That creates a timestamped zip under `./dist/` and excludes local runtime cache plus machine-specific `.env`.

Release metadata lives in `./VERSION`, `./CHANGELOG.md`, and `./CONTRIBUTING.md`.

## Codex Quickstart

For a first-time Codex user on Windows:

1. Clone or unpack the repo.
2. Run `./scripts/install.ps1`.
3. Run `./scripts/codex-status.ps1`.
4. When the stack is healthy, open any repo and run `codex` normally.

```powershell
cd C:\path\to\your\repo
codex
```

Day-to-day usage after setup:

1. start the privacy stack with `./scripts/start.ps1`
2. open the repo you want
3. run `codex`

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

## Run The Smoke Test

```powershell
./scripts/test.ps1
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
  text = "My name is Jonas, email jonas@example.com, phone +37061234567, and API key sk-test-1234567890"
  language = "en"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:8000/protect" -Method Post -ContentType "application/json" -Body $body
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

Invoke-RestMethod -Uri "http://127.0.0.1:8000/restore" -Method Post -ContentType "application/json" -Body $restoredBody
```

Expected result:

- `text` contains the original values again

If you also want transport proof, run `docker logs -f llm-cli-privacy-proxy` in another terminal and then send a Codex prompt. A `POST /responses` log entry proves the request went through the proxy, while the `/protect` and `/restore` demo proves the anonymization and restoration behavior.

## Troubleshooting

- `docker` or `codex` not found: install the missing tool and ensure it is on `PATH`, then rerun `./scripts/install.ps1`.
- `Analyzer health: unreachable` or `Proxy health: unreachable`: run `./scripts/start.ps1`, then recheck with `./scripts/status.ps1` or `./scripts/codex-status.ps1`.
- Port already in use on `127.0.0.1:8000` or `127.0.0.1:5001`: change `PROXY_PORT` or `ANALYZER_PORT` in `.env`, restart the stack, then rerun `./scripts/install.ps1`.
- `Default model_provider` is not `privacy`: rerun `./scripts/install.ps1`, then confirm with `./scripts/codex-status.ps1`.
- `codex-status.ps1` healthy output should show `Provider configured: True`, `Default model_provider: privacy`, `Analyzer health: ok`, and `Proxy health: ok`.
- `demo-proof.ps1` fails: fix stack health first with `./scripts/start.ps1`, then rerun the proof. If it still fails, use `./scripts/regression.ps1` for a broader check.
- `doctor.ps1` is the fastest full readiness check because it bundles login, provider, health, and protect/restore proof into one command.

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

## Naming Note

The runtime and documentation have been rebranded to `LLM CLI Privacy Proxy`.
The on-disk folder has been renamed to `tools/llm-cli-privacy-proxy` to match the product identity.
Older notes and handoffs may still mention `tools/cline-privacy` as the previous path.
