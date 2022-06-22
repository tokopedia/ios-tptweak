// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ios-tptweak",
    platforms: [.iOS(.v10)],
    products: [
        .library(
            name: "TPTweak",
            targets: ["TPTweak"]),
    ],
    targets: [
        .target(
            name: "TPTweak",
            dependencies: []
        ),
        .testTarget(
            name: "TPTweakTests",
            dependencies: ["TPTweak"]),
    ]
)
