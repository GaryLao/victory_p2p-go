# victory_p2p-go

`victory_p2p-go` is a Go-based P2P toolset for connecting Windows-side business environments to remote services through a libp2p-based network. The repository contains source code, SQL utilities, and internal workflow notes, while generated binaries, logs, customer assets, and private keys are intentionally excluded from version control.

## Repository Layout

### `cmd/`

Main application source code and local launcher scripts.

- `cmd/p2p_proxy/`: central P2P proxy and request-routing service.
- `cmd/p2p_agent/`: agent-side service that connects local resources to the proxy.
- `cmd/p2p_client/`: Windows-oriented client process for local connectivity and update logic.
- `cmd/p2p_monitor/`: watchdog process used to keep selected executables running.
- `cmd/p2p_agent_old/`: older agent implementation retained for comparison or fallback.
- `cmd/other/`: experimental or reference code snippets that support operational tuning.
- `cmd/*.bat`: local Windows launch scripts for the main executables.

### `sql/`

Database bootstrap and maintenance helpers.

- PostgreSQL schema creation scripts.
- SQL cleanup and export checks.
- Small Go utilities for generating or parsing SQL comments.

### `.agent/`

Workflow notes used to describe how the main binaries are built or packaged.

### `.github/`

Repository-level instructions and GitHub-side guidance files.

## Notes For Public Use

- This repository is source-first. Runtime binaries, logs, packaged archives, and customer-specific deployment files are not tracked here.
- Sensitive assets such as `*.key` files are intentionally ignored and must be supplied through your own secure deployment process.
- The project is Windows-heavy in its operational model, but the Go source is organized per executable under `cmd/`.

## Building

Each executable currently has its own Go module directory. Build from the specific module you need, for example:

```powershell
cd cmd\p2p_agent
go build
```

Other entry points follow the same pattern:

- `cmd/p2p_proxy`
- `cmd/p2p_client`
- `cmd/p2p_monitor`
- `sql/parse_comments`
- `sql/ai_column_comments`

## Repository Hygiene

The root `.gitignore` excludes local IDE settings, generated binaries, backup archives, logs, and private key material. The root `.gitattributes` keeps text-file normalization predictable while preserving CRLF for Windows shell scripts.
