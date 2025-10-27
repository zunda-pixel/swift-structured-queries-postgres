// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

let package = Package(
    name: "swift-structured-queries-postgres",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(
            name: "StructuredQueriesCore",
            targets: ["StructuredQueriesCore"]
        ),
        .library(
            name: "StructuredQueriesPostgres",
            targets: ["StructuredQueriesPostgres"]
        ),
        .library(
            name: "StructuredQueriesPostgresTestSupport",
            targets: ["StructuredQueriesPostgresTestSupport"]
        ),
        .library(
            name: "StructuredQueriesPostgresSupport",
            targets: ["StructuredQueriesPostgresSupport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.7.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.8.1"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.3"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.4"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", exact: "1.6.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
        .package(url: "https://github.com/vapor/postgres-nio", from: "1.22.0"),
    ],
    targets: [
        .target(
            name: "StructuredQueriesCore",
            dependencies: [
                .target(name: "StructuredQueriesPostgresSupport"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "Tagged", package: "swift-tagged"),
            ],
            exclude: ["Symbolic Links/README.md"]
        ),
        .target(
            name: "StructuredQueriesPostgres",
            dependencies: [
                .target(name: "StructuredQueriesCore"),
                .target(name: "StructuredQueriesPostgresMacros"),
            ],
            exclude: ["Functions/Aggregate/_COVERAGE.md"]
        ),
        .macro(
            name: "StructuredQueriesPostgresMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            exclude: ["Symbolic Links/README.md"]
        ),
        .target(
            name: "StructuredQueriesPostgresTestSupport",
            dependencies: [
                .target(name: "StructuredQueriesCore"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ]
        ),
        .target(
            name: "StructuredQueriesPostgresSupport"
        ),
        .testTarget(
            name: "StructuredQueriesPostgresMacrosTests",
            dependencies: [
                .target(name: "StructuredQueriesPostgres"),
                .target(name: "StructuredQueriesPostgresMacros"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "StructuredQueriesPostgresTests",
            dependencies: [
                .target(name: "StructuredQueriesPostgres"),
                .target(name: "StructuredQueriesPostgresTestSupport"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["StructuredQueriesPostgres.xctestplan"]
        ),
        .testTarget(
            name: "READMEExamplesTests",
            dependencies: [
                .target(name: "StructuredQueriesPostgres"),
                .target(name: "StructuredQueriesPostgresTestSupport"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ],
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility")
]

for index in package.targets.indices {
    package.targets[index].swiftSettings = swiftSettings
}
