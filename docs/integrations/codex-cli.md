# Codex CLI Setup

This integration keeps the proxy runtime separate from Codex-specific configuration.

## Fast Path

For a teammate who just needs the working Codex flow:

1. Run `./scripts/install.ps1`
2. Run `./scripts/codex-status.ps1`
3. Launch Codex for a repo:

```powershell
./scripts/codex-with-privacy.ps1 -Workspace C:\path\to\your\repo
```

For non-interactive usage:

```powershell
./scripts/codex-with-privacy.ps1 -Exec -Workspace C:\path\to\your\repo -- "Summarize this repository"
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

What the helper does:

- checks `docker` and `codex`
- ensures the stack is built and running
- waits for analyzer and proxy health
- runs the smoke test
- appends the local proxy provider block to `~/.codex/config.toml` if needed
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
2. Start the proxy stack with `./scripts/start.ps1`.
3. Check readiness with `./scripts/codex-status.ps1`.
4. Launch Codex through the proxy:

```powershell
./scripts/codex-with-privacy.ps1 -Workspace C:\path\to\your\repo
```

If you run the wrapper from inside the target repo, `-Workspace` is optional.

For non-interactive usage, use the same wrapper with `-Exec`:

```powershell
./scripts/codex-with-privacy.ps1 -Exec -Workspace C:\path\to\your\repo -- "Summarize this repository"
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
- `Analyzer health: ok`
- `Proxy health: ok`

## Which Script To Use

- `install.ps1`: one-time Codex + proxy setup
- `codex-status.ps1`: readiness check for login, provider, and local proxy health
- `codex-with-privacy.ps1`: launch Codex through the privacy provider
- `codex-with-privacy.ps1 -Exec`: non-interactive Codex usage

## Notes

- The proxy only works when the local stack is running on the host/port configured in `.env`.
- Codex authentication remains handled by Codex/OpenAI rather than by the proxy.
- Interactive Codex sessions require a real terminal. In non-interactive shells, use `-Exec`.

