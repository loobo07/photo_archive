# macOS App POC Scope

## Goal

Build a small native macOS app POC that makes the existing Photo Archive CLI
easier to operate without changing export behavior.

The app should collect export options, run dry runs, run real exports, stream
process output, and make it obvious when a real export is allowed.

## Current Ground Truth

- Stable CLI entrypoint: `scripts/export_photos_originals.zsh`
- Shell test harness: `tests/export_photos_originals_test.zsh`
- Runtime dependency: `osxphotos`
- Platform scope: macOS only
- Target volumes: mounted under `/Volumes`
- Default export folder: `Photos Originals Export`
- Default layout: `YYYY/MM/DD/type`
- Date targeting: hour, day, month, or inclusive date range
- Safety model: library exists, target volume is eligible, filesystem is
  accepted, free space threshold is met, dry run happens before real export

## POC In Scope

- SwiftUI main window.
- User-editable export options.
- Dry-run action.
- Real-export action gated by current-session dry-run success.
- Streaming stdout and stderr logs.
- Process exit status and failure display.
- Testable process runner using a stub script.
- Testable session store using a runner protocol.

## POC Out Of Scope

- Rewriting the exporter in Swift.
- Direct Photos SQLite parsing.
- Deletion workflow.
- Manifest workflow.
- Automatic dependency installation from the app.
- Menu bar app.
- Cross-platform UI.
- Production packaging or notarization.
- New production dependencies without confirmation.

## Core Product Rule

The app is a control plane. The CLI remains the source of truth for export
behavior and safety checks.

