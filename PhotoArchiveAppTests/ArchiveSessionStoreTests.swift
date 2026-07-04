import Foundation
import PhotoArchiveCore

extension PhotoArchiveCoreTestRunner {
  @MainActor
  static func runArchiveSessionStoreTests() async throws {
    try await storeMarksDryRunSuccessAndEnablesExport()
    try await storeMarksDryRunFailureAndKeepsExportDisabled()
    try await storeInvalidatesExportReadinessWhenOptionsChangeAfterDryRun()
    try await storeMarksExportSuccess()
    try await storeMarksExportFailure()
    try storeClearsLogs()
  }

  @MainActor
  static func storeMarksDryRunSuccessAndEnablesExport() async throws {
    let runner = FakeRunner(results: [ProcessResult(exitCode: 0)])
    let store = ArchiveSessionStore(runner: runner)

    await store.startDryRun()

    try expect(store.phase == .dryRunSucceeded, "dry-run success updates phase")
    try expect(store.canExport, "dry-run success enables export")
    try expect(runner.modes == [.dryRunOnly], "store runs dry-run mode")
    try expect(store.logs.contains { $0.text == "ran dryRunOnly" }, "store appends runner logs")
  }

  @MainActor
  static func storeMarksDryRunFailureAndKeepsExportDisabled() async throws {
    let runner = FakeRunner(results: [ProcessResult(exitCode: 2)])
    let store = ArchiveSessionStore(runner: runner)

    await store.startDryRun()

    try expect(store.phase == .failed("Dry run failed with exit code 2"), "dry-run failure updates phase")
    try expect(!store.canExport, "dry-run failure keeps export disabled")
  }

  @MainActor
  static func storeInvalidatesExportReadinessWhenOptionsChangeAfterDryRun() async throws {
    let runner = FakeRunner(results: [ProcessResult(exitCode: 0)])
    let store = ArchiveSessionStore(runner: runner)
    await store.startDryRun()

    store.updateOptions(ExportOptions(targetPath: "/Volumes/NewDrive"))

    try expect(store.phase == .editingOptions, "option change returns to editing")
    try expect(!store.canExport, "option change invalidates export readiness")
  }

  @MainActor
  static func storeMarksExportSuccess() async throws {
    let runner = FakeRunner(results: [ProcessResult(exitCode: 0), ProcessResult(exitCode: 0)])
    let store = ArchiveSessionStore(runner: runner)
    await store.startDryRun()

    await store.startExport()

    try expect(store.phase == .exportSucceeded, "export success updates phase")
    try expect(runner.modes == [.dryRunOnly, .export], "store runs dry-run then export")
  }

  @MainActor
  static func storeMarksExportFailure() async throws {
    let runner = FakeRunner(results: [ProcessResult(exitCode: 0), ProcessResult(exitCode: 9)])
    let store = ArchiveSessionStore(runner: runner)
    await store.startDryRun()

    await store.startExport()

    try expect(store.phase == .failed("Export failed with exit code 9"), "export failure updates phase")
    try expect(!store.canExport, "export failure disables export")
  }

  @MainActor
  static func storeClearsLogs() throws {
    let store = ArchiveSessionStore(runner: FakeRunner(results: []))
    store.appendLogLine(ProcessLogLine(stream: .stdout, text: "hello"))

    store.clearLogs()

    try expect(store.logs.isEmpty, "clear logs empties log buffer")
  }
}

private final class FakeRunner: ExporterProcessRunning {
  private var results: [ProcessResult]
  private(set) var modes: [ExportRunMode] = []

  init(results: [ProcessResult]) {
    self.results = results
  }

  func run(
    options: ExportOptions,
    mode: ExportRunMode,
    onLogLine: @escaping (ProcessLogLine) -> Void
  ) async throws -> ProcessResult {
    modes.append(mode)
    onLogLine(ProcessLogLine(stream: .stdout, text: "ran \(mode)"))
    return results.removeFirst()
  }
}
