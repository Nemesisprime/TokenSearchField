// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TokenSearchField",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "TokenSearchField",
            targets: ["TokenSearchField"])
    ],
    targets: [
        .target(name: "TokenSearchField")
    ]
)
