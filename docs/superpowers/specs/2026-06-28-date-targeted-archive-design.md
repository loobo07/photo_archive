# Date-Targeted Archive Design

## Purpose

The exporter currently behaves like a full Apple Photos originals backup. Add
date-based targeting so users can archive only the photos and videos they need
while preserving the existing full-export behavior when no date filter is
provided.

## User-Facing Behavior

The CLI will support one date targeting mode per run:

```zsh
scripts/export_photos_originals.zsh --day 2024-07-19
scripts/export_photos_originals.zsh --hour 2024-07-19T14
scripts/export_photos_originals.zsh --month 2024-07
scripts/export_photos_originals.zsh --from 2024-07-01 --to 2024-07-31
```

No date option means the command remains a full archive export. `--limit` keeps
its current meaning and may be combined with any date target for small test
runs.

## Date Semantics

All targeting is based on the asset creation date as understood by `osxphotos`.
The supported shapes are:

- `--hour YYYY-MM-DDTHH`: includes assets created during that hour.
- `--day YYYY-MM-DD`: includes assets created during that date.
- `--month YYYY-MM`: includes assets created during that month.
- `--from YYYY-MM-DD --to YYYY-MM-DD`: includes assets from the start date
  through the end date.

The CLI rejects mixed targeting modes, such as `--day` with `--month`, and
rejects partial ranges where only `--from` or only `--to` is supplied.

## Architecture

Keep `scripts/export_photos_originals.zsh` as the single stable entrypoint. Add
a small set of helpers that validate date-target options and translate the
selected target into additional `osxphotos export` arguments. The command
builder and command runner should share the same argument-building path so
`--print-command`, dry runs, and real exports stay consistent.

No Photos database parsing will be added. The script will continue delegating
export selection to `osxphotos`.

## Error Handling

The script will fail before target validation or dependency checks if date
targeting input is invalid. Error messages should identify the bad option and
show the accepted format, for example:

```text
Error: --day must use YYYY-MM-DD
Error: use only one date target mode
Error: --from and --to must be used together
```

## Documentation

Update the README and getting-started guide with targeted archive examples.
Update the architecture documentation so future changes know that date filters
are validated locally and executed by `osxphotos`.

## Testing

Extend `tests/export_photos_originals_test.zsh` to cover:

- Printed commands include the expected date filter for `--day`.
- Printed commands include the expected date filter for `--hour`.
- Printed commands include the expected date filter for `--month`.
- Printed commands include the expected date filter for `--from` and `--to`.
- Invalid combinations fail with clear errors.
- Partial ranges fail with clear errors.

Run `just check` before completion. No `npm test` run is required because this
project has no JavaScript files and this feature does not add any.
