# Public Repository Wrap-up Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add public-facing repository documentation and baseline Git metadata without changing application behavior.

**Architecture:** Keep all runtime code untouched. Limit changes to repository root metadata files and planning docs so the public repo becomes readable and safer to maintain. Use narrow ignore rules, explicit line-ending guidance, and a concise README that maps the existing project structure.

**Tech Stack:** Git, GitHub, Markdown, `.gitignore`, `.gitattributes`

---

### Task 1: Record the approved design

**Files:**
- Create: `docs/plans/2026-04-09-public-repo-wrapup-design.md`
- Create: `docs/plans/2026-04-09-public-repo-wrapup.md`

**Step 1: Write the design summary**

Capture the approved scope, non-goals, and validation criteria in the design document.

**Step 2: Write the implementation plan**

Document the exact repository files to create or modify and keep the scope limited to public-repo hygiene.

**Step 3: Verify the docs exist**

Run: `git status --short`
Expected: new files under `docs/plans/`

### Task 2: Tighten repository hygiene metadata

**Files:**
- Modify: `.gitignore`
- Create: `.gitattributes`

**Step 1: Extend ignore rules**

Add local-only tooling metadata such as `.codex/` and keep the existing exclusions for binaries, archives, logs, and keys.

**Step 2: Add attributes rules**

Define text normalization defaults, preserve CRLF for Windows shell files, and mark binary formats explicitly.

**Step 3: Verify the staged intent**

Run: `git diff -- .gitignore .gitattributes`
Expected: only repository metadata changes

### Task 3: Add root repository documentation

**Files:**
- Create: `README.md`

**Step 1: Summarize the project**

Write a short overview describing the repository as a Go-based P2P toolset with Windows-oriented deployment concerns.

**Step 2: Document source layout**

Explain `cmd/`, `sql/`, `.agent/`, and why runtime assets are intentionally not committed.

**Step 3: Add practical usage notes**

Document prerequisites and the expectation that users build from source or provide their own runtime configuration instead of relying on tracked binaries.

**Step 4: Verify readability**

Run: `Get-Content README.md`
Expected: a concise, accurate overview with no operational claims that exceed the current repo contents

### Task 4: Validate, commit, and publish

**Files:**
- Modify: `.gitignore`
- Create: `.gitattributes`
- Create: `README.md`
- Create: `docs/plans/2026-04-09-public-repo-wrapup-design.md`
- Create: `docs/plans/2026-04-09-public-repo-wrapup.md`

**Step 1: Verify repository state**

Run: `git status --short --branch`
Expected: only the intended wrap-up files are new or modified

**Step 2: Review the diff**

Run: `git diff -- .gitignore .gitattributes README.md docs/plans/`
Expected: documentation and metadata only, no source-code edits

**Step 3: Commit the wrap-up**

Run: `git add .gitignore .gitattributes README.md docs/plans/ && git commit -m "docs: add public repository wrap-up"`
Expected: a single documentation-focused commit

**Step 4: Push to GitHub**

Run: `git push origin main`
Expected: `main` updated on `origin`
