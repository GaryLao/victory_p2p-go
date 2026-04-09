# Runtime Guide Design

## Goal

Add a practical runtime guide for both developers and deployment operators, organized around the real workflow of this repository: prepare environment, build binaries, assemble runtime files, start services, and troubleshoot common failures.

## Audience

- Developers who need to compile specific binaries from source.
- Deployment or operations users who need to understand the expected runtime directory shape and startup order.

## Scope

- Document the current build scripts under `cmd/*.bat`.
- Document runtime files and directories that the code expects but the repository does not track.
- Document the main executable roles, important ports, and a conservative startup order.
- Document only troubleshooting steps that are directly supported by the repository contents.

## Non-Goals

- No attempt to define a single canonical production topology.
- No promise that all environments use the same Go version or operating system.
- No new automation or code changes.

## Source-of-Truth Rules

This guide should be written from the repository evidence only:

- Batch scripts define the current build entry points and the locally hardcoded `GO_BIN` examples.
- Code in `cmd/p2p_agent`, `cmd/p2p_client`, `cmd/p2p_proxy`, and `cmd/p2p_monitor` defines ports, config file paths, and key-loading behavior.
- Excluded runtime assets such as `bin/`, `Data/`, `keys/`, and logs must be described as external prerequisites, not tracked repository contents.

## Proposed Document Structure

1. Overview and audience
2. Component roles
3. Environment preparation
4. Build instructions from the existing batch scripts
5. Runtime directory expectations
6. Recommended startup sequence
7. Common troubleshooting

## Validation

Success means:

- The guide stays aligned with actual file names and code paths in the repo.
- The README links to the runtime guide.
- The changes remain documentation-only.
