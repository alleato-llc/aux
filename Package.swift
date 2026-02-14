// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "aux",
    platforms: [.macOS("14.4")],
    dependencies: [
        .package(url: "git@github.com:aalleato/libav-kit.git", branch: "main"),
        .package(url: "git@github.com:aalleato/tint.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "aux",
            dependencies: [
                .product(name: "LibAVKit", package: "libav-kit"),
                .product(name: "Tint", package: "tint"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/aux"
        ),
    ]
)
