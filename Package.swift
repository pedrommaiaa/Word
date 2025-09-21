// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Word",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Word",
            targets: ["Word"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Word",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "WordTests",
            dependencies: ["Word"],
            path: "Tests"
        ),
    ]
)
