# macOS App POC Agent Context Packet

## Common Context For Every Worker

```text
You are working in /Users/edwinlobo/photo_archive.
The project is a macOS-first Apple Photos archive CLI.
The stable exporter entrypoint is scripts/export_photos_originals.zsh.
The shell test harness is tests/export_photos_originals_test.zsh.
The POC macOS app should orchestrate the CLI and stream output.
Do not rewrite the exporter in Swift.
Do not bypass the CLI safety model.
Do not add production dependencies without confirmation.
Use SwiftUI for views and Process for shell execution.
Pass process arguments as arrays, not shell strings.
Preserve paths with spaces.
Keep files small and focused.
Run `swift run PhotoArchiveCoreTestRunner` for current Swift app checks.
Read docs/macos-app-poc/scope.md before starting.
Read only the other docs needed for your task.
Return status, files changed, tests run, and unresolved concerns.
```

## Controller Instructions

Use sequential agentic development unless isolated worktrees are created. Do not
dispatch workers that edit the same files at the same time.

For each task:

1. Give the worker the common context.
2. Give the worker the exact task spec below.
3. Require tests or a clear explanation if tests cannot run.
4. Run a spec compliance review.
5. Run a code quality review.
6. Integrate only after both reviews pass.

## Worker 1: Models

Read:

- `docs/macos-app-poc/scope.md`
- `docs/macos-app-poc/technical-architecture.md`
- `docs/macos-app-poc/uml.md`

Task:

Create the Swift model types only.

Expected types:

- `ExportOptions`
- `ExportLayout`
- `DateTarget`
- `ExportPhase`
- `ProcessLogLine`
- `ProcessLogStream`

Acceptance:

- Model files compile.
- Date-target modes are explicit enough that invalid mixed modes cannot be
  represented accidentally by the UI.
- `ExportOptions` can produce CLI arguments for dry-run-only and real-export
  modes.
- No process launching or UI code is added.

## Worker 2: Process Runner

Read:

- `docs/macos-app-poc/scope.md`
- `docs/macos-app-poc/technical-architecture.md`
- `docs/macos-app-poc/diagrams.md`
- `docs/macos-app-poc/uml.md`

Task:

Create the process runner service.

Expected types:

- `ExporterProcessRunning`
- `ExporterProcessRunner`
- `ScriptPathResolver`
- `ProcessResult`

Acceptance:

- Runner launches the script using `Process`.
- Arguments are passed as an array.
- stdout and stderr are streamed to a callback.
- Exit status is returned.
- Runner can be tested with a stub script.
- No SwiftUI views are added.

## Worker 3: Session Store

Read:

- `docs/macos-app-poc/scope.md`
- `docs/macos-app-poc/technical-architecture.md`
- `docs/macos-app-poc/diagrams.md`
- `docs/macos-app-poc/uml.md`

Task:

Create `ArchiveSessionStore`.

Acceptance:

- Store owns options, phase, logs, and dry-run validity.
- Store exposes actions for starting dry run, starting export, changing options,
  and clearing logs.
- Store invalidates export readiness whenever options change.
- Store depends on `ExporterProcessRunning` so tests do not launch real exports.
- Tests cover successful dry run, failed dry run, option changes after dry run,
  successful export, and failed export.
- No SwiftUI layout is added.

## Worker 4: SwiftUI POC Shell

Read:

- `docs/macos-app-poc/scope.md`
- `docs/macos-app-poc/design.md`
- `docs/macos-app-poc/diagrams.md`

Task:

Create the native UI around `ArchiveSessionStore`.

Expected views:

- `ContentView`
- `SetupView`
- `RunView`
- `LogView`

Acceptance:

- UI compiles.
- Controls map to `ExportOptions`.
- Dry-run and real-export actions call the store.
- Real export is disabled until current options have a successful dry run.
- Logs stream visibly while a command runs.
- Views stay focused and small.

## Review Prompt

Use this for spec compliance review:

```text
Review the worker changes against docs/macos-app-poc/.
List any missing requirements, extra behavior, unsafe CLI bypasses, or files
outside the worker scope. If there are no issues, say "Spec compliant."
```

Use this for code quality review:

```text
Review the worker changes for Swift/macOS quality, testability, small file
boundaries, argument safety, and consistency with the existing CLI contract.
List issues by severity. If there are no issues, say "Approved."
```

## Verification Commands

For documentation-only changes:

```zsh
just check
```

For current Swift app code:

```zsh
swift run PhotoArchiveCoreTestRunner
swift build --product PhotoArchiveApp
zsh tests/export_photos_originals_test.zsh
```

If JavaScript files are introduced or modified:

```zsh
npm test
```
