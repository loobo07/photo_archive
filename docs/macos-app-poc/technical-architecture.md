# macOS App POC Technical Architecture

## Architecture Decision

Use a SwiftUI app that orchestrates the existing zsh exporter through a narrow
process-running service.

This keeps the POC small and preserves the current CLI contract. A later version
can extract shared Swift logic if the app proves useful.

The current implementation follows this architecture through a SwiftPM package:

- `Sources/PhotoArchiveCore`: shared models, store, and process service.
- `Sources/PhotoArchiveApp`: SwiftUI app shell.
- `PhotoArchiveAppTests`: package-local test runner sources.
- `script/build_and_run.sh`: build and launch entrypoint for the generated app
  bundle.

## Layers

```text
SwiftUI Views
  -> ArchiveSessionStore
    -> ExporterProcessRunning protocol
      -> ExporterProcessRunner
        -> scripts/export_photos_originals.zsh
          -> osxphotos, diskutil, df
```

## Suggested File Boundaries

```text
PhotoArchiveApp/
  App/
    PhotoArchiveApp.swift
  Models/
    ExportOptions.swift
    ExportPhase.swift
    ProcessLogLine.swift
  Stores/
    ArchiveSessionStore.swift
  Services/
    ExporterProcessRunner.swift
    ScriptPathResolver.swift
  Views/
    ContentView.swift
    SetupView.swift
    RunView.swift
    LogView.swift
```

## Responsibilities

- `PhotoArchiveApp.swift`: app entrypoint and main `WindowGroup`.
- `ExportOptions.swift`: typed representation of CLI options.
- `ExportPhase.swift`: session state machine.
- `ProcessLogLine.swift`: timestamped stdout and stderr lines.
- `ArchiveSessionStore.swift`: owns options, phase, logs, and export readiness.
- `ExporterProcessRunner.swift`: launches the shell script with `Process`.
- `ScriptPathResolver.swift`: resolves development or bundled script location.
- `ContentView.swift`: high-level layout.
- `SetupView.swift`: library, target, layout, date scope, limit, and free-space
  controls.
- `RunView.swift`: dry-run/export buttons and status.
- `LogView.swift`: streaming output.

## Process Execution Rules

- Pass arguments as an array to `Process`; do not build a shell string.
- Preserve paths with spaces.
- Capture stdout and stderr separately.
- Append process output to the session log as it arrives.
- Return the real exit status.
- Disable option editing while a process is running.

## Export Readiness Rule

A real export is enabled only when the current options have completed a
successful dry run.

Any option change invalidates export readiness.

## Testing Strategy

- Model tests cover option-to-argument mapping and date-target representation.
- Runner tests use a local stub script, not the real exporter.
- Store tests use a fake runner protocol implementation.
- Current Swift checks run through `swift run PhotoArchiveCoreTestRunner`
  because this local Command Line Tools install does not expose XCTest or Swift
  Testing to SwiftPM test targets.
- CLI tests remain in `tests/export_photos_originals_test.zsh`.

Verification commands:

```zsh
swift run PhotoArchiveCoreTestRunner
swift build --product PhotoArchiveApp
just check
bash -n script/build_and_run.sh
./script/build_and_run.sh --verify
```
