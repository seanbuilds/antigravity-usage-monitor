// swift-tools-version: 5.9
// Package.swift — antigravity-usage-monitor
// Supports macOS menu bar application, SharedModels, and WidgetKit extension
import PackageDescription

let package = Package(
    name: "AntigravityUsage",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AntigravityUsageApp", targets: ["AntigravityUsageApp"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
    ],
    targets: [
        // ── Main menu bar application ──────────────────────────────────────
        .executableTarget(
            name: "AntigravityUsageApp",
            dependencies: ["SharedModels"],
            path: "Sources/AntigravityUsageApp",
            resources: [
                .copy("Resources/index.html"),
                .copy("Resources/widget.html")
            ]
        ),

        // ── Shared data models (App Group UserDefaults) ────────────────────
        .target(
            name: "SharedModels",
            path: "SharedModels"
        ),

        // ── WidgetKit extension ────────────────────────────────────────────
        .target(
            name: "AntigravityWidget",
            dependencies: ["SharedModels"],
            path: "AntigravityWidget"
        )
    ]
)
