// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ios-tptweak",
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
            dependencies: ["TPTweak"]
        ),
    ]
)
