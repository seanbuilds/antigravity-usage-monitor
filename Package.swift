// swift-tools-version: 5.9
// Package.swift — Unified Native Shared Quota Suite
import PackageDescription

let package = Package(
    name: "SharedQuotaSuite",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AntigravityUsageApp", targets: ["AntigravityUsageApp"]),
        .executable(name: "GrokUsageApp", targets: ["GrokUsageApp"]),
        .library(name: "SharedQuotaKit", targets: ["SharedQuotaKit"]),
        .library(name: "AntigravityWidget", targets: ["AntigravityWidget"]),
        .library(name: "GrokWidget", targets: ["GrokWidget"]),
    ],
    targets: [
        // ── Core Shared Package ─────────────────────────────────────────────
        .target(
            name: "SharedQuotaKit",
            path: "Sources/SharedQuotaKit"
        ),

        // ── Antigravity Menu Bar App ────────────────────────────────────────
        .executableTarget(
            name: "AntigravityUsageApp",
            dependencies: ["SharedQuotaKit"],
            path: "Sources/AntigravityUsageApp"
        ),

        // ── Grok Menu Bar App ───────────────────────────────────────────────
        .executableTarget(
            name: "GrokUsageApp",
            dependencies: ["SharedQuotaKit"],
            path: "Sources/GrokUsageApp"
        ),

        // ── Native WidgetKit Extensions ─────────────────────────────────────
        .target(
            name: "AntigravityWidget",
            dependencies: ["SharedQuotaKit"],
            path: "Sources/AntigravityWidget"
        ),
        .target(
            name: "GrokWidget",
            dependencies: ["SharedQuotaKit"],
            path: "Sources/GrokWidget"
        )
    ]
)
