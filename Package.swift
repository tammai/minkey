// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Minkey",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MinkeyEngine", targets: ["MinkeyEngine"]),
        .executable(name: "Minkey", targets: ["Minkey"]),
    ],
    targets: [
        .target(name: "MinkeyEngine"),
        .executableTarget(
            name: "Minkey",
            dependencies: ["MinkeyEngine"],
            linkerSettings: [.linkedFramework("InputMethodKit")]
        ),
        .testTarget(name: "MinkeyEngineTests", dependencies: ["MinkeyEngine"]),
    ],
    swiftLanguageModes: [.v6]
)
