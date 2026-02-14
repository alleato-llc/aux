// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "aux",
    platforms: [.macOS("14.4")],
    dependencies: [
        .package(url: "git@github.com:alleato-llc/libav-kit.git", branch: "main"),
        .package(url: "git@github.com:alleato-llc/tint.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/alleato-llc/pickle-kit.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "AuxLib",
            dependencies: [
                .product(name: "LibAVKit", package: "libav-kit"),
                .product(name: "Tint", package: "tint"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/AuxLib"
        ),
        .executableTarget(
            name: "aux",
            dependencies: [
                "AuxLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/AuxCLI"
        ),
        .testTarget(
            name: "auxTests",
            dependencies: [
                "AuxLib",
                .product(name: "LibAVKit", package: "libav-kit"),
                .product(name: "PickleKit", package: "pickle-kit"),
            ]
        ),
    ]
)
