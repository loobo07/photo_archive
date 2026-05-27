# Architecture

This project intentionally stays small: one exporter script and one shell test
harness.

## Exporter Script

`scripts/export_photos_originals.zsh` is the main entrypoint. It is organized
around a few responsibilities:

- Parse command-line options.
- Convert user-friendly layouts into `osxphotos` directory templates.
- Discover eligible mounted volumes under `/Volumes`.
- Validate target filesystem and free space before exporting.
- Ensure `osxphotos` exists, with an interactive `pipx` install prompt if not.
- Build and run the `osxphotos export` command.

The script defaults to:

```text
~/Pictures/Photos Library.photoslibrary
```

as the source library and:

```text
Photos Originals Export
```

as the destination folder on the selected external volume.

## Safety Model

The script avoids starting a large export until these checks pass:

- The Photos library directory exists.
- The target is under `/Volumes`.
- The target is not `Macintosh HD`.
- The target filesystem is APFS or Mac OS Extended Journaled.
- The target has at least the configured free-space minimum.
- A dry run completes unless `--skip-dry-run` is passed.
- The user confirms the real export after the dry run.

Tiny app disk images are filtered out by the free-space requirement, so they are
not presented as export candidates.

The destination export folder is created only after the real-export confirmation.
`--dry-run-only` exits without creating that folder.

## Folder Layouts

The script supports two layout names:

```text
yyyy-mm-dd-type -> {created.year}/{created.mm}/{created.dd}/{media_type}
type-yy-mm-dd   -> {media_type}/{created.yy}/{created.mm}/{created.dd}
```

These are passed to `osxphotos` through the `--directory` option.

## Test Harness

`tests/export_photos_originals_test.zsh` verifies behavior that can be checked
without exporting real photos:

- Default layout template generation.
- Alternate layout template generation.
- Generated `osxphotos export` command includes the required options.
- The no-target-volume path exits before dependency installation.

Run it with:

```zsh
zsh tests/export_photos_originals_test.zsh
```

Also run shell syntax checks:

```zsh
zsh -n scripts/export_photos_originals.zsh
zsh -n tests/export_photos_originals_test.zsh
```

## External Dependency

The core export work is delegated to
[`osxphotos`](https://rhettbull.github.io/osxphotos/). This project does not
parse the Photos SQLite database directly and does not copy files out of the
Photos library bundle by hand.
