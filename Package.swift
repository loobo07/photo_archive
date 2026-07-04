// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "PhotoArchive",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "PhotoArchiveCore",
      targets: ["PhotoArchiveCore"]
    ),
    .executable(
      name: "PhotoArchiveApp",
      targets: ["PhotoArchiveApp"]
    ),
    .executable(
      name: "PhotoArchiveCoreTestRunner",
      targets: ["PhotoArchiveCoreTestRunner"]
    )
  ],
  targets: [
    .target(
      name: "PhotoArchiveCore",
      path: "Sources/PhotoArchiveCore"
    ),
    .executableTarget(
      name: "PhotoArchiveApp",
      dependencies: ["PhotoArchiveCore"],
      path: "Sources/PhotoArchiveApp"
    ),
    .executableTarget(
      name: "PhotoArchiveCoreTestRunner",
      dependencies: ["PhotoArchiveCore"],
      path: "PhotoArchiveAppTests"
    )
  ]
)
