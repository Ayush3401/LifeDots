// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LifeDots",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "LifeDots", path: "Sources/LifeDots")
    ]
)
