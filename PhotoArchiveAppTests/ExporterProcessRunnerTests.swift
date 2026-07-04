import Foundation
import PhotoArchiveCore

extension PhotoArchiveCoreTestRunner {
  static func runExporterProcessRunnerTests() async throws {
    try await runnerStreamsOutputAndPreservesArgumentsWithSpaces()
    try await runnerStreamsOutputBeforeProcessExits()
    try await runnerReturnsNonzeroExitStatus()
  }

  static func runnerStreamsOutputAndPreservesArgumentsWithSpaces() async throws {
    let stub = try StubScript(
      body: """
      #!/bin/zsh
      print -r -- "stdout:$*"
      print -r -- "stderr:$*" >&2
      exit 0
      """
    )
    let runner = ExporterProcessRunner(scriptPath: stub.path)
    let options = ExportOptions(
      libraryPath: "/Users/example/Pictures/Photos Library.photoslibrary",
      targetPath: "/Volumes/My Photos",
      exportFolder: "Archive Export",
      layout: .yyyyMmDdType,
      dateTarget: .day("2024-07-19"),
      minimumFreeGB: 250,
      limit: 10
    )
    let logSink = LockedLogSink()

    let result = try await runner.run(options: options, mode: .dryRunOnly) { line in
      logSink.append(line)
    }
    let logLines = logSink.lines

    try expect(result.exitCode == 0, "runner returns zero exit code")
    try expect(result.succeeded, "runner marks zero exit code as succeeded")
    try expect(logLines.contains { $0.stream == .stdout && $0.text.contains("/Volumes/My Photos") }, "stdout preserves path with spaces")
    try expect(logLines.contains { $0.stream == .stderr && $0.text.contains("Archive Export") }, "stderr preserves path with spaces")
    try expect(logLines.contains { $0.text.contains("--dry-run-only") }, "dry-run-only flag is passed")
  }

  static func runnerReturnsNonzeroExitStatus() async throws {
    let stub = try StubScript(
      body: """
      #!/bin/zsh
      print -r -- "bad target" >&2
      exit 44
      """
    )
    let runner = ExporterProcessRunner(scriptPath: stub.path)
    let logSink = LockedLogSink()

    let result = try await runner.run(options: ExportOptions(targetPath: "/Volumes/PhotoDrive"), mode: .export) { line in
      logSink.append(line)
    }
    let logLines = logSink.lines

    try expect(result.exitCode == 44, "runner returns nonzero exit code")
    try expect(!result.succeeded, "runner marks nonzero exit code as failure")
    try expect(logLines.contains { $0.stream == .stderr && $0.text == "bad target" }, "stderr line is streamed")
  }

  static func runnerStreamsOutputBeforeProcessExits() async throws {
    let stub = try StubScript(
      body: """
      #!/bin/zsh
      print -r -- "started"
      sleep 1
      print -r -- "finished"
      exit 0
      """
    )
    let runner = ExporterProcessRunner(scriptPath: stub.path)
    let started = AsyncSignal()

    let task = Task {
      try await runner.run(options: ExportOptions(targetPath: "/Volumes/PhotoDrive"), mode: .dryRunOnly) { line in
        if line.text == "started" {
          Task {
            await started.signal()
          }
        }
      }
    }

    try await expect(started.wait(timeoutNanoseconds: 500_000_000), "runner streams the first line before process exit")
    let result = try await task.value
    try expect(result.succeeded, "streaming process still succeeds")
  }
}

private actor AsyncSignal {
  private var signaled = false

  func signal() {
    signaled = true
  }

  func wait(timeoutNanoseconds: UInt64) async -> Bool {
    let step: UInt64 = 10_000_000
    var elapsed: UInt64 = 0

    while elapsed < timeoutNanoseconds {
      if signaled {
        return true
      }
      try? await Task.sleep(nanoseconds: step)
      elapsed += step
    }

    return signaled
  }
}

private final class LockedLogSink {
  private let lock = NSLock()
  private var storage: [ProcessLogLine] = []

  var lines: [ProcessLogLine] {
    lock.lock()
    defer { lock.unlock() }
    return storage
  }

  func append(_ line: ProcessLogLine) {
    lock.lock()
    storage.append(line)
    lock.unlock()
  }
}

private struct StubScript {
  let path: String

  init(body: String) throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("photo-archive-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let script = directory.appendingPathComponent("stub.zsh")
    try body.write(to: script, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
    path = script.path
  }
}
