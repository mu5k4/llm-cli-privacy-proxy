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
- `scripts/demo-proof.ps1`: run a local protect/restore proof and fail if anonymization or restoration breaks
- `scripts/doctor.ps1`: run the teammate-facing end-to-end health check for Codex config, stack health, and demo proof
- `scripts/codex-with-privacy.ps1`: optional advanced wrapper for one-shot provider override cases
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

## Teammate Quickstart

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

## Start The Proxy

```powershell
./scripts/start.ps1
```

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

## Run The Smoke Test

```powershell
./scripts/test.ps1
```

## Privacy Proof Demo

Use this when you want to prove to yourself or a colleague that the proxy is anonymizing sensitive values locally before upstream use.

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
  text = "My name is Jonas, email jonas@example.com, phone +37061234567, and API key DEMO_SECRET_VALUE"
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
- `doctor.ps1` is the fastest full readiness check for teammates because it bundles login, provider, health, and protect/restore proof into one command.

## Stop The Proxy

```powershell
./scripts/stop.ps1
```

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

## Sharing With Colleagues

- Share the project folder without `.env` if you want teammates to start from the documented defaults.
- Do not rely on `privacy-cache/*.json` as a portable artifact; it is local runtime state.
- Keep client-specific setup in `docs/integrations/` so the core runtime remains reusable.
- Prefer `./scripts/package.ps1` when you want a clean handoff artifact instead of a live working folder.

## Naming Note

The runtime and documentation have been rebranded to `LLM CLI Privacy Proxy`.
The on-disk folder has been renamed to `tools/llm-cli-privacy-proxy` to match the product identity.
Older notes and handoffs may still mention `tools/cline-privacy` as the previous path.

