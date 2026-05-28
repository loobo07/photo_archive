# Install

Photo Archive is macOS-first. The current exporter targets Apple Photos through
`osxphotos`, so Windows and Linux are not supported for real Photos exports yet.

## Prerequisites

- macOS
- Homebrew
- `pipx`
- `osxphotos`
- `just`

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
