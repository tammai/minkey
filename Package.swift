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
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .target(name: "MinkeyEngine"),
        .target(name: "MinkeyKit", dependencies: ["MinkeyEngine"]),
        .executableTarget(
            name: "Minkey",
            dependencies: ["MinkeyEngine", "MinkeyKit", .product(name: "Sparkle", package: "Sparkle")],
            linkerSettings: [
                .linkedFramework("InputMethodKit"),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
        .testTarget(name: "MinkeyEngineTests", dependencies: ["MinkeyEngine"]),
        .testTarget(name: "MinkeyKitTests", dependencies: ["MinkeyKit"]),
    ],
    swiftLanguageModes: [.v6]
)
