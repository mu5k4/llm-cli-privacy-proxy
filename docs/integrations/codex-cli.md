# Codex CLI Setup

This integration keeps the proxy runtime separate from Codex-specific configuration.

## Fast Path

For a user who just needs the working Codex flow:

1. Run `./scripts/install.ps1`
2. Run `./scripts/doctor.ps1` for the full readiness check, or `./scripts/codex-status.ps1` for the lighter status check
3. Start the privacy stack when needed with `./scripts/start.ps1`
4. Open any repo and run `codex` normally

On Windows, run `./scripts/install.ps1` while the Codex CLI is closed. The helper rewrites `~/.codex/config.toml`, and an active Codex session can cause an `os error 32` config-lock failure.

```powershell
cd C:\path\to\your\repo
codex
```

## Requirements

- Docker Desktop
- PowerShell
- `codex` installed and available on `PATH`

## One-Time Setup

Run:

```powershell
./scripts/install.ps1
```

On Windows, close any running Codex CLI sessions before running this helper so `~/.codex/config.toml` is not locked during the config update.

What the helper does:

- checks `docker` and `codex`
- ensures the stack is built and running
- waits for analyzer and proxy health
- runs the smoke test
- appends the local proxy provider block to `~/.codex/config.toml` if needed
- sets `model_provider = "privacy"` so plain `codex` uses the privacy stack by default
- marks the proxy project as trusted in Codex config
- backs up the existing Codex config before changing it

The helper configures this provider:

```toml
[model_providers.privacy]
name = "Local Privacy Proxy"
base_url = "http://127.0.0.1:8000/local/<redacted>"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
```

If you changed `CODEX_PROVIDER_ID`, `PRIVACY_PROVIDER_NAME`, or `PROXY_PORT` in `.env`, the installed provider block will follow those values.
The actual installed `base_url` also includes an auto-generated local auth path secret from `.env`.

Important distinction:

- `install.ps1` is the step that makes plain `codex` use the privacy proxy
- `start.ps1` only starts the Docker services
- without `install.ps1`, plain `codex` will keep using its existing provider even if the proxy stack is healthy

## Step By Step

1. Sign in with `codex login` if needed.
2. Run `./scripts/install.ps1` once on the machine.
3. Start the proxy stack with `./scripts/start.ps1`.
4. Check readiness with `./scripts/doctor.ps1` for the full check, or `./scripts/codex-status.ps1` for the lighter status check.
5. Open the repo you want to work in.
6. Run `codex` normally.

```powershell
cd C:\path\to\your\repo
codex
```

For non-interactive usage:

```powershell
cd C:\path\to\your\repo
codex exec "Summarize this repository"
```

## Readiness Checks

Use these checks before real usage:

```powershell
./scripts/doctor.ps1
./scripts/status.ps1
./scripts/regression.ps1
./scripts/codex-status.ps1
```

What `./scripts/codex-status.ps1` should show:

- `Codex login status: Logged in`
- `Provider configured: True`
- `Default model_provider: privacy`
- `Analyzer health: ok`
- `Proxy health: ok`

`./scripts/doctor.ps1` now prints that same summary first, then continues with structured PASS/FAIL results and the demo-proof check.

## Troubleshooting

- `codex-status.ps1` shows `Provider configured: False`: rerun `./scripts/install.ps1`.
- `codex-status.ps1` shows `Default model_provider` other than `privacy`: rerun `./scripts/install.ps1`.
- `start.ps1` succeeds but Codex still bypasses the proxy: you likely skipped `./scripts/install.ps1`, so Codex was never pointed at the `privacy` provider.
- `Failed to read config file ... os error 32` during install or uninstall: close any running Codex CLI sessions, then rerun `./scripts/install.ps1` or `./scripts/uninstall.ps1`.
- `Analyzer health: unreachable` or `Proxy health: unreachable`: run `./scripts/start.ps1`, then rerun `./scripts/codex-status.ps1`.
- Port collision on the local proxy or analyzer: edit `.env`, change `PROXY_PORT` or `ANALYZER_PORT`, restart the stack, then rerun `./scripts/install.ps1`.
- `codex` starts but does not appear to use the proxy: run `docker logs -f llm-cli-privacy-proxy` and confirm you see `POST /responses` after sending a Codex prompt.
- `scripts/demo-proof.ps1` is the fastest local anonymization proof if you want something stronger than raw traffic logs.
- `scripts/doctor.ps1` is the fastest all-in-one check because it now includes the `codex-status.ps1`-style status summary, Codex config checks, stack health, and the proof script together.
- `scripts/uninstall.ps1` removes the privacy-provider config and tears the stack back down if you want Codex to stop using the proxy.

## Proof Of Behavior

If you want a concrete demo that does not depend on guessing from container logs:

1. Start the stack with `./scripts/start.ps1`.
2. Run `./scripts/demo-proof.ps1`.
3. Optionally, in another terminal, watch proxy traffic with `docker logs -f llm-cli-privacy-proxy`.
4. For live Codex proof, send a Codex prompt and confirm you see `POST /responses`.

Automated example:

```powershell
./scripts/demo-proof.ps1
```

Manual example:

```powershell
$body = @{
  text = "My name is Jonas, email jonas@example.com, phone +37061234567, and API key sk-test-1234567890"
  language = "en"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:8000/local/<redacted>/protect" -Method Post -ContentType "application/json" -Body $body
```

What to show:

- proxy logs show `POST /responses` for real Codex traffic or `/protect` for the explicit demo
- `/protect` output shows `GP_*` placeholders instead of raw values
- `/restore` output shows the original values reconstructed locally

This is stronger evidence than raw container logs alone, because the current proxy logs intentionally avoid printing prompt contents.

## Which Script To Use

- `install.ps1`: one-time Codex + proxy setup
- `uninstall.ps1`: remove Codex proxy settings and tear the local stack down
- `doctor.ps1`: one-command readiness check
- `codex-status.ps1`: lighter readiness check for login, provider, and local proxy health
- `demo-proof.ps1`: proof that protect/restore still works
- `start.ps1`: bring the local privacy stack up before coding sessions
- `stop.ps1`: stop the local privacy stack when done
- `codex-with-privacy.ps1`: advanced wrapper for explicit one-shot provider override
- `codex-with-privacy.ps1 -Exec`: advanced wrapper for non-interactive one-shot usage

## Advanced Wrapper

Most users should ignore this and use plain `codex` after `./scripts/install.ps1`.

Use the wrapper only when you deliberately want an explicit per-run override instead of relying on the installed default provider.

## Notes

- The proxy only works when the local stack is running on the host/port configured in `.env`.
- Codex authentication remains handled by Codex/OpenAI rather than by the proxy.
- After installation, the intended day-to-day workflow is plain `codex`, not the wrapper script.
