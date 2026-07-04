import Foundation

public enum ExportPhase: Equatable {
  case editingOptions
  case dryRunRunning
  case dryRunSucceeded
  case exportRunning
  case exportSucceeded
  case failed(String)

  public var isRunning: Bool {
    switch self {
    case .dryRunRunning, .exportRunning:
      return true
    case .editingOptions, .dryRunSucceeded, .exportSucceeded, .failed:
      return false
    }
  }
}
