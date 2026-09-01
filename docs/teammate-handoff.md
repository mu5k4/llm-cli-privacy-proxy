# Zipped Project Startup

This note is for the teammate who receives the packaged project and needs to start and audit it without extra help.

The package to send is the newest zip from `dist/`.

## What They Need

- Windows 11
- Docker Desktop with Linux containers
- PowerShell
- `codex` on `PATH` if they want Codex CLI integration

## First Steps

1. Unzip the project.
2. Open PowerShell in the unzipped project folder.
3. If they want Codex CLI integration, close any running Codex CLI sessions first.
4. Read this note before running any scripts.

## If They Need Codex To Use The Proxy

Run the install script first:

```powershell
./scripts/install.ps1
```

Then verify it:

```powershell
./scripts/doctor.ps1
```

Expected result:

- `Codex login status: Logged in`
- `Provider configured: True`
- `Default model_provider: privacy`
- `Analyzer health: ok`
- `Proxy health: ok`

For audit work, this is the recommended path because it checks the full install flow, provider wiring, and the protect/restore behavior in one pass.

If they only want the lighter status summary without the full doctor run, they can use `./scripts/codex-status.ps1` instead.

After that, day-to-day usage is:

```powershell
./scripts/start.ps1
```

Then open the repo they want to work in and run `codex` normally.

## If They Only Need The Local Proxy Running

Run:

```powershell
./scripts/bootstrap.ps1
./scripts/start.ps1
./scripts/regression.ps1
./scripts/status.ps1
```

Expected result:

- analyzer health is `ok`
- proxy health is `ok`

Use this path when they only need to inspect the local stack behavior and do not want the Codex CLI integration written into `~/.codex/config.toml`.

## One-Command Check

For the broadest readiness check:

```powershell
./scripts/doctor.ps1
```

This is the best single command to run before starting the audit.

## Most Likely Failure On Windows

If install or uninstall fails with:

`Failed to read config file ... os error 32`

Do this:

1. Close all running Codex CLI sessions.
2. Rerun:

```powershell
./scripts/install.ps1
```

or

```powershell
./scripts/uninstall.ps1
```

Cause:

- those scripts rewrite `~/.codex/config.toml`
- an active Codex session can lock that file

## Stop Or Remove It

Stop the stack:

```powershell
./scripts/stop.ps1
```

Uninstall the integration:

```powershell
./scripts/uninstall.ps1
```

## Short Message To Send With The Zip

```text
Send the newest zip from dist.
Unzip the project and open PowerShell in the project folder.
Read docs/teammate-handoff.md first.
If you want Codex to use the proxy, close Codex first, run ./scripts/install.ps1, then run ./scripts/doctor.ps1.
If you only need the local proxy running for audit, run ./scripts/bootstrap.ps1, ./scripts/start.ps1, ./scripts/regression.ps1, and ./scripts/status.ps1.
Before the audit, run ./scripts/codex-status.ps1 or doctor.ps1.
If install fails with "os error 32", close Codex and rerun the install script.
```
