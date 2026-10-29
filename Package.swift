// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Minkey",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MinkeyEngine", targets: ["MinkeyEngine"]),
        .library(name: "MinkeyKit", targets: ["MinkeyKit"]),
        .executable(name: "Minkey", targets: ["Minkey"]),
    ],
    targets: [
        .target(name: "MinkeyEngine"),
        .target(name: "MinkeyKit", dependencies: ["MinkeyEngine"]),
        .executableTarget(
            name: "Minkey",
            dependencies: ["MinkeyEngine", "MinkeyKit"],
            linkerSettings: [.linkedFramework("InputMethodKit")]
        ),
        .testTarget(name: "MinkeyEngineTests", dependencies: ["MinkeyEngine"]),
        .testTarget(name: "MinkeyKitTests", dependencies: ["MinkeyKit"]),
    ],
    swiftLanguageModes: [.v6]
)
