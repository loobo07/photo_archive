import Foundation
import Observation

@MainActor
@Observable
public final class ArchiveSessionStore {
  public private(set) var options: ExportOptions
  public private(set) var phase: ExportPhase
  public private(set) var logs: [ProcessLogLine]
  public private(set) var canExport: Bool

  private let runner: ExporterProcessRunning

  public init(
    options: ExportOptions = ExportOptions(),
    phase: ExportPhase = .editingOptions,
    logs: [ProcessLogLine] = [],
    canExport: Bool = false,
    runner: ExporterProcessRunning = ExporterProcessRunner()
  ) {
    self.options = options
    self.phase = phase
    self.logs = logs
    self.canExport = canExport
    self.runner = runner
  }

  public func updateOptions(_ options: ExportOptions) {
    guard !phase.isRunning else {
      return
    }

    self.options = options
    phase = .editingOptions
    canExport = false
  }

  public func startDryRun() async {
    guard !phase.isRunning else {
      return
    }

    phase = .dryRunRunning
    canExport = false

    do {
      let result = try await runner.run(options: options, mode: .dryRunOnly) { [weak self] line in
        Task { @MainActor in
          self?.appendLogLine(line)
        }
      }

      if result.succeeded {
        phase = .dryRunSucceeded
        canExport = true
      } else {
        phase = .failed("Dry run failed with exit code \(result.exitCode)")
        canExport = false
      }
    } catch {
      phase = .failed("Dry run failed: \(error.localizedDescription)")
      canExport = false
    }
  }

  public func startExport() async {
    guard canExport, !phase.isRunning else {
      return
    }

    phase = .exportRunning
    canExport = false

    do {
      let result = try await runner.run(options: options, mode: .export) { [weak self] line in
        Task { @MainActor in
          self?.appendLogLine(line)
        }
      }

      if result.succeeded {
        phase = .exportSucceeded
      } else {
        phase = .failed("Export failed with exit code \(result.exitCode)")
      }
    } catch {
      phase = .failed("Export failed: \(error.localizedDescription)")
    }
  }

  public func clearLogs() {
    logs.removeAll()
  }

  public func appendLogLine(_ line: ProcessLogLine) {
    logs.append(line)
  }
}
