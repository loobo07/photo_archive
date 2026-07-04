import Foundation

public struct ScriptPathResolver {
  private let fileManager: FileManager
  private let currentDirectoryPath: String

  public init(
    fileManager: FileManager = .default,
    currentDirectoryPath: String = FileManager.default.currentDirectoryPath
  ) {
    self.fileManager = fileManager
    self.currentDirectoryPath = currentDirectoryPath
  }

  public func resolveScriptPath() -> String {
    let developmentPath = URL(fileURLWithPath: currentDirectoryPath)
      .appendingPathComponent("scripts/export_photos_originals.zsh")
      .path

    if fileManager.fileExists(atPath: developmentPath) {
      return developmentPath
    }

    if let resourcePath = Bundle.main.path(forResource: "export_photos_originals", ofType: "zsh") {
      return resourcePath
    }

    return developmentPath
  }
}
