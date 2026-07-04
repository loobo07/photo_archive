import Foundation

public struct ProcessLogLine: Equatable, Identifiable {
  public let id: UUID
  public let timestamp: Date
  public let stream: ProcessLogStream
  public let text: String

  public init(
    id: UUID = UUID(),
    timestamp: Date = Date(),
    stream: ProcessLogStream,
    text: String
  ) {
    self.id = id
    self.timestamp = timestamp
    self.stream = stream
    self.text = text
  }
}

public enum ProcessLogStream: String, Equatable {
  case stdout
  case stderr
}
