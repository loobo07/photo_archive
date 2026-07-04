# macOS App POC Design

## Main Window

Use one normal macOS app window with a simple setup-and-run workflow.

Recommended structure:

- Left or top setup area for options.
- Run/status area for dry run and export actions.
- Log area that fills remaining space.

Keep the UI utilitarian. This app is an operational tool for a risky archive
workflow, not a marketing page.

## Setup Controls

Required controls:

- Photos library path.
- Target volume path.
- Export folder name.
- Layout picker:
  - `yyyy-mm-dd-type`
  - `type-yy-mm-dd`
- Date scope picker:
  - full archive
  - hour
  - day
  - month
  - date range
- Minimum free GB.
- Optional limit for test exports.

## Run Controls

Required actions:

- Start dry run.
- Start real export.
- Clear logs.

The real export action stays disabled until the current options have a
successful dry run.

Current implementation:

- `RunView` calls `ArchiveSessionStore.startDryRun()`.
- `RunView` calls `ArchiveSessionStore.startExport()`.
- `RunView` disables export while `canExport` is false or a process is running.
- `ArchiveSessionStore` resets `canExport` whenever options change.

## Status

Show these states clearly:

- Editing options.
- Dry run running.
- Dry run succeeded.
- Export running.
- Export succeeded.
- Failed with message.

## Log View

The log view should show streamed process output with enough context to diagnose
failures:

- Timestamp.
- Stream name: stdout or stderr.
- Text.

Do not hide raw CLI errors. The existing CLI messages are part of the safety
contract.

Current implementation:

- `ExporterProcessRunner` captures stdout and stderr separately.
- `ProcessLogLine` records timestamp, stream, and text.
- `LogView` renders streamed lines with stdout/stderr labels.

## Desktop Behavior

- Use a normal `WindowGroup`.
- Use native SwiftUI controls.
- Prefer system colors and materials.
- Keep primary actions available as buttons first.
- Keyboard shortcuts can be added later after the POC flow works.
