// Sources/SharedQuotaKit/Models/QuotaModels.swift
import Foundation
import SwiftUI

public enum BrandIdentity: String, Codable, Sendable {
    case antigravity = "antigravity"
    case grok = "grok"

    public var displayName: String {
        switch self {
        case .antigravity: return "Antigravity Quota"
        case .grok: return "Grok Quota"
        }
    }

    public var statusSymbol: String {
        switch self {
        case .antigravity: return "✦"
        case .grok: return "⊘"
        }
    }

    public var defaultTier: String {
        switch self {
        case .antigravity: return "Google AI Ultra"
        case .grok: return "SuperGrok"
        }
    }

    public var accentColor: Color {
        switch self {
        case .antigravity: return Color(red: 0.23, green: 0.51, blue: 0.96) // #3B82F6
        case .grok: return Color(red: 0.90, green: 0.90, blue: 0.92)
        }
    }

    public var appGroupKey: String {
        switch self {
        case .antigravity: return "antigravity"
        case .grok: return "grok"
        }
    }
}

public struct RateLimitWindow: Codable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let iconName: String
    public let fraction: Double
    public let resetsInSeconds: Int?
    public let resetTime: String?

    public init(name: String, iconName: String, fraction: Double, resetsInSeconds: Int?, resetTime: String? = nil) {
        self.name = name
        self.iconName = iconName
        self.fraction = max(0.0, min(1.0, fraction))
        self.resetsInSeconds = resetsInSeconds
        self.resetTime = resetTime
    }

    public var percentage: Int {
        Int(round(fraction * 100))
    }
}

public struct ModelQuotaGroup: Codable, Sendable, Identifiable {
    public var id: String { title }
    public let title: String
    public let subtitle: String
    public let primaryLimit: RateLimitWindow
    public let secondaryLimit: RateLimitWindow

    public init(title: String, subtitle: String, primaryLimit: RateLimitWindow, secondaryLimit: RateLimitWindow) {
        self.title = title
        self.subtitle = subtitle
        self.primaryLimit = primaryLimit
        self.secondaryLimit = secondaryLimit
    }
}

public struct UnifiedQuotaSnapshot: Codable, Sendable {
    public let brand: BrandIdentity
    public let account: String
    public let tier: String
    public let tierId: String
    public let description: String
    public let groups: [ModelQuotaGroup]
    public let lastUpdated: Date

    public init(
        brand: BrandIdentity,
        account: String,
        tier: String,
        tierId: String,
        description: String,
        groups: [ModelQuotaGroup],
        lastUpdated: Date = Date()
    ) {
        self.brand = brand
        self.account = account
        self.tier = tier
        self.tierId = tierId
        self.description = description
        self.groups = groups
        self.lastUpdated = lastUpdated
    }

    public var menuBarTitle: String {
        let symbol = brand.statusSymbol
        if brand == .grok {
            if let g1 = groups.first?.primaryLimit {
                let t1 = formatShortTimer(seconds: g1.resetsInSeconds)
                let t1Part = t1.isEmpty ? "" : " (\(t1))"
                return "\(symbol) \(g1.percentage)%\(t1Part)"
            }
            return "\(symbol) 85%"
        } else {
            if groups.count >= 2 {
                let g1 = groups[0].primaryLimit
                let g2 = groups[1].primaryLimit
                let t1 = formatShortTimer(seconds: g1.resetsInSeconds)
                let t2 = formatShortTimer(seconds: g2.resetsInSeconds)
                let t1Part = t1.isEmpty ? "" : " (\(t1))"
                let t2Part = t2.isEmpty ? "" : " (\(t2))"

                return "\(symbol) G: \(g1.percentage)%\(t1Part) · C: \(g2.percentage)%\(t2Part)"
            } else if let g1 = groups.first?.primaryLimit {
                let t1 = formatShortTimer(seconds: g1.resetsInSeconds)
                let t1Part = t1.isEmpty ? "" : " (\(t1))"
                return "\(symbol) \(g1.percentage)%\(t1Part)"
            }
            return "\(symbol) 100%"
        }
    }
}

public func formatShortTimer(seconds: Int?) -> String {
    guard let s = seconds, s > 0 else { return "" }
    let days = s / 86400
    let hours = (s % 86400) / 3600
    let mins = (s % 3600) / 60
    if days > 0 { return "\(days)d \(hours)h" }
    if hours > 0 { return "\(hours)h \(mins)m" }
    return "\(mins)m"
}

public func formatRelativeTime(seconds: Int?) -> String {
    guard let s = seconds, s > 0 else { return "Ready" }
    if s < 60 { return "resets in \(s)s" }
    let days = s / 86400
    let hours = (s % 86400) / 3600
    let mins = (s % 3600) / 60
    var parts: [String] = []
    if days > 0 { parts.append("\(days)d") }
    if hours > 0 || days > 0 { parts.append("\(hours)h") }
    if mins > 0 || parts.isEmpty { parts.append("\(mins)m") }
    return "resets in " + parts.prefix(2).joined(separator: " ")
}

#if canImport(WidgetKit)
import WidgetKit

public struct QuotaWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: UnifiedQuotaSnapshot?

    public init(date: Date, snapshot: UnifiedQuotaSnapshot?) {
        self.date = date
        self.snapshot = snapshot
    }
}
#endif
