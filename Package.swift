// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BTCPriceTracker",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "BTCPriceTracker",
            targets: ["BTCPriceTracker"]
        )
    ],
    dependencies: [
        // No external dependencies needed for this project
    ],
    targets: [
        .executableTarget(
            name: "BTCPriceTracker",
            dependencies: [],
            path: "BTCPriceTracker"
        )
    ]
)