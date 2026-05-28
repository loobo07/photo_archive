# Getting Started

This guide walks through a safe first export from Apple Photos to an external
drive.

If you are setting up the project for the first time, start with
[Install](install.md).

## 1. Prepare the External Drive

Connect the drive and confirm it appears in Finder. The script only targets
mounted volumes under `/Volumes`.

Recommended drive setup:

- Format: APFS or Mac OS Extended Journaled
- Free space: at least `250GB` for the current export flow
- Capacity: `500GB+` for this export, `1TB+` if you want room for future exports

Avoid using a Time Machine backup disk as the export target.

## 2. Run a Small Test Export

Start with a limited export so you can verify the folder layout and metadata
sidecars before running a full archive:

```zsh
scripts/export_photos_originals.zsh --target "/Volumes/My Photos" --limit 10
```

Replace `/Volumes/My Photos` with the mounted drive name.

The default output folder is:

```text
/Volumes/My Photos/Photos Originals Export
```

The default layout is:

```text
YYYY/MM/DD/type
```

Example:

```text
Photos Originals Export/2024/07/19/photo/IMG_1234.HEIC
Photos Originals Export/2024/07/19/video/IMG_1235.MOV
```

## 3. Run the Full Export

After checking the test export, run:

```zsh
scripts/export_photos_originals.zsh --target "/Volumes/My Photos"
```

The script runs a dry run first and asks before starting the real export.
If you pass `--dry-run-only`, the script exits after preflight and does not
create the destination export folder.

If `osxphotos` is missing, the script prompts to install it with:

```zsh
pipx install osxphotos
```

## 4. Choose a Folder Layout

Default chronological layout:

```zsh
scripts/export_photos_originals.zsh --layout yyyy-mm-dd-type
```

This maps to:

```text
{created.year}/{created.mm}/{created.dd}/{media_type}
```

Media-type-first layout:

```zsh
scripts/export_photos_originals.zsh --layout type-yy-mm-dd
```

This maps to:

```text
{media_type}/{created.yy}/{created.mm}/{created.dd}
```

## 5. Verify the Export

After export:

- Open several exported photos and videos from different dates.
- Confirm `.xmp` files appear next to exported media where sidecars were written.
- Check `export-report.csv` in the export folder for skipped or failed items.
- Run the script again with the same target if needed; `--update` makes repeated
  runs incremental.

## Troubleshooting

### No External Target Volume Found

The script only lists mounted volumes under `/Volumes` that meet the free-space
minimum. Connect the drive, unlock it if encrypted, and make sure it has enough
free space.

To lower the free-space threshold for a small test drive:

```zsh
scripts/export_photos_originals.zsh --min-free-gb 10 --limit 10
```

### Unsupported Filesystem

The target must be APFS or Mac OS Extended Journaled. Reformat the drive with
Disk Utility if it is ExFAT, FAT32, NTFS, or another unsupported filesystem.

### Missing iCloud Originals

The script passes `--download-missing` to `osxphotos`. Keep the Mac awake and
connected to the internet during export so Photos/iCloud can provide originals.

### Export Interrupted

Run the same command again. The script includes `--update`, so `osxphotos` can
skip or update files it already exported.
