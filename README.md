# Photo Archive

Photo Archive is a small macOS command-line project for exporting original media
from Apple Photos to an external drive. It wraps
[`osxphotos`](https://rhettbull.github.io/osxphotos/) with guardrails for large
exports: target volume selection, filesystem checks, free-space checks, a dry run
before the real export, resumable updates, and date/type folder layouts.

The current default export layout is:

```text
YYYY/MM/DD/type
```

For example:

```text
/Volumes/My Photos/Photos Originals Export/2024/07/19/photo/IMG_1234.HEIC
/Volumes/My Photos/Photos Originals Export/2024/07/19/video/IMG_1235.MOV
```

## Codebase Overview

```text
.
├── scripts/
│   └── export_photos_originals.zsh
├── tests/
│   └── export_photos_originals_test.zsh
└── docs/
    ├── architecture.md
    └── getting-started.md
```

- `scripts/export_photos_originals.zsh` is the exporter entrypoint.
- `tests/export_photos_originals_test.zsh` verifies path templates, generated
  command options, and the no-target-volume error path.
- `docs/getting-started.md` explains how to prepare a drive and run the export.
- `docs/architecture.md` explains the script design and safety checks.

## Requirements

- macOS with `zsh`
- Apple Photos library, defaulting to:
  `~/Pictures/Photos Library.photoslibrary`
- External drive mounted under `/Volumes`
- `pipx`, used to install `osxphotos` if needed
- Target drive formatted as APFS or Mac OS Extended Journaled

The script defaults to requiring `250GB` free on the export target. Use a larger
drive for a full archive and future incremental exports.

## Quick Start

Connect the external drive, then run:

```zsh
scripts/export_photos_originals.zsh
```

The script will:

1. Find eligible mounted volumes under `/Volumes`.
2. Ask which target to use.
3. Validate filesystem type and free space.
4. Prompt to install `osxphotos` with `pipx` if it is missing.
5. Run an `osxphotos` dry run.
6. Ask before running the real export.

For a small test export first:

```zsh
scripts/export_photos_originals.zsh --target "/Volumes/My Photos" --limit 10
```

To organize by media type first:

```zsh
scripts/export_photos_originals.zsh --layout type-yy-mm-dd
```

## Export Behavior

The real export command includes these `osxphotos` behaviors:

- `--skip-edited`: export originals only, not edited renderings.
- `--sidecar XMP --sidecar-drop-ext`: write XMP metadata sidecars next to media.
- `--download-missing`: request missing iCloud originals during export.
- `--update`: make future runs resumable/incremental.
- `--retry 3`: retry transient export failures.
- `--touch-file`: set exported file timestamps from photo creation dates.
- `--report export-report.csv`: write an export report in the destination.

## Common Commands

Show supported options:

```zsh
scripts/export_photos_originals.zsh --help
```

Print the default directory template:

```zsh
scripts/export_photos_originals.zsh --print-template --layout yyyy-mm-dd-type
```

Print the generated export command without running it:

```zsh
scripts/export_photos_originals.zsh --print-command --target "/Volumes/My Photos"
```

The printed command quotes paths with spaces so it can be copied into a shell.

Run only the dry run:

```zsh
scripts/export_photos_originals.zsh --target "/Volumes/My Photos" --dry-run-only
```

`--dry-run-only` does not create the destination export folder.

## Testing

Run the shell test harness:

```zsh
zsh tests/export_photos_originals_test.zsh
```

Run syntax checks:

```zsh
zsh -n scripts/export_photos_originals.zsh
zsh -n tests/export_photos_originals_test.zsh
```

This project currently has no JavaScript files, so `npm test` is not applicable
unless JavaScript is added later.

## More Documentation

- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
