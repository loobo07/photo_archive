import Foundation

public struct ExportOptions: Equatable {
  public var libraryPath: String
  public var targetPath: String
  public var exportFolder: String
  public var layout: ExportLayout
  public var dateTarget: DateTarget
  public var minimumFreeGB: Int
  public var limit: Int?

  public init(
    libraryPath: String = "\(NSHomeDirectory())/Pictures/Photos Library.photoslibrary",
    targetPath: String = "",
    exportFolder: String = "Photos Originals Export",
    layout: ExportLayout = .yyyyMmDdType,
    dateTarget: DateTarget = .fullArchive,
    minimumFreeGB: Int = 250,
    limit: Int? = nil
  ) {
    self.libraryPath = libraryPath
    self.targetPath = targetPath
    self.exportFolder = exportFolder
    self.layout = layout
    self.dateTarget = dateTarget
    self.minimumFreeGB = minimumFreeGB
    self.limit = limit
  }

  public func arguments(mode: ExportRunMode, scriptPath: String = "scripts/export_photos_originals.zsh") -> [String] {
    var arguments = [
      scriptPath,
      "--target", targetPath,
      "--library", libraryPath,
      "--export-folder", exportFolder,
      "--layout", layout.rawValue,
      "--min-free-gb", String(minimumFreeGB)
    ]

    arguments.append(contentsOf: dateTarget.arguments)

    if let limit {
      arguments.append(contentsOf: ["--limit", String(limit)])
    }

    if mode == .dryRunOnly {
      arguments.append("--dry-run-only")
    }

    return arguments
  }
}

public enum ExportLayout: String, CaseIterable, Identifiable {
  case yyyyMmDdType = "yyyy-mm-dd-type"
  case typeYyMmDd = "type-yy-mm-dd"

  public var id: String {
    rawValue
  }
}

public enum DateTarget: Equatable {
  case fullArchive
  case hour(String)
  case day(String)
  case month(String)
  case range(from: String, to: String)

  public var arguments: [String] {
    switch self {
    case .fullArchive:
      return []
    case let .hour(value):
      return ["--hour", value]
    case let .day(value):
      return ["--day", value]
    case let .month(value):
      return ["--month", value]
    case let .range(from, to):
      return ["--from", from, "--to", to]
    }
  }
}

public enum ExportRunMode: Equatable {
  case dryRunOnly
  case export
}
