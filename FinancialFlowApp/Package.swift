// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FinancialFlowApp",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HomeFeature",
            targets: ["HomeFeature"]
        ),
        .library(
            name: "Models",
            targets: ["Models"]
        ),
        .library(
            name: "Utils",
            targets: ["Utils"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.17.1"
        ),
        .package(
            url: "https://github.com/groue/GRDB.swift",
            from: "7.2.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/sharing-grdb",
            from: "0.1.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HomeFeature",
            dependencies: [
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        
            .target(
                name: "Models",
                dependencies: [
                    "Utils",
                    .product(name: "SharingGRDB", package: "sharing-grdb"),
                ]
            ),
        
            .target(name: "Utils"),
        
            .testTarget(
                name: "HomeFeatureTests",
                dependencies: ["HomeFeature"]
            ),
    ]
)
