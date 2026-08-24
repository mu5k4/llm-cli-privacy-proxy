# Contributing

## Local Workflow

- Windows 11
- PowerShell
- Docker Desktop with Linux containers

## First-Time Setup

1. Run `./scripts/bootstrap.ps1`.
2. Review `.env` if you need non-default ports or provider naming.
3. Run `./scripts/start.ps1`.
4. Run `./scripts/regression.ps1`.

## Before Sharing Changes

1. Run `./scripts/regression.ps1`.
2. Run `./scripts/status.ps1`.
3. If you changed lifecycle or packaging behavior, run `./scripts/package.ps1`.
4. Do not include local `.env` or `privacy-cache/*.json` in shared artifacts.

## Versioning

- The current release marker lives in `./VERSION`
- Packaging uses that version string in the output archive name
- Add a short entry to `CHANGELOG.md` when behavior changes materially
