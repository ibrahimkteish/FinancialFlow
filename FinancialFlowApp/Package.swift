// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FinancialFlowApp",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "AddDeviceFeature",
            targets: ["AddDeviceFeature"]
        ),
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
        .library(
            name: "AnalyticsFeature",
            targets: ["AnalyticsFeature"]
        ),
        .library(
            name: "CurrencyRatesFeature",
            targets: ["CurrencyRatesFeature"]
        ),
        .library(
            name: "SettingsFeature",
            targets: ["SettingsFeature"]
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
            name: "AddDeviceFeature",
            dependencies: [
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "AddDeviceFeature",
                "AnalyticsFeature",
                "CurrencyRatesFeature",
                "Models",
                "Utils",
                "SettingsFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .target(
            name: "AnalyticsFeature",
            dependencies: [
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ]
        ),
        .target(
            name: "CurrencyRatesFeature",
            dependencies: [
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ]
        ),
        .target(
            name: "SettingsFeature",
            dependencies: [
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
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
