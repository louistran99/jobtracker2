// swift-tools-version: 6.2
import PackageDescription

let strictSettings: [SwiftSetting] = [
    .treatAllWarnings(as: .error)
]

let package = Package(
    name: "JobTrackerKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Storage", targets: ["Storage"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Features", targets: ["Features"]),
    ],
    targets: [
        // Pure business types and logic. Foundation only: no SwiftUI, no I/O.
        .target(name: "Domain", swiftSettings: strictSettings),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: strictSettings),

        // Persistence adapters behind `ApplicationRepository`.
        .target(name: "Storage", dependencies: ["Domain"], swiftSettings: strictSettings),
        .testTarget(name: "StorageTests", dependencies: ["Storage"], swiftSettings: strictSettings),

        // Reusable visual building blocks and tokens. No business logic.
        .target(name: "DesignSystem", dependencies: ["Domain"], swiftSettings: strictSettings),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"], swiftSettings: strictSettings),

        // Screens: SwiftUI views and their view models.
        .target(name: "Features", dependencies: ["Domain", "DesignSystem"], swiftSettings: strictSettings),
        .testTarget(name: "FeaturesTests", dependencies: ["Features"], swiftSettings: strictSettings),
    ],
    swiftLanguageModes: [.v6]
)
