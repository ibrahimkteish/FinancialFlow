// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceValueApp",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "AddDeviceFeature",
            targets: ["AddDeviceFeature"]
        ),
        .library(
          name: "BuildClient",
          targets: ["BuildClient"]
        ),
        .library(
            name: "Generated",
            targets: ["Generated"]
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
            name: "CurrenciesRatesFeature",
            targets: ["CurrenciesRatesFeature"]
        ),
        .library(
            name: "SettingsFeature",
            targets: ["SettingsFeature"]
        ),
        .library(
            name: "UIApplicationClient",
            targets: ["UIApplicationClient"]
        ),

        .plugin(name: "SwiftFormat", targets: ["SwiftFormat"]),
        .plugin(name: "SwiftGenGenerate", targets: ["SwiftGenGenerate"]),

    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.17.1"
        ),
        .package(
          url: "https://github.com/pointfreeco/swift-dependencies",
          from: "1.7.0"
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
                "Generated",
                "Models",
                "Utils",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ]
        ),
        .target(name:"BuildClient", dependencies: [
          .product(name: "Dependencies", package: "swift-dependencies"),
          .product(name: "DependenciesMacros", package: "swift-dependencies"),
        ]),
        .target(
            name: "Generated",
            dependencies: [
                "Models",
                "Utils",
            ]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "AddDeviceFeature",
                "AnalyticsFeature",
                "CurrenciesRatesFeature",
                "Generated",
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
            name: "CurrenciesRatesFeature",
            dependencies: [
                "Generated",
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

        .target(
            name: "SettingsFeature",
            dependencies: [
                "BuildClient",
                "Generated",
                "Models",
                "Utils",
                "UIApplicationClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SharingGRDB", package: "sharing-grdb"),
            ]
        ),
        
        
        .testTarget(
            name: "HomeFeatureTests",
            dependencies: ["HomeFeature"]
        ),

        .target(
            name: "UIApplicationClient",
            dependencies: [
              .product(name: "Dependencies", package: "swift-dependencies"),
              .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(name: "Utils"),

          .binaryTarget(
            name: "swiftgen",
            url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.3/swiftgen-6.6.3.artifactbundle.zip",
            checksum: "caf1feaf93dd32bc5037f0b6ded8d0f4fe28ab5d2f6e5c3edf2572006ba0b7eb"
          ),

          .plugin(
            name: "SwiftGenGenerate",
            capability: .command(
              intent: .custom(
                verb: "generate-code-for-resources",
                description: "Creates type-safe for all your resources"
              ),
              permissions: [
                .writeToPackageDirectory(reason: "This command generates source code")
              ]
            ),
            dependencies: ["swiftgen"]
          ),

          .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.49.16/swiftformat.artifactbundle.zip",
            checksum: "b935247c918d0f45ee35e4e42e840fc55cd2461d0db2673b26d47c03a0ffd3f6"
          ),

          .plugin(
            name: "SwiftFormat",
            capability: .command(
              intent: .sourceCodeFormatting(),
              permissions: [
                .writeToPackageDirectory(reason: "This command reformats source files"),
              ]),
            dependencies: [.target(name: "swiftformat")]
          ),

    ]
)
