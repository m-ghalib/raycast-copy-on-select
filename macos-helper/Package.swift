// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CopyOnSelect",
  platforms: [.macOS(.v13)],
  targets: [
    .target(name: "CopyOnSelectCore"),
    .executableTarget(name: "copyonselectd", dependencies: ["CopyOnSelectCore"]),
    .testTarget(name: "CopyOnSelectCoreTests", dependencies: ["CopyOnSelectCore"]),
  ]
)
