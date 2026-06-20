# Archive Lifecycle Design

## Purpose

Extend the macOS archive CLI with explicit dry, safe, and delete workflows.
The design preserves the existing export safety checks and makes source deletion
a separate, locally initiated, manifest-gated operation.

## Workflows

### Dry mode

Dry mode is the only lifecycle mode suitable for automated tests and pull
request checks. It validates options, builds the planned export and lifecycle
actions, and logs them without changing Photos, the target volume, or the local
filesystem outside temporary test fixtures.

### Safe mode

Safe mode exports originals and XMP sidecars to the chosen external drive. Once
the export is verified, it writes an archive manifest recording source asset
identifiers, archive locations, and verification results. It then adds those
verified source assets to a dedicated `Archived Externally` Photos album. It
does not delete or hide source media.

### Delete mode

Delete mode accepts an existing successful manifest, revalidates every recorded
archive copy, and computes a deletion set only for matching verified assets. It
displays the count and identifiers, requires an explicit typed confirmation,
and then moves those assets to Apple Photos' built-in Recently Deleted album.
It must refuse to run in CI, from dry mode, with a missing or invalid manifest,
or when any archive verification fails. Permanent deletion is out of scope.

## Boundaries

`Archived Externally` is a non-destructive organizational marker; it is never
the sole authority for deletion. The manifest is the deletion authority.
Recently Deleted remains Apple Photos' recovery mechanism and is not used to
track successful archives.

## Testing

Unit tests will stub Photos, `osxphotos`, and filesystem commands to prove dry
mode performs no writes, safe mode records only verified exports, and delete
mode refuses unsafe conditions. GitHub Actions continues to run only dry-mode
tests on macOS. Real exports and deletions are always local, interactive actions.
