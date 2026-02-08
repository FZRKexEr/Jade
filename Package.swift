// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChineseChess",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ChineseChessKit",
            targets: ["ChineseChessKit"]
        ),
        .library(
            name: "Engine",
            targets: ["Engine"]
        ),
        .executable(
            name: "ChineseChess",
            targets: ["ChineseChess"]
        )
    ],
    dependencies: [
        // Add swift-testing for modern testing
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.3.0"),
    ],
    targets: [
        // Core domain models
        .target(
            name: "Domain",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Core game logic
        .target(
            name: "Game",
            dependencies: ["Domain"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Core game logic (placeholder)
        .target(
            name: "ChineseChessKit",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Engine/UCI protocol layer
        .target(
            name: "Engine",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Configuration module
        .target(
            name: "Configuration",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Presentation module
        .target(
            name: "Presentation",
            dependencies: [
                "Domain",
                "Game",
                "Configuration"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Main application
        .executableTarget(
            name: "ChineseChess",
            dependencies: [
                "ChineseChessKit",
                "Engine",
                "Domain",
                "Game",
                "Configuration",
                "Presentation"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),

        // Tests
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "ChineseChessKit",
                .product(name: "Testing", package: "swift-testing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "GameTests",
            dependencies: [
                "ChineseChessKit",
                .product(name: "Testing", package: "swift-testing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EngineTests",
            dependencies: [
                "Engine",
                .product(name: "Testing", package: "swift-testing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ConfigurationTests",
            dependencies: [
                "ChineseChessKit",
                .product(name: "Testing", package: "swift-testing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "ChineseChessKit",
                "Engine",
                .product(name: "Testing", package: "swift-testing"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
