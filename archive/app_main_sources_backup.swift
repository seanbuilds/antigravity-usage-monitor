// v12 – 100% Pure Native SwiftUI & AppKit macOS Menu Bar Application
//       Multi-Monitor Popover Anchor & Secondary Display Coordinate Geometry Fix,
//       Live 1-Second Decrement Countdown Timer in Menu Bar Title and
//       High-Contrast Electric-Blue Pill Badges on All Rate-Limit Cards.
import Cocoa
import SwiftUI
import WidgetKit
import SharedModels

// MARK: - Data Models

public struct QuotaBucket: Codable, Identifiable, Sendable {
    public var id: String { bucketId ?? displayName ?? UUID().uuidString }
    public let bucketId: String?
    public let displayName: String?
    public let label: String?
    public let kind: String?
    public let window: String?
    public let remainingFraction: Double?
    public let resetsInSeconds: Int?
    public let resetTime: String?
    public let resetAt: String?
    public let description: String?
}

public struct QuotaGroup: Codable, Identifiable, Sendable {
    public var id: String { displayName ?? name ?? UUID().uuidString }
    public let displayName: String?
    public let name: String?
    public let description: String?
    public let models: String?
    public let buckets: [QuotaBucket]?
}

public struct QuotaData: Codable, Sendable {
    public let account: String?
    public let tier: String?
    public let tierId: String?
    public let tierDescription: String?
    public let host: String?
    public let fetchedAt: String?
    public let source: String?
    public let credentialSource: String?
    public let localIp: String?
    public let port: Int?
    public let remoteCommand: String?
    public let description: String?
    public let groups: [QuotaGroup]?
}

public struct QuotaBreakdown: Sendable {
    public var gemini5hFraction: Double?
    public var gemini5hResetsIn: Int?
    public var gemini5hResetDate: Date?
    public var geminiWeeklyFraction: Double?
    public var geminiWeeklyResetsIn: Int?
    public var geminiWeeklyResetDate: Date?

    public var claude5hFraction: Double?
    public var claude5hResetsIn: Int?
    public var claude5hResetDate: Date?
    public var claudeWeeklyFraction: Double?
    public var claudeWeeklyResetsIn: Int?
    public var claudeWeeklyResetDate: Date?

    public init() {}
}

// MARK: - Formatters & Helpers

func parseResetTargetDate(resetsInSeconds: Int?, resetTime: String?, resetAt: String?) -> (Int?, Date?) {
    let rawTime = (resetTime?.isEmpty == false) ? resetTime : resetAt
    if let timeStr = rawTime, !timeStr.isEmpty {
        let isoWithFrac = ISO8601DateFormatter()
        isoWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoWithFrac.date(from: timeStr) {
            let diff = max(0, Int(d.timeIntervalSinceNow))
            return (diff, d)
        }
        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        if let d = isoStandard.date(from: timeStr) {
            let diff = max(0, Int(d.timeIntervalSinceNow))
            return (diff, d)
        }
    }
    if let s = resetsInSeconds, s > 0 {
        let d = Date().addingTimeInterval(Double(s))
        return (s, d)
    }
    return (nil, nil)
}

func formatRelativeTime(seconds: Int?) -> String {
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

func formatShortTimer(seconds: Int?) -> String {
    guard let s = seconds, s > 0 else { return "" }
    let days = s / 86400
    let hours = (s % 86400) / 3600
    let mins = (s % 3600) / 60
    if days > 0 { return "\(days)d \(hours)h" }
    if hours > 0 { return "\(hours)h \(mins)m" }
    if mins > 0 { return "\(mins)m" }
    return "\(s)s"
}

func extractBreakdown(from quota: QuotaData?) -> QuotaBreakdown {
    var b = QuotaBreakdown()
    guard let quota = quota else { return b }

    for grp in quota.groups ?? [] {
        let name = (grp.displayName ?? grp.name ?? "").lowercased()
        let isGemini = name.contains("gemini")

        for bucket in grp.buckets ?? [] {
            let bId = (bucket.bucketId ?? bucket.displayName ?? bucket.window ?? "").lowercased()
            let frac = bucket.remainingFraction
            let (secs, targetDate) = parseResetTargetDate(
                resetsInSeconds: bucket.resetsInSeconds,
                resetTime: bucket.resetTime,
                resetAt: bucket.resetAt
            )
            let is5h = bId.contains("5h") || bId.contains("five hour") || bucket.window == "5h"
            let isWeekly = bId.contains("week") || bucket.window == "weekly"

            if isGemini {
                if is5h {
                    b.gemini5hFraction = frac
                    b.gemini5hResetsIn = secs
                    b.gemini5hResetDate = targetDate
                } else if isWeekly {
                    b.geminiWeeklyFraction = frac
                    b.geminiWeeklyResetsIn = secs
                    b.geminiWeeklyResetDate = targetDate
                }
            } else {
                if is5h {
                    b.claude5hFraction = frac
                    b.claude5hResetsIn = secs
                    b.claude5hResetDate = targetDate
                } else if isWeekly {
                    b.claudeWeeklyFraction = frac
                    b.claudeWeeklyResetsIn = secs
                    b.claudeWeeklyResetDate = targetDate
                }
            }
        }
    }
    return b
}

public enum ScreenMode: Hashable {
    case dashboard
    case setup
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var quota: QuotaData?
    @Published var breakdown: QuotaBreakdown = QuotaBreakdown()
    @Published var isLoading: Bool = false
    @Published var isOffline: Bool = false
    @Published var errorMessage: String?
    @Published var currentScreen: ScreenMode = .dashboard
    @Published var isUnsnapped: Bool = false
    @Published var isWidgetVisible: Bool = false
    @Published var isWidgetHovering: Bool = false
    @Published var isManualRefreshing: Bool = false
    @Published var refreshRotation: Double = 0
    @Published var copiedRemoteCommand: Bool = false

    var onToggleUnsnap: (() -> Void)?
    var onToggleWidget: (() -> Void)?
    var onCloseWidget: (() -> Void)?
    var onOpenFullApp: (() -> Void)?
    var onUpdateStatusTitle: ((String, String) -> Void)?

    private var countdownTimer: Timer?

    func startCountdownTimer() {
        guard countdownTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickCountdown()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }

    func tickCountdown() {
        guard quota != nil, !isOffline else { return }

        var changed = false

        if let d = breakdown.gemini5hResetDate {
            let s = max(0, Int(d.timeIntervalSinceNow))
            if s != breakdown.gemini5hResetsIn {
                breakdown.gemini5hResetsIn = s
                changed = true
            }
        }
        if let d = breakdown.geminiWeeklyResetDate {
            let s = max(0, Int(d.timeIntervalSinceNow))
            if s != breakdown.geminiWeeklyResetsIn {
                breakdown.geminiWeeklyResetsIn = s
                changed = true
            }
        }
        if let d = breakdown.claude5hResetDate {
            let s = max(0, Int(d.timeIntervalSinceNow))
            if s != breakdown.claude5hResetsIn {
                breakdown.claude5hResetsIn = s
                changed = true
            }
        }
        if let d = breakdown.claudeWeeklyResetDate {
            let s = max(0, Int(d.timeIntervalSinceNow))
            if s != breakdown.claudeWeeklyResetsIn {
                breakdown.claudeWeeklyResetsIn = s
                changed = true
            }
        }

        if changed {
            updateStatusTitle()
        }

        // Auto-refresh from daemon if any active limit countdown reaches zero
        let gHitZero = (breakdown.gemini5hResetsIn == 0 && (breakdown.gemini5hFraction ?? 1.0) < 1.0)
        let cHitZero = (breakdown.claude5hResetsIn == 0 && (breakdown.claude5hFraction ?? 1.0) < 1.0)
        if gHitZero || cHitZero {
            if !isLoading && !isManualRefreshing {
                fetchQuota(force: true)
            }
        }
    }

    func fetchQuota(force: Bool = false) {
        isLoading = true
        let urlStr = force ? "http://127.0.0.1:3007/quota?refresh=1" : "http://127.0.0.1:3007/quota"
        guard let url = URL(string: urlStr) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(QuotaData.self, from: data)
                self.quota = decoded
                self.breakdown = extractBreakdown(from: decoded)
                self.isOffline = false
                self.errorMessage = nil
                self.isLoading = false
                self.syncToAppGroup(decoded)
                self.updateStatusTitle()
            } catch {
                self.isOffline = true
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.onUpdateStatusTitle?("✦ offline", "Antigravity Quota: Daemon offline (retrying...)")
            }
        }
    }

    func triggerManualRefresh() {
        guard !isManualRefreshing else { return }
        isManualRefreshing = true
        withAnimation(.easeInOut(duration: 0.6)) {
            refreshRotation += 360
        }
        fetchQuota(force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            self?.isManualRefreshing = false
        }
    }

    func updateStatusTitle() {
        guard let quota = self.quota else {
            onUpdateStatusTitle?("✦ G: --% · C: --%", "Antigravity Quota (Click to open dashboard)")
            return
        }
        let b = self.breakdown
        let g5hPct = Int(round((b.gemini5hFraction ?? 1.0) * 100))
        let c5hPct = Int(round((b.claude5hFraction ?? 1.0) * 100))
        let gWkPct = Int(round((b.geminiWeeklyFraction ?? 1.0) * 100))
        let cWkPct = Int(round((b.claudeWeeklyFraction ?? 1.0) * 100))

        let gTimer = formatShortTimer(seconds: b.gemini5hResetsIn)
        let cTimer = formatShortTimer(seconds: b.claude5hResetsIn)
        let gTimerPart = gTimer.isEmpty ? "" : " (\(gTimer))"
        let cTimerPart = cTimer.isEmpty ? "" : " (\(cTimer))"

        // Display both models and their live countdown timers directly in Menu Bar
        let title = "✦ G: \(g5hPct)%\(gTimerPart) · C: \(c5hPct)%\(cTimerPart)"

        let g5hTime = formatRelativeTime(seconds: b.gemini5hResetsIn)
        let gWkTime = formatRelativeTime(seconds: b.geminiWeeklyResetsIn)
        let c5hTime = formatRelativeTime(seconds: b.claude5hResetsIn)
        let cWkTime = formatRelativeTime(seconds: b.claudeWeeklyResetsIn)

        let tooltip = """
        Antigravity Quotas (\(quota.tier ?? "Google AI Ultra")):
        • Gemini 5-Hour: \(g5hPct)% (\(g5hTime))
        • Gemini Weekly: \(gWkPct)% (\(gWkTime))
        • Claude/GPT 5-Hour: \(c5hPct)% (\(c5hTime))
        • Claude/GPT Weekly: \(cWkPct)% (\(cWkTime))
        (Click to open dashboard)
        """
        onUpdateStatusTitle?(title, tooltip)
    }

    func syncToAppGroup(_ quota: QuotaData) {
        let b = extractBreakdown(from: quota)
        let minPct = Int(round(min(b.gemini5hFraction ?? 1.0, b.claude5hFraction ?? 1.0) * 100))
        if let defaults = UserDefaults(suiteName: "group.com.dad.aiusage") {
            defaults.set(minPct, forKey: "antigravity.quotaPercent")
            defaults.set(Date(), forKey: "antigravity.lastUpdated")
            defaults.set(quota.tier ?? "Google AI Ultra", forKey: "antigravity.tier")
            defaults.set(quota.account ?? "Active Account", forKey: "antigravity.account")
            WidgetCenter.shared.reloadTimelines(ofKind: "AntigravityUsageWidget")
        }
    }

    func copyRemoteCommand() {
        let cmd = quota?.remoteCommand ?? "curl -s http://127.0.0.1:3007"
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(cmd, forType: .string)
        copiedRemoteCommand = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.copiedRemoteCommand = false
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Native SwiftUI UI Components

struct CustomProgressBar: View {
    let fraction: Double
    var height: CGFloat = 5

    var color: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) } // red
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) } // yellow
        return Color(red: 0.19, green: 0.82, blue: 0.35) // green
    }

    var gradient: LinearGradient {
        if fraction < 0.20 {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.35, blue: 0.28), Color(red: 0.95, green: 0.16, blue: 0.16)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if fraction < 0.50 {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.88, blue: 0.20), Color(red: 0.98, green: 0.70, blue: 0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.90, blue: 0.50), Color(red: 0.12, green: 0.78, blue: 0.35)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(fraction))))
                    .shadow(color: color.opacity(0.30), radius: 3, x: 0, y: 1)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: fraction)
            }
        }
        .frame(height: height)
    }
}

struct HeaderView: View {
    @ObservedObject var appState: AppState

    var tierText: String {
        let t = appState.quota?.tier ?? "Ultra"
        return t.lowercased().contains("ultra") ? "Ultra" : t
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center, spacing: 8) {
                // 22x22pt brand logo box with subtle glow
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.04, green: 0.05, blue: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.45), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.25), radius: 4, x: 0, y: 1)

                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.04, green: 0.52, blue: 1.0))
                }
                .frame(width: 22, height: 22)

                // Title
                Text("Antigravity")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                // Tier Pill
                Text(tierText.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 1)
                            )
                    )

                Spacer()

                // 4-Icon Toolbar
                HStack(spacing: 5) {
                    // 1. Desktop Widget
                    Button {
                        appState.onToggleWidget?()
                    } label: {
                        Image(systemName: appState.isWidgetVisible ? "rectangle.fill.on.rectangle.fill" : "rectangle.on.rectangle")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(appState.isWidgetVisible ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color.white.opacity(0.65))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(appState.isWidgetVisible ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(appState.isWidgetVisible ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.4) : Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.isWidgetVisible ? "Hide Desktop Widget (⌘W)" : "Add Desktop Widget (⌘W)")

                    // 2. Setup & Diagnostics
                    Button {
                        withAnimation {
                            appState.currentScreen = (appState.currentScreen == .dashboard) ? .setup : .dashboard
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(appState.currentScreen == .setup ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color.white.opacity(0.65))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(appState.currentScreen == .setup ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(appState.currentScreen == .setup ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.4) : Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Settings & Server Diagnostics")

                    // 3. Unsnap / Snap
                    Button {
                        appState.onToggleUnsnap?()
                    } label: {
                        Image(systemName: appState.isUnsnapped ? "arrow.down.left.square" : "arrow.up.right.square")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(appState.isUnsnapped ? Color(red: 0.04, green: 0.52, blue: 1.0) : Color.white.opacity(0.65))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(appState.isUnsnapped ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.2) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(appState.isUnsnapped ? Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.4) : Color.white.opacity(0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.isUnsnapped ? "Snap back to Menu Bar (⌘U)" : "Unsnap to Floating Window (⌘U)")

                    // 4. Refresh
                    Button {
                        appState.triggerManualRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(appState.isManualRefreshing ? 1.0 : 0.65))
                            .rotationEffect(.degrees(appState.refreshRotation))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.white.opacity(appState.isManualRefreshing ? 0.14 : 0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(Color.white.opacity(appState.isManualRefreshing ? 0.20 : 0.09), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.isManualRefreshing)
                    .help("Refresh Quota (⌘R)")
                }
            }

            // Account Subhead directly under brand
            if let account = appState.quota?.account {
                Text(account)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.60))
                    .lineLimit(1)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 10)
    }
}

struct RateLimitBoxView: View {
    let windowTitle: String
    let fraction: Double
    let resetSeconds: Int?
    let iconName: String

    var pctText: String {
        "\(Int(round(fraction * 100)))%"
    }

    var color: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    var badgeText: String {
        guard let s = resetSeconds, s > 0 else {
            return fraction >= 0.999 ? "Ready" : "Refreshing..."
        }
        return formatRelativeTime(seconds: s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: iconName)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.white.opacity(0.60))
                    Text(windowTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()

                HStack(spacing: 6) {
                    // High-Contrast Electric-Blue Pill Badge [resets in 15m]
                    Text(badgeText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.0, green: 0.92, blue: 1.0)) // #00EBFF Electric Cyan/Blue
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.0, green: 0.45, blue: 1.0).opacity(0.24))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 0.0, green: 0.88, blue: 1.0).opacity(0.60), lineWidth: 1.0)
                                )
                        )
                        .shadow(color: Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.30), radius: 3, x: 0, y: 0)

                    Text(pctText)
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                }
            }

            CustomProgressBar(fraction: fraction, height: 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

struct ModelGroupSection: View {
    let title: String
    let subtitle: String
    let fiveHourFraction: Double
    let fiveHourReset: Int?
    let weeklyFraction: Double
    let weeklyReset: Int?
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(subtitle)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.50))
                    .lineLimit(1)
            }

            // Dual Rate Limits for this Group
            VStack(spacing: 6) {
                RateLimitBoxView(
                    windowTitle: "5-Hour Rolling Limit",
                    fraction: fiveHourFraction,
                    resetSeconds: fiveHourReset,
                    iconName: "clock.arrow.circlepath"
                )

                RateLimitBoxView(
                    windowTitle: "Weekly Plan Quota",
                    fraction: weeklyFraction,
                    resetSeconds: weeklyReset,
                    iconName: "calendar"
                )
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct RemoteDeviceBar: View {
    @ObservedObject var appState: AppState

    var cmd: String {
        appState.quota?.remoteCommand ?? "curl -s http://127.0.0.1:3007"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))

            Text(cmd)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.60))
                .lineLimit(1)

            Spacer()

            Button {
                appState.copyRemoteCommand()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: appState.copiedRemoteCommand ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9, weight: .semibold))
                    Text(appState.copiedRemoteCommand ? "Copied" : "Copy")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(appState.copiedRemoteCommand ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}

struct FooterView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack {
            Text("Independent personal utility · Not affiliated with Google")
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.40))

            Spacer()

            Button {
                appState.quit()
            } label: {
                Text("Quit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            .buttonStyle(.plain)
            .help("Quit Antigravity Usage (⌘Q)")
        }
    }
}

struct LoadingCardView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Connecting to local daemon...")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.60))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct OfflineCardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                Text("Daemon Offline")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            Text("LaunchAgent daemon not responding on 127.0.0.1:3007.")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.60))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    appState.triggerManualRefresh()
                } label: {
                    Text("Retry Connection")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct DashboardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 10) {
            if appState.quota != nil {
                // 1. Gemini Models Group (Both 5h and Weekly Limits)
                ModelGroupSection(
                    title: "Gemini Models",
                    subtitle: "Gemini Flash · Gemini Pro",
                    fiveHourFraction: appState.breakdown.gemini5hFraction ?? 1.0,
                    fiveHourReset: appState.breakdown.gemini5hResetsIn,
                    weeklyFraction: appState.breakdown.geminiWeeklyFraction ?? 1.0,
                    weeklyReset: appState.breakdown.geminiWeeklyResetsIn,
                    accentColor: Color(red: 0.04, green: 0.52, blue: 1.0)
                )
                .padding(.horizontal, 14)

                // 2. Claude & GPT Models Group (Both 5h and Weekly Limits)
                ModelGroupSection(
                    title: "Claude & GPT Models",
                    subtitle: "Claude Opus · Sonnet · GPT-OSS",
                    fiveHourFraction: appState.breakdown.claude5hFraction ?? 1.0,
                    fiveHourReset: appState.breakdown.claude5hResetsIn,
                    weeklyFraction: appState.breakdown.claudeWeeklyFraction ?? 1.0,
                    weeklyReset: appState.breakdown.claudeWeeklyResetsIn,
                    accentColor: Color(red: 0.75, green: 0.35, blue: 0.95)
                )
                .padding(.horizontal, 14)
            } else if appState.isOffline {
                OfflineCardView(appState: appState)
                    .padding(.horizontal, 14)
            } else {
                LoadingCardView()
                    .padding(.horizontal, 14)
            }

            RemoteDeviceBar(appState: appState)
                .padding(.horizontal, 14)

            FooterView(appState: appState)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .padding(.top, 4)
    }
}

struct SetupRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.60))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

struct SetupView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation {
                        appState.currentScreen = .dashboard
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back to Dashboard")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color(red: 0.04, green: 0.52, blue: 1.0))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("AUTHENTICATION & IDENTITY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.40))

                SetupRow(label: "Account", value: appState.quota?.account ?? "Active Account")
                SetupRow(label: "Plan Tier", value: appState.quota?.tier ?? "Google AI Ultra")
                SetupRow(label: "Credential Store", value: appState.quota?.credentialSource ?? "macOS Keychain")
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 8) {
                Text("DAEMON & NETWORK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.40))

                SetupRow(label: "Daemon Status", value: appState.isOffline ? "Offline" : "Running 24/7 (LaunchAgent)")
                SetupRow(label: "Local Port", value: "\(appState.quota?.port ?? 3007)")
                SetupRow(label: "Local LAN IP", value: appState.quota?.localIp ?? "127.0.0.1")
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 10) {
                Text("APPLICATION MANAGEMENT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.40))

                Button(role: .destructive) {
                    appState.quit()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "power")
                            .font(.system(size: 11, weight: .bold))
                        Text("Quit Antigravity Usage Completely")
                            .font(.system(size: 11, weight: .bold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.85))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }
}

struct MainContainerView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(appState: appState)

            Divider()
                .background(Color.white.opacity(0.08))

            if appState.currentScreen == .dashboard {
                DashboardView(appState: appState)
                    .transition(.opacity)
            } else {
                SetupView(appState: appState)
                    .transition(.opacity)
            }
        }
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.65), radius: 20, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .fixedSize(horizontal: true, vertical: false)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.currentScreen)
    }
}

struct DesktopWidgetView: View {
    @ObservedObject var appState: AppState

    var isHovering: Bool { appState.isWidgetHovering }

    var tierText: String {
        let t = appState.quota?.tier ?? "Ultra"
        return t.lowercased().contains("ultra") ? "Ultra" : t
    }

    var body: some View {
        let b = appState.breakdown
        let g5h = b.gemini5hFraction ?? 1.0
        let gWk = b.geminiWeeklyFraction ?? 1.0
        let c5h = b.claude5hFraction ?? 1.0
        let cWk = b.claudeWeeklyFraction ?? 1.0

        VStack(spacing: 6) {
            // Header
            HStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(red: 0.04, green: 0.05, blue: 0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.45), lineWidth: 0.8)
                        )
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(red: 0.04, green: 0.52, blue: 1.0))
                }
                .frame(width: 18, height: 18)

                Text("Antigravity")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)

                Text(tierText.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 0.8)
                            )
                    )

                Spacer()

                Button {
                    appState.onCloseWidget?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(isHovering ? 0.9 : 0.4))
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(isHovering ? Color.red.opacity(0.7) : Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
            }

            // All 4 Mini Progress Rows
            VStack(spacing: 3) {
                // 1. Gemini 5h
                HStack {
                    Text("Gemini (5h)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.70))
                    Spacer()
                    Text("\(Int(round(g5h * 100)))%")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundStyle(colorFor(fraction: g5h))
                }
                CustomProgressBar(fraction: g5h, height: 3)

                // 2. Gemini Wk
                HStack {
                    Text("Gemini (Wk)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.50))
                    Spacer()
                    Text("\(Int(round(gWk * 100)))%")
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(colorFor(fraction: gWk))
                }
                CustomProgressBar(fraction: gWk, height: 3)

                // 3. Claude 5h
                HStack {
                    Text("Claude (5h)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.70))
                    Spacer()
                    Text("\(Int(round(c5h * 100)))%")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundStyle(colorFor(fraction: c5h))
                }
                CustomProgressBar(fraction: c5h, height: 3)

                // 4. Claude Wk
                HStack {
                    Text("Claude (Wk)")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.50))
                    Spacer()
                    Text("\(Int(round(cWk * 100)))%")
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(colorFor(fraction: cWk))
                }
                CustomProgressBar(fraction: cWk, height: 3)
            }

            Text("Independent personal utility · Not affiliated with Google")
                .font(.system(size: 7, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(1)
        }
        .padding(9)
        .frame(width: 240, height: 136)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onHover { hovering in
            appState.isWidgetHovering = hovering
        }
        .onTapGesture(count: 2) {
            appState.onOpenFullApp?()
        }
    }

    private func colorFor(fraction: Double) -> Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }
}

// MARK: - AppKit AppDelegate & Window Management

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var detachedWindow: NSPanel?
    var widgetWindow: NSPanel?

    let appState = AppState()
    var pollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureDaemonRunning()

        appState.onToggleUnsnap = { [weak self] in
            self?.toggleUnsnapMode()
        }
        appState.onToggleWidget = { [weak self] in
            self?.toggleDesktopWidget()
        }
        appState.onCloseWidget = { [weak self] in
            self?.closeDesktopWidget()
        }
        appState.onOpenFullApp = { [weak self] in
            self?.snapOutPopover()
        }
        appState.onUpdateStatusTitle = { [weak self] title, tooltip in
            if self?.statusItem?.button?.title != title {
                self?.statusItem?.button?.title = title
            }
            if self?.statusItem?.button?.toolTip != tooltip {
                self?.statusItem?.button?.toolTip = tooltip
            }
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor

        popover = NSPopover()
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 490)
        popover.delegate = self
        popover.contentViewController = hostingVC

        setupStatusBar()
        setupMainMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Start 1-second live countdown timer and fetch initial data
        appState.startCountdownTimer()
        appState.fetchQuota()

        // 15-second background daemon polling in common RunLoop mode
        let timer = Timer(timeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.appState.fetchQuota()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.snapOutPopover()
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "✦ G: --% · C: --%"
            button.toolTip = "Antigravity Quota (Click to open dashboard)"
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            if appState.isUnsnapped {
                if let win = detachedWindow {
                    if win.isVisible {
                        win.orderOut(nil)
                    } else {
                        win.makeKeyAndOrderFront(nil)
                    }
                } else {
                    detachToWindow()
                }
            } else {
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    snapOutPopover()
                }
            }
        }
    }

    func snapOutPopover() {
        guard let button = statusItem.button else { return }
        if appState.isUnsnapped {
            if let win = detachedWindow {
                win.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                detachToWindow()
            }
            return
        }

        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            if let popWindow = popover.contentViewController?.view.window {
                popWindow.makeKey()
            }
            appState.fetchQuota()
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if appState.isUnsnapped {
            if let win = detachedWindow {
                if win.isVisible {
                    win.orderOut(nil)
                } else {
                    win.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            snapOutPopover()
        }
    }

    nonisolated func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    nonisolated func detachableWindow(for popover: NSPopover) -> NSWindow? {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                return self.detachToWindow()
            }
        } else {
            return DispatchQueue.main.sync {
                return self.detachToWindow()
            }
        }
    }

    @discardableResult
    func detachToWindow() -> NSWindow {
        if let existing = detachedWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return existing
        }

        appState.isUnsnapped = true

        let winWidth: CGFloat = 360
        let winHeight: CGFloat = 490

        // Multi-monitor coordinate positioning:
        // Identify the exact screen where the status item button lives.
        let targetScreen = statusItem.button?.window?.screen ?? NSScreen.main ?? NSScreen.screens.first
        let screenVisible = targetScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        var origin: NSPoint
        if let button = statusItem.button, let win = button.window {
            let buttonRectOnScreen = win.convertToScreen(button.bounds)
            let desiredX = buttonRectOnScreen.midX - (winWidth / 2)
            let desiredY = buttonRectOnScreen.minY - winHeight - 6

            // Clamp strictly inside targetScreen's visibleFrame so it never lands off-screen
            // or jumps to another monitor in setups where coordinates are negative
            let minX = screenVisible.minX + 8
            let maxX = max(minX, screenVisible.maxX - winWidth - 8)
            let clampedX = max(minX, min(desiredX, maxX))

            let minY = screenVisible.minY + 8
            let maxY = max(minY, screenVisible.maxY - winHeight - 8)
            let clampedY = max(minY, min(desiredY, maxY))

            origin = NSPoint(x: clampedX, y: clampedY)
        } else {
            origin = NSPoint(
                x: max(screenVisible.minX + 8, screenVisible.maxX - winWidth - 20),
                y: max(screenVisible.minY + 8, screenVisible.maxY - winHeight - 20)
            )
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: winWidth, height: winHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        if popover.isShown {
            popover.close()
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingVC

        detachedWindow = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        return panel
    }

    func snapBackToPopover() {
        guard appState.isUnsnapped else { return }
        appState.isUnsnapped = false

        if let win = detachedWindow {
            win.orderOut(nil)
            detachedWindow = nil
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor
        popover.contentViewController = hostingVC

        snapOutPopover()
    }

    func windowWillClose(_ notification: Notification) {
        if let win = notification.object as? NSPanel {
            if win == detachedWindow {
                snapBackToPopover()
            } else if win == widgetWindow {
                saveWidgetPosition(win)
                appState.isWidgetVisible = false
            }
        }
    }

    func toggleDesktopWidget() {
        if appState.isWidgetVisible {
            closeDesktopWidget()
        } else {
            showDesktopWidget()
        }
    }

    func showDesktopWidget() {
        if let win = widgetWindow {
            win.makeKeyAndOrderFront(nil)
            appState.isWidgetVisible = true
            return
        }

        let widgetWidth: CGFloat = 240
        let widgetHeight: CGFloat = 136

        let targetScreen = statusItem.button?.window?.screen ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = targetScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var targetFrame = NSRect(
            x: max(screenFrame.minX + 16, screenFrame.maxX - widgetWidth - 30),
            y: screenFrame.minY + 40,
            width: widgetWidth,
            height: widgetHeight
        )

        if let saved = UserDefaults.standard.string(forKey: "antigravity.widgetFrame") {
            let restored = NSRectFromString(saved)
            if restored.width > 0 && restored.height > 0 {
                targetFrame = restored
            }
        }

        let panel = NSPanel(
            contentRect: targetFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let hostingVC = NSHostingController(rootView: DesktopWidgetView(appState: appState))
        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingVC

        widgetWindow = panel
        appState.isWidgetVisible = true
        panel.makeKeyAndOrderFront(nil)
    }

    func closeDesktopWidget() {
        if let win = widgetWindow {
            saveWidgetPosition(win)
            win.orderOut(nil)
        }
        appState.isWidgetVisible = false
    }

    private func saveWidgetPosition(_ panel: NSPanel) {
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "antigravity.widgetFrame")
    }

    func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let titleItem = NSMenuItem(title: "Google Antigravity Quota", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        if let acc = appState.quota?.account {
            let accItem = NSMenuItem(title: "Account: \(acc)", action: nil, keyEquivalent: "")
            accItem.isEnabled = false
            menu.addItem(accItem)
        }

        if let tier = appState.quota?.tier {
            let tierItem = NSMenuItem(title: "Plan: \(tier)", action: nil, keyEquivalent: "")
            tierItem.isEnabled = false
            menu.addItem(tierItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Explicitly list all 4 rate limits in right-click context menu
        let b = appState.breakdown
        let g5hPct = Int(round((b.gemini5hFraction ?? 1.0) * 100))
        let gWkPct = Int(round((b.geminiWeeklyFraction ?? 1.0) * 100))
        let c5hPct = Int(round((b.claude5hFraction ?? 1.0) * 100))
        let cWkPct = Int(round((b.claudeWeeklyFraction ?? 1.0) * 100))

        let g5hItem = NSMenuItem(title: "• Gemini (5h Limit): \(g5hPct)% (\(formatRelativeTime(seconds: b.gemini5hResetsIn)))", action: nil, keyEquivalent: "")
        g5hItem.isEnabled = false
        menu.addItem(g5hItem)

        let gWkItem = NSMenuItem(title: "• Gemini (Weekly): \(gWkPct)% (\(formatRelativeTime(seconds: b.geminiWeeklyResetsIn)))", action: nil, keyEquivalent: "")
        gWkItem.isEnabled = false
        menu.addItem(gWkItem)

        let c5hItem = NSMenuItem(title: "• Claude/GPT (5h Limit): \(c5hPct)% (\(formatRelativeTime(seconds: b.claude5hResetsIn)))", action: nil, keyEquivalent: "")
        c5hItem.isEnabled = false
        menu.addItem(c5hItem)

        let cWkItem = NSMenuItem(title: "• Claude/GPT (Weekly): \(cWkPct)% (\(formatRelativeTime(seconds: b.claudeWeeklyResetsIn)))", action: nil, keyEquivalent: "")
        cWkItem.isEnabled = false
        menu.addItem(cWkItem)

        menu.addItem(NSMenuItem.separator())

        if appState.isUnsnapped {
            let snapItem = NSMenuItem(title: "Snap Back to Menu Bar", action: #selector(snapMenuAction), keyEquivalent: "u")
            snapItem.target = self
            menu.addItem(snapItem)
        } else {
            let unsnapItem = NSMenuItem(title: "Unsnap to Floating Window", action: #selector(unsnapMenuAction), keyEquivalent: "u")
            unsnapItem.target = self
            menu.addItem(unsnapItem)
        }

        let widgetItemTitle = appState.isWidgetVisible ? "Hide Desktop Widget" : "Add Desktop Widget"
        let widgetItem = NSMenuItem(title: widgetItemTitle, action: #selector(widgetMenuAction), keyEquivalent: "w")
        widgetItem.target = self
        if appState.isWidgetVisible {
            widgetItem.state = .on
        }
        menu.addItem(widgetItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshDataFromMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let copyItem = NSMenuItem(title: "Copy Remote Device curl Command", action: #selector(copyRemoteCmd), keyEquivalent: "c")
        copyItem.target = self
        menu.addItem(copyItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Antigravity Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    @objc func unsnapMenuAction() {
        detachToWindow()
    }

    @objc func snapMenuAction() {
        snapBackToPopover()
    }

    @objc func widgetMenuAction() {
        toggleDesktopWidget()
    }

    @objc func refreshDataFromMenu() {
        appState.triggerManualRefresh()
    }

    @objc func copyRemoteCmd() {
        appState.copyRemoteCommand()
    }

    @objc func systemDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.appState.fetchQuota(force: true)
        }
    }

    func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About Antigravity Usage", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())

        let unsnapItem = NSMenuItem(title: "Unsnap / Snap Window", action: #selector(toggleUnsnapMode), keyEquivalent: "u")
        unsnapItem.target = self
        appMenu.addItem(unsnapItem)

        let widgetItem = NSMenuItem(title: "Toggle Desktop Widget", action: #selector(widgetMenuAction), keyEquivalent: "w")
        widgetItem.target = self
        appMenu.addItem(widgetItem)

        let reloadItem = NSMenuItem(title: "Refresh Data", action: #selector(refreshDataFromMenu), keyEquivalent: "r")
        reloadItem.target = self
        appMenu.addItem(reloadItem)
        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(withTitle: "Quit Antigravity Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        NSApp.mainMenu = mainMenu
    }

    @objc func toggleUnsnapMode() {
        if appState.isUnsnapped {
            snapBackToPopover()
        } else {
            detachToWindow()
        }
    }

    func ensureDaemonRunning() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "curl -s --connect-timeout 1 http://127.0.0.1:3007/healthz || launchctl load ~/Library/LaunchAgents/com.antigravity.usage_v4.plist 2>/dev/null"]
        task.terminationHandler = { _ in }
        do {
            try task.run()
        } catch {
            NSLog("[Antigravity] Failed to run daemon check process: \(error)")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if appState.isUnsnapped, let win = detachedWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            snapOutPopover()
        }
        return true
    }
}

// MARK: - Entry Point

@main
struct AppLauncher {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
