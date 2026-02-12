// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "sigilcli",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "sigil", targets: ["sigil"]),
        .library(name: "SigilCore", targets: ["SigilCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "sigil",
            dependencies: [
                "SigilCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "SigilCore",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
        .testTarget(
            name: "SigilCoreTests",
            dependencies: ["SigilCore"]
        ),
    ]
)
