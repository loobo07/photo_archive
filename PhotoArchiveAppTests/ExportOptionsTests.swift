import Foundation
import PhotoArchiveCore

@main
struct PhotoArchiveCoreTestRunner {
  static func main() async throws {
    try dryRunArgumentsPreservePathsWithSpacesAndIncludeDryRunOnly()
    try dateTargetArgumentsAreExplicitForEachMode()
    try realExportArgumentsDoNotIncludeDryRunOnly()
    try await runExporterProcessRunnerTests()
    try await runArchiveSessionStoreTests()
    print("PhotoArchiveCore tests passed")
  }

  static func dryRunArgumentsPreservePathsWithSpacesAndIncludeDryRunOnly() throws {
    let options = ExportOptions(
      libraryPath: "/Users/example/Pictures/Photos Library.photoslibrary",
      targetPath: "/Volumes/My Photos",
      exportFolder: "Archive Export",
      layout: .yyyyMmDdType,
      dateTarget: .fullArchive,
      minimumFreeGB: 250,
      limit: 10
    )

    let arguments = options.arguments(mode: .dryRunOnly)

    try expect(arguments.first == "scripts/export_photos_originals.zsh", "first argument is the script path")
    try expect(arguments.argument(after: "--library") == "/Users/example/Pictures/Photos Library.photoslibrary", "library path with spaces is preserved")
    try expect(arguments.argument(after: "--target") == "/Volumes/My Photos", "target path with spaces is preserved")
    try expect(arguments.argument(after: "--export-folder") == "Archive Export", "export folder with spaces is preserved")
    try expect(arguments.argument(after: "--layout") == "yyyy-mm-dd-type", "layout argument is included")
    try expect(arguments.argument(after: "--min-free-gb") == "250", "minimum free GB is included")
    try expect(arguments.argument(after: "--limit") == "10", "limit is included")
    try expect(arguments.contains("--dry-run-only"), "dry-run-only mode includes the dry-run flag")
  }

  static func dateTargetArgumentsAreExplicitForEachMode() throws {
    try expect(ExportOptions(dateTarget: .hour("2024-07-19T14")).arguments(mode: .export).containsSequence(["--hour", "2024-07-19T14"]), "hour target is represented explicitly")
    try expect(ExportOptions(dateTarget: .day("2024-07-19")).arguments(mode: .export).containsSequence(["--day", "2024-07-19"]), "day target is represented explicitly")
    try expect(ExportOptions(dateTarget: .month("2024-07")).arguments(mode: .export).containsSequence(["--month", "2024-07"]), "month target is represented explicitly")
    try expect(ExportOptions(dateTarget: .range(from: "2024-07-01", to: "2024-07-31")).arguments(mode: .export).containsSequence(["--from", "2024-07-01", "--to", "2024-07-31"]), "range target is represented explicitly")
  }

  static func realExportArgumentsDoNotIncludeDryRunOnly() throws {
    let arguments = ExportOptions().arguments(mode: .export)

    try expect(!arguments.contains("--dry-run-only"), "real export does not include dry-run-only")
  }

  static func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
      throw TestFailure(message)
    }
  }
}

struct TestFailure: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

private extension ExportOptions {
  init(dateTarget: DateTarget) {
    self.init(
      libraryPath: "/Users/example/Pictures/Photos Library.photoslibrary",
      targetPath: "/Volumes/PhotoDrive",
      exportFolder: "Photos Originals Export",
      layout: .yyyyMmDdType,
      dateTarget: dateTarget,
      minimumFreeGB: 250,
      limit: nil
    )
  }
}

private extension Array where Element == String {
  func argument(after option: String) -> String? {
    guard let index = firstIndex(of: option) else {
      return nil
    }
    let valueIndex = self.index(after: index)
    guard valueIndex < endIndex else {
      return nil
    }
    return self[valueIndex]
  }

  func containsSequence(_ expected: [String]) -> Bool {
    guard expected.count <= count else {
      return false
    }

    return indices.contains { start in
      let end = index(start, offsetBy: expected.count, limitedBy: endIndex)
      guard let end else {
        return false
      }
      return Array(self[start..<end]) == expected
    }
  }
}
