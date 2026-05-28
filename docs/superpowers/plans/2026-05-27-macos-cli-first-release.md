# macOS CLI First Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare Photo Archive for a minimal public GitHub release as a macOS-first CLI with clear install, test, and contributor workflows.

**Architecture:** Keep the current `zsh` exporter as the product entrypoint for v1 and wrap it with repo-level tooling instead of rewriting the app. Add a `justfile` for repeatable local commands, GitHub Actions for macOS CI, install docs that use Homebrew for prerequisites, and release docs that leave room for future Windows/Linux backends without claiming current support.

**Tech Stack:** zsh, osxphotos, pipx, Homebrew, just, GitHub Actions on macOS.

---

## File Structure

- Create: `.gitignore` for macOS/editor/test artifact hygiene.
- Create: `justfile` for discoverable local commands.
- Create: `.github/workflows/ci.yml` for macOS CI syntax/test checks.
- Create: `docs/install.md` for end-user macOS install instructions.
- Create: `docs/release.md` for maintainer release and GitHub publishing steps.
- Modify: `README.md` to describe public install, quick start, test commands, and platform support.
- Modify: `docs/architecture.md` to document the macOS-first boundary and future backend direction.
- Modify: `docs/getting-started.md` to link to installation and clarify first-run flow.
- Modify: `tests/export_photos_originals_test.zsh` only if the `just test` command reveals path or environment assumptions that need tightening.

## Task 1: Initialize Git Hygiene

**Files:**
- Create: `.gitignore`
- No test file changes expected.

- [ ] **Step 1: Write the expected ignore policy before creating `.gitignore`**

Use this policy:

```text
.DS_Store
*.log
tmp/
.tmp/
.cache/
coverage/
export-report.csv
Photos Originals Export/
```

This should ignore macOS metadata, local logs/caches, accidental export reports, and accidental local export folders.

- [ ] **Step 2: Create `.gitignore`**

Create `.gitignore` with exactly:

```gitignore
.DS_Store
*.log
tmp/
.tmp/
.cache/
coverage/
export-report.csv
Photos Originals Export/
```

- [ ] **Step 3: Verify ignored files are recognized after git init**

Run:

```bash
git init
git check-ignore .DS_Store export-report.csv "Photos Originals Export/"
```

Expected: all three paths are printed by `git check-ignore`.

- [ ] **Step 4: Commit**

Run:

```bash
git add .gitignore
git commit -m "chore: add repository ignore rules"
```

Expected: commit succeeds.

## Task 2: Add Local Task Runner

**Files:**
- Create: `justfile`
- Test: `tests/export_photos_originals_test.zsh`

- [ ] **Step 1: Write the failing task-runner check**

Run:

```bash
just --list
```

Expected before implementation: command fails because `just` is not installed or no `justfile` exists.

- [ ] **Step 2: Install `just` if needed**

If `just --version` fails, run:

```bash
brew install just
```

Expected: `just --version` prints a version.

- [ ] **Step 3: Create `justfile`**

Create `justfile` with exactly:

```make
set shell := ["zsh", "-cu"]

default:
    @just --list

fmt-check:
    zsh -n scripts/export_photos_originals.zsh
    zsh -n tests/export_photos_originals_test.zsh

test:
    zsh tests/export_photos_originals_test.zsh

check: fmt-check test

print-command:
    scripts/export_photos_originals.zsh --print-command --target "/Volumes/My Photos" --limit 10

smoke target:
    scripts/export_photos_originals.zsh --target "{{target}}" --limit 10
```

- [ ] **Step 4: Verify `just` lists the commands**

Run:

```bash
just --list
```

Expected: output includes `check`, `fmt-check`, `test`, `print-command`, and `smoke`.

- [ ] **Step 5: Run the new local check**

Run:

```bash
just check
```

Expected: syntax checks pass and test output includes `All export_photos_originals tests passed`.

- [ ] **Step 6: Commit**

Run:

```bash
git add justfile
git commit -m "chore: add local task runner"
```

Expected: commit succeeds.

## Task 3: Add macOS CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create GitHub Actions workflow**

Create `.github/workflows/ci.yml` with exactly:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    name: Shell tests
    runs-on: macos-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Run syntax checks
        run: |
          zsh -n scripts/export_photos_originals.zsh
          zsh -n tests/export_photos_originals_test.zsh

      - name: Run tests
        run: zsh tests/export_photos_originals_test.zsh
```

- [ ] **Step 2: Verify workflow YAML exists and shell tests still pass locally**

Run:

```bash
test -f .github/workflows/ci.yml
zsh -n scripts/export_photos_originals.zsh
zsh -n tests/export_photos_originals_test.zsh
zsh tests/export_photos_originals_test.zsh
```

Expected: all commands exit `0`, and test output includes `All export_photos_originals tests passed`.

- [ ] **Step 3: Commit**

Run:

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add macos shell test workflow"
```

Expected: commit succeeds.

## Task 4: Add macOS Install Documentation

**Files:**
- Create: `docs/install.md`
- Modify: `README.md`
- Modify: `docs/getting-started.md`

- [ ] **Step 1: Create `docs/install.md`**

Create `docs/install.md` with exactly:

```markdown
# Install

Photo Archive is macOS-first. The current exporter targets Apple Photos through
`osxphotos`, so Windows and Linux are not supported for real Photos exports yet.

## Prerequisites

- macOS
- Homebrew
- `pipx`
- `osxphotos`
- optional: `just`

## Install Prerequisites

```zsh
brew install pipx just
pipx ensurepath
pipx install osxphotos
```

Open a new terminal after `pipx ensurepath` if `osxphotos` is not found.

## Clone

```zsh
git clone https://github.com/<owner>/photo_archive.git
cd photo_archive
```

Replace `<owner>` with the GitHub account or organization that owns the repo.

## Verify

```zsh
just check
```

If you do not have `just` installed:

```zsh
zsh -n scripts/export_photos_originals.zsh
zsh -n tests/export_photos_originals_test.zsh
zsh tests/export_photos_originals_test.zsh
```

## First Export Smoke Test

Connect an external drive and run a limited export:

```zsh
scripts/export_photos_originals.zsh --target "/Volumes/YourDrive" --limit 10
```

Check the exported folder layout, media files, XMP sidecars, and
`export-report.csv` before running a full export.

## Platform Scope

The v1 CLI supports macOS only. Future Windows/Linux support should be designed
as separate source backends rather than forcing Apple Photos behavior onto other
operating systems.
```

- [ ] **Step 2: Update README install section**

In `README.md`, add this section after `## Requirements`:

```markdown
## Installation

See [Install](docs/install.md) for setup from a fresh clone.

For macOS with Homebrew:

```zsh
brew install pipx just
pipx ensurepath
pipx install osxphotos
```
```

- [ ] **Step 3: Update getting-started link**

In `docs/getting-started.md`, add this sentence after the title paragraph:

```markdown
If you are setting up the project for the first time, start with
[Install](install.md).
```

- [ ] **Step 4: Verify docs contain no placeholder owner in final README**

Run:

```bash
rg -n "T[[:alpha:]]D|TO[[:alpha:]]O|FIX[[:alpha:]]E|implement[[:space:]]later|fill[[:space:]]in" README.md docs --glob '!docs/superpowers/plans/**'
```

Expected: no matches and exit code `1`.

- [ ] **Step 5: Commit**

Run:

```bash
git add README.md docs/getting-started.md docs/install.md
git commit -m "docs: add macos install guide"
```

Expected: commit succeeds.

## Task 5: Document Architecture and Cross-Platform Boundary

**Files:**
- Modify: `docs/architecture.md`
- Create: `docs/platform-roadmap.md`

- [ ] **Step 1: Add macOS-first architecture note**

Append this section to `docs/architecture.md`:

```markdown
## Distribution Boundary

The v1 distribution keeps `scripts/export_photos_originals.zsh` as the stable
CLI entrypoint. Repository tooling (`justfile`, GitHub Actions, and install
docs) wraps that script without changing its runtime contract.

This is intentionally macOS-first because the exporter depends on Apple Photos,
mounted `/Volumes` paths, `diskutil`, and `osxphotos`. Future cross-platform
work should introduce source-specific backends behind a new CLI contract instead
of adding Windows/Linux conditionals to the current script.
```

- [ ] **Step 2: Create platform roadmap**

Create `docs/platform-roadmap.md` with exactly:

```markdown
# Platform Roadmap

## v1: macOS CLI

- Export originals from Apple Photos using `osxphotos`.
- Target external drives mounted under `/Volumes`.
- Provide Homebrew-oriented setup docs.
- Run CI on `macos-latest`.

## Future: Cross-Platform Core

Future Windows and Linux support should start with a source abstraction:

- macOS backend: Apple Photos via `osxphotos`.
- Windows backend: a normal filesystem/photo-folder source.
- Linux backend: a normal filesystem/photo-folder source.

The portable core should own destination layouts, reports, dry-run behavior, and
resume/update semantics. Source backends should own how media and metadata are
read from each platform.

Do not claim Windows or Linux install support until a backend exists and is
covered by CI.
```

- [ ] **Step 3: Link roadmap from README**

In `README.md`, add `- [Platform Roadmap](docs/platform-roadmap.md)` under `## More Documentation`.

- [ ] **Step 4: Verify docs**

Run:

```bash
rg -n "Windows|Linux|macOS" README.md docs --glob '!docs/superpowers/plans/**'
rg -n "T[[:alpha:]]D|TO[[:alpha:]]O|FIX[[:alpha:]]E|implement[[:space:]]later|fill[[:space:]]in" README.md docs --glob '!docs/superpowers/plans/**'
```

Expected: first command prints platform references; second command has no matches and exits `1`.

- [ ] **Step 5: Commit**

Run:

```bash
git add README.md docs/architecture.md docs/platform-roadmap.md
git commit -m "docs: document platform roadmap"
```

Expected: commit succeeds.

## Task 6: Prepare GitHub Publishing

**Files:**
- Create: `LICENSE`
- Create: `docs/release.md`
- Modify: `README.md`

- [ ] **Step 1: Create `LICENSE`**

Create `LICENSE` with the MIT License text and copyright holder:

```text
MIT License

Copyright (c) 2026 Edwin Lobo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Create release guide**

Create `docs/release.md` with exactly:

```markdown
# Release Guide

## First GitHub Publish

1. Confirm the default branch is `main`.
2. Confirm local checks pass:

   ```zsh
   just check
   ```

3. Create the GitHub repository:

   ```zsh
   gh repo create photo_archive --public --source=. --remote=origin --push
   ```

4. Confirm CI passes on GitHub.

## Versioned Release

1. Update release notes in the GitHub release body.
2. Tag the release:

   ```zsh
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. Create the release:

   ```zsh
   gh release create v0.1.0 --title "v0.1.0" --notes "Initial macOS CLI release."
   ```

## Homebrew Follow-Up

The v1 install path documents Homebrew prerequisites, but does not ship a tap.
Add a Homebrew tap only after the CLI name, repo URL, and release artifact shape
stabilize.
```

- [ ] **Step 3: Link license and release docs**

In `README.md`, add under `## More Documentation`:

```markdown
- [Release Guide](docs/release.md)
```

Also add a final section:

```markdown
## License

MIT. See [LICENSE](LICENSE).
```

- [ ] **Step 4: Verify release tooling is available**

Run:

```bash
gh --version
git branch --show-current
```

Expected: `gh --version` prints a version. `git branch --show-current` prints `main` after the branch is named in Task 7.

- [ ] **Step 5: Commit**

Run:

```bash
git add LICENSE README.md docs/release.md
git commit -m "docs: add release guide and license"
```

Expected: commit succeeds.

## Task 7: Final Repository Verification and Push

**Files:**
- No file changes expected unless verification exposes a defect.

- [ ] **Step 1: Ensure branch is `main`**

Run:

```bash
git branch -M main
git branch --show-current
```

Expected: output is `main`.

- [ ] **Step 2: Run full local checks**

Run:

```bash
just check
rg -n "T[[:alpha:]]D|TO[[:alpha:]]O|FIX[[:alpha:]]E|implement[[:space:]]later|fill[[:space:]]in" README.md docs scripts tests --glob '!docs/superpowers/plans/**'
```

Expected: `just check` passes. `rg` has no matches and exits `1`.

- [ ] **Step 3: Review git status**

Run:

```bash
git status --short
```

Expected: no output. If files are listed, either commit intentional changes or remove generated artifacts without deleting source files.

- [ ] **Step 4: Create GitHub repo and push**

Run:

```bash
gh repo create photo_archive --public --source=. --remote=origin --push
```

Expected: GitHub repository is created, `origin` is configured, and `main` is pushed.

- [ ] **Step 5: Confirm remote**

Run:

```bash
git remote -v
gh repo view --web=false
```

Expected: `origin` points to the new GitHub repo and `gh repo view` prints repo metadata.

- [ ] **Step 6: Confirm CI**

Run:

```bash
gh run list --limit 5
```

Expected: latest CI workflow appears. If it fails, run:

```bash
gh run view --log-failed
```

Use the failure log to make a narrow fix, then repeat `just check`, commit, and push.

## Self-Review

- Spec coverage: Covers git initialization, minimal macOS packaging, local commands, CI, install docs, release docs, GitHub push, and future Windows/Linux scope.
- Placeholder scan: The only placeholder-like value is `<owner>` in `docs/install.md`, intentionally documented as a value users replace after clone instructions; do not add unfinished marker text.
- Type consistency: Command names are consistent across tasks: `fmt-check`, `test`, `check`, `print-command`, and `smoke`.
