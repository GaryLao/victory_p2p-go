# Runtime Guide Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a practical runtime guide that helps users compile, assemble, start, and troubleshoot the current P2P toolchain.

**Architecture:** Keep all changes documentation-only. Create a dedicated guide under `docs/` so the root README stays concise, then add a README link to the detailed runtime document. Base the guide only on existing batch scripts, code-level constants, and file-path expectations already present in the repository.

**Tech Stack:** Markdown, Git, repository docs

---

### Task 1: Record the approved documentation design

**Files:**
- Create: `docs/plans/2026-04-09-runtime-guide-design.md`
- Create: `docs/plans/2026-04-09-runtime-guide-plan.md`

**Step 1: Write the design document**

Capture audience, scope, non-goals, and the source-of-truth constraints for the runtime guide.

**Step 2: Write the implementation plan**

Document the exact files to create or modify and keep the work documentation-only.

**Step 3: Verify the new planning docs are visible**

Run: `git status --short`
Expected: new files under `docs/plans/`

### Task 2: Create the runtime guide

**Files:**
- Create: `docs/runtime-guide.md`

**Step 1: Document component roles**

Describe `p2p_proxy`, `p2p_agent`, `p2p_client`, and `p2p_monitor` using repository evidence only.

**Step 2: Document build workflow**

Summarize the existing `cmd/*.bat` scripts, the hardcoded `GO_BIN` examples, and the current `GOOS`/`GOARCH` differences.

**Step 3: Document runtime prerequisites**

List external runtime files and directories referenced by the code, including `Data/SystemPara.ini`, `Data/database.ini`, `pg_targets.json`, `vnc_targets.json`, and key files.

**Step 4: Document startup and troubleshooting**

Provide a conservative startup order and a small set of failure checks that are grounded in current code paths and ports.

### Task 3: Add the README entry point

**Files:**
- Modify: `README.md`

**Step 1: Link the new runtime guide**

Add a short link in the root README so public readers can find the operational document immediately.

**Step 2: Keep README concise**

Do not duplicate the full runtime guide in the root README.

### Task 4: Verify and publish

**Files:**
- Create: `docs/runtime-guide.md`
- Modify: `README.md`
- Create: `docs/plans/2026-04-09-runtime-guide-design.md`
- Create: `docs/plans/2026-04-09-runtime-guide-plan.md`

**Step 1: Verify repository state**

Run: `git status --short --branch`
Expected: only documentation files are new or modified

**Step 2: Review the documentation diff**

Run: `git diff -- README.md docs/runtime-guide.md docs/plans/`
Expected: documentation-only changes with no source edits

**Step 3: Commit**

Run: `git add README.md docs/runtime-guide.md docs/plans/ && git commit -m "docs: add runtime guide"`
Expected: a docs-only commit

**Step 4: Push**

Run: `git push origin main`
Expected: the new runtime documentation is published to GitHub
