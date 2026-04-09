# Runtime Guide

This guide is for two audiences:

- Developers who need to build the executables from source.
- Deployment or operations users who need to understand which runtime files are expected and how the processes relate to each other.

It is intentionally conservative. The steps below are based on the current repository layout, the checked-in batch scripts, and the file paths hardcoded in the Go code. Where the repository does not provide a full deployment artifact, this guide calls that out explicitly.

## 1. Component Roles

### `p2p_proxy`

`p2p_proxy` is the central proxy node.

- P2P listen port: `8590`
- HTTP proxy port: `8686`
- Runtime key file: `p2p_proxy.key` in the current working directory
- Extra runtime outputs: `log/` directory and daily log files may be created at runtime

The proxy generates `p2p_proxy.key` automatically if it does not already exist.

### `p2p_agent`

`p2p_agent` connects the local machine or store-side environment back to `p2p_proxy`.

- P2P target port on proxy: `8590`
- Local client-side port: `8386`
- Local management and pprof HTTP port: `9301`
- Local HTTP forwarding port: `9300`
- Reads `Data/SystemPara.ini`
- Reads `Data/database.ini`
- Optionally reads `pg_targets.json`
- Optionally reads `vnc_targets.json`
- Needs the proxy private key as `keys/p2p_proxy.key` or `p2p_proxy.key` in the working directory

For its own local identity, the current implementation prefers a Windows registry key under `HKLM\SOFTWARE\SuperTouch\info` named `p2p_agent_key`. That means first-run behavior may require permission to read or write that registry location.

### `p2p_client`

`p2p_client` is a Windows-oriented local client process.

- Reads `Data/SystemPara.ini`
- Uses local port `8386`
- Exposes pprof on `9301`

The checked-in build script targets an older Go toolchain and `GOARCH=386`, which suggests compatibility with older Windows environments remains part of its current design.

### `p2p_monitor`

`p2p_monitor` is a watchdog-style helper.

- Current code watches for the window title `P2P_Agent_Client`
- Current code attempts to restart `p2p_agent.exe`
- The `p2p_proxy.exe` watcher is present in code but commented out

Treat it as an optional local helper, not as a replacement for service supervision.

## 2. Before You Build

The repository does not ship a universal build script. Instead, it contains several Windows batch files under `cmd/`:

- `cmd/p2p_agent.bat`
- `cmd/p2p_client.bat`
- `cmd/p2p_proxy.bat`
- `cmd/p2p_proxy_linux.bat`

Each script hardcodes a local `GO_BIN` path from the original author environment. You should expect to edit that variable before using the script on another machine.

Current checked-in examples:

- `p2p_agent.bat` points to `go1.20.14`
- `p2p_client.bat` points to `go1.10`
- `p2p_proxy.bat` points to `go1.25.5`
- `p2p_proxy_linux.bat` points to `go1.20.14`

That inconsistency is important. Do not assume a single Go version works for every submodule without testing.

## 3. Build Workflow

### Recommended approach

Use the existing batch scripts as the primary build entry points, because they encode the current `GOOS`, `GOARCH`, and module-directory expectations.

Examples:

```powershell
cd cmd
.\p2p_agent.bat
.\p2p_client.bat
.\p2p_proxy.bat
.\p2p_proxy_linux.bat
```

### What the scripts currently do

- Change into the corresponding module directory under `cmd/`
- Optionally run `go clean -modcache`
- Optionally run `go mod tidy` where the script supports it
- Build the executable into `..\..\bin\`

### Current target combinations from the scripts

- `p2p_agent`: `GOOS=windows`, `GOARCH=386`
- `p2p_client`: `GOOS=windows`, `GOARCH=386`
- `p2p_proxy`: `GOOS=windows`, `GOARCH=amd64`
- `p2p_proxy_linux`: `GOOS=linux`, `GOARCH=amd64`

### Manual build fallback

If you do not want to use the batch scripts, build from the specific module directory. For example:

```powershell
cd cmd\p2p_proxy
go build
```

Use this only after checking the corresponding batch file, because the script may encode target-architecture assumptions that matter for your environment.

## 4. Runtime Directory Expectations

This repository intentionally does not track the full runtime layout. At minimum, expect to supply or generate the following items outside Git:

### For `p2p_proxy`

- `p2p_proxy.exe` or Linux build output
- `p2p_proxy.key` in the process working directory
- writable `log/` directory or permission for the process to create it

The proxy can generate its own `p2p_proxy.key` if the file is missing.

### For `p2p_agent`

- `p2p_agent.exe`
- `Data/SystemPara.ini`
- `Data/database.ini`
- optionally `Data/database_custom.ini`
- optionally `pg_targets.json`
- optionally `vnc_targets.json`
- `keys/p2p_proxy.key` or `p2p_proxy.key`

The agent code references these files relative to its working directory. If you launch it from the wrong directory, file-not-found failures are likely.

### For `p2p_client`

- `p2p_client.exe`
- `Data/SystemPara.ini`

### For `p2p_monitor`

- `p2p_monitor.exe`
- `p2p_agent.exe` in the same working directory if you want restart behavior to work as currently coded

## 5. Conservative Startup Order

When bringing up a fresh environment, use this order:

1. Start `p2p_proxy` and confirm it can bind its ports and create or read `p2p_proxy.key`.
2. Place the proxy key where `p2p_agent` can read it, preferably `keys/p2p_proxy.key`.
3. Prepare the agent-side `Data/` files and optional target JSON files.
4. Start `p2p_agent`.
5. Start `p2p_client` only if that machine role is part of your deployment.
6. Start `p2p_monitor` only if you want local watchdog behavior for `p2p_agent.exe`.

This order keeps key-generation and dependency failures obvious.

## 6. Ports And Process Boundaries

These are the main ports visible from the checked-in code:

- `8590`: `p2p_proxy` P2P listen port
- `8686`: `p2p_proxy` HTTP proxy port
- `9301`: `p2p_agent` management and pprof HTTP port
- `9300`: `p2p_agent` local HTTP forwarding port
- `8386`: `p2p_agent` local client-side connection port

One important caveat from the current codebase: `p2p_client` also uses `8386` and `9301`. If you try to run `p2p_agent` and `p2p_client` on the same host without further changes, port conflicts are likely.

Before concluding a process is broken, confirm the port is not already occupied by another copy or blocked by the host firewall.

## 7. Troubleshooting

### Build fails immediately

Check the corresponding `cmd/*.bat` script first.

- `GO_BIN` may still point to the original machine path.
- The script may be targeting `386` or `amd64` explicitly.
- `p2p_client.bat` intentionally skips `go mod tidy` because the checked-in script assumes a Go 1.10 workflow.

### Process starts but cannot find config files

Check the working directory you used to start the executable.

- `p2p_agent` and `p2p_client` both read `Data/SystemPara.ini` relative to the process directory.
- `p2p_agent` also reads `Data/database.ini` and optional target JSON files relative to that directory.
- `p2p_proxy` reads and writes `p2p_proxy.key` relative to its process directory.

### Agent cannot load the proxy key

Check these locations in order:

1. `keys/p2p_proxy.key`
2. `p2p_proxy.key` in the current working directory

If neither exists, `p2p_agent` will fail during startup.

### Proxy starts on one machine but agent cannot connect

Check the basics first:

- `p2p_proxy` is actually listening on `8590`
- firewall rules allow inbound traffic to `8590`
- the agent-side configuration resolves the expected proxy address
- the proxy key being used by the agent matches the proxy instance you started

### You need runtime diagnostics

The repository already contains pprof exposure points:

- `p2p_proxy` comments reference `http://<host>:8686/debug/pprof/...`
- `p2p_agent` exposes pprof handlers on port `9301`
- `p2p_client` also starts pprof on `9301`

Do not expose these endpoints publicly without additional protection.

## 8. What This Guide Does Not Guarantee

This document does not claim that:

- all checked-in modules are aligned to one Go version
- the same deployment layout fits every historical environment
- every optional runtime file is present in Git

It is a practical map of the current repository, not a formal release manual.
