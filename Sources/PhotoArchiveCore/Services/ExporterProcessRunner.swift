import Foundation

public protocol ExporterProcessRunning {
  func run(
    options: ExportOptions,
    mode: ExportRunMode,
    onLogLine: @escaping (ProcessLogLine) -> Void
  ) async throws -> ProcessResult
}

public struct ProcessResult: Equatable {
  public let exitCode: Int32

  public init(exitCode: Int32) {
    self.exitCode = exitCode
  }

  public var succeeded: Bool {
    exitCode == 0
  }
}

public final class ExporterProcessRunner: ExporterProcessRunning {
  private let scriptPath: String

  public init(scriptPath: String = ScriptPathResolver().resolveScriptPath()) {
    self.scriptPath = scriptPath
  }

  public func run(
    options: ExportOptions,
    mode: ExportRunMode,
    onLogLine: @escaping (ProcessLogLine) -> Void
  ) async throws -> ProcessResult {
    try await withCheckedThrowingContinuation { continuation in
      let process = Process()
      process.executableURL = URL(fileURLWithPath: scriptPath)
      process.arguments = Array(options.arguments(mode: mode, scriptPath: scriptPath).dropFirst())

      let stdout = Pipe()
      let stderr = Pipe()
      process.standardOutput = stdout
      process.standardError = stderr

      let outputGroup = DispatchGroup()
      stream(pipe: stdout, stream: .stdout, group: outputGroup, onLogLine: onLogLine)
      stream(pipe: stderr, stream: .stderr, group: outputGroup, onLogLine: onLogLine)

      process.terminationHandler = { finishedProcess in
        outputGroup.notify(queue: .global()) {
          continuation.resume(returning: ProcessResult(exitCode: finishedProcess.terminationStatus))
        }
      }

      do {
        try process.run()
      } catch {
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        continuation.resume(throwing: error)
      }
    }
  }

  private func stream(
    pipe: Pipe,
    stream: ProcessLogStream,
    group: DispatchGroup,
    onLogLine: @escaping (ProcessLogLine) -> Void
  ) {
    group.enter()
    let reader = StreamingPipeReader(stream: stream, onLogLine: onLogLine) {
      group.leave()
    }
    pipe.fileHandleForReading.readabilityHandler = { handle in
      reader.consume(handle.availableData, from: handle)
    }
  }

}

private final class StreamingPipeReader {
  private let stream: ProcessLogStream
  private let onLogLine: (ProcessLogLine) -> Void
  private let onFinish: () -> Void
  private let lock = NSLock()
  private var pending = Data()
  private var finished = false

  init(
    stream: ProcessLogStream,
    onLogLine: @escaping (ProcessLogLine) -> Void,
    onFinish: @escaping () -> Void
  ) {
    self.stream = stream
    self.onLogLine = onLogLine
    self.onFinish = onFinish
  }

  func consume(_ data: Data, from handle: FileHandle) {
    lock.lock()
    if data.isEmpty {
      guard !finished else {
        lock.unlock()
        return
      }
      finished = true
      handle.readabilityHandler = nil
      let remaining = pending
      pending.removeAll()
      lock.unlock()
      emit(data: remaining)
      onFinish()
      return
    }

    pending.append(data)
    let lines = removeCompleteLines()
    lock.unlock()

    for line in lines {
      onLogLine(ProcessLogLine(stream: stream, text: line))
    }
  }

  private func removeCompleteLines() -> [String] {
    var lines: [String] = []

    while let newlineIndex = pending.firstIndex(of: 10) {
      let lineData = pending[..<newlineIndex]
      pending.removeSubrange(...newlineIndex)
      if let line = String(data: lineData, encoding: .utf8) {
        lines.append(line.trimmingCharacters(in: CharacterSet(charactersIn: "\r")))
      }
    }

    return lines
  }

  private func emit(data: Data) {
    guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else {
      return
    }
    onLogLine(ProcessLogLine(stream: stream, text: line.trimmingCharacters(in: .newlines)))
  }
}
