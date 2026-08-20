# Codex CLI Setup

This integration keeps the proxy runtime separate from Codex-specific configuration.

## Fast Path

For a teammate who just needs the working Codex flow:

1. Run `./scripts/install.ps1`
2. Run `./scripts/codex-status.ps1`
3. Start the privacy stack when needed with `./scripts/start.ps1`
4. Open any repo and run `codex` normally

## Requirements

- Docker Desktop
- PowerShell
- `codex` installed and available on `PATH`

## One-Time Setup

Run:

```powershell
./scripts/install.ps1
```

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
base_url = "http://127.0.0.1:8000"
wire_api = "responses"
requires_openai_auth = true
supports_websockets = false
```

If you changed `CODEX_PROVIDER_ID`, `PRIVACY_PROVIDER_NAME`, or `PROXY_PORT` in `.env`, the installed provider block will follow those values.

## Step By Step

1. Sign in with `codex login` if needed.
2. Run `./scripts/install.ps1` once on the machine.
3. Start the proxy stack with `./scripts/start.ps1`.
4. Check readiness with `./scripts/codex-status.ps1`.
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

Use these checks before real usage or teammate handoff:

```powershell
./scripts/status.ps1
./scripts/test.ps1
./scripts/codex-status.ps1
```

What `./scripts/codex-status.ps1` should show:

- `Codex login status: Logged in`
- `Provider configured: True`
- `Default model_provider: privacy`
- `Analyzer health: ok`
- `Proxy health: ok`

## Proof For Teammates

If you want a concrete demo that does not depend on guessing from container logs:

1. Start the stack with `./scripts/start.ps1`.
2. In one terminal, optionally watch proxy traffic with `docker logs -f llm-cli-privacy-proxy`.
3. In another terminal, call `/protect` with sample PII or secrets.
4. Show that the response contains `GP_*` placeholders and a `session_id`.
5. Call `/restore` with that `session_id` and the placeholder text.
6. Show that the original values return locally.

Example:

```powershell
$body = @{
  text = "My name is Jonas, email jonas@example.com, phone +37061234567, and API key sk-test-1234567890"
  language = "en"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:8000/protect" -Method Post -ContentType "application/json" -Body $body
```

What to show:

- proxy logs show `POST /responses` for real Codex traffic or `/protect` for the explicit demo
- `/protect` output shows tokenized placeholders instead of raw values
- `/restore` output shows the original values reconstructed locally

This is stronger evidence than raw container logs alone, because the current proxy logs intentionally avoid printing prompt contents.

## Which Script To Use

- `install.ps1`: one-time Codex + proxy setup
- `codex-status.ps1`: readiness check for login, provider, and local proxy health
- `start.ps1`: bring the local privacy stack up before coding sessions
- `stop.ps1`: stop the local privacy stack when done
- `codex-with-privacy.ps1`: optional wrapper if you want an explicit one-shot provider override
- `codex-with-privacy.ps1 -Exec`: optional wrapper for non-interactive one-shot usage

## Notes

- The proxy only works when the local stack is running on the host/port configured in `.env`.
- Codex authentication remains handled by Codex/OpenAI rather than by the proxy.
- After installation, the intended day-to-day workflow is plain `codex`, not the wrapper script.
