// v8 – 100% Pure Native SwiftUI & AppKit macOS Menu Bar Application
//      Zero WebKit/HTML wrappers. Pure macOS Controls, Frosted Glass Materials,
//      Spring Animations, Floating HUD Window, Native Desktop Widget & App Group Sync.
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

// MARK: - Formatters & Helpers

func formatRelativeTime(seconds: Int?) -> String {
    guard let s = seconds, s > 0 else { return "Ready" }
    if s < 60 { return "\(s)s left" }
    let days = s / 86400
    let hours = (s % 86400) / 3600
    let mins = (s % 3600) / 60
    var parts: [String] = []
    if days > 0 { parts.append("\(days)d") }
    if hours > 0 || days > 0 { parts.append("\(hours)h") }
    parts.append("\(mins)m")
    return parts.prefix(2).joined(separator: " ") + " left"
}

public enum ScreenMode: Hashable {
    case dashboard
    case setup
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var quota: QuotaData?
    @Published var isLoading: Bool = false
    @Published var isOffline: Bool = false
    @Published var errorMessage: String?
    @Published var currentScreen: ScreenMode = .dashboard
    @Published var isUnsnapped: Bool = false
    @Published var isWidgetVisible: Bool = false
    @Published var isWidgetHovering: Bool = false
    @Published var copiedRemoteCommand: Bool = false

    var onToggleUnsnap: (() -> Void)?
    var onToggleWidget: (() -> Void)?
    var onCloseWidget: (() -> Void)?
    var onOpenFullApp: (() -> Void)?
    var onUpdateStatusTitle: ((String, String) -> Void)?

    func fetchQuota(force: Bool = false) {
        isLoading = true
        let urlStr = force ? "http://127.0.0.1:3007/quota?refresh=1" : "http://127.0.0.1:3007/quota"
        guard let url = URL(string: urlStr) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(QuotaData.self, from: data)
                self.quota = decoded
                self.isOffline = false
                self.errorMessage = nil
                self.isLoading = false
                self.syncToAppGroup(decoded)
                self.updateStatusTitle(with: decoded)
            } catch {
                self.isOffline = true
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.onUpdateStatusTitle?("✦ offline", "Antigravity Quota: Daemon offline (retrying...)")
            }
        }
    }

    func computeDisplayPercent(for quota: QuotaData) -> Int {
        var minFraction = 1.0
        var primaryFraction: Double?

        for grp in quota.groups ?? [] {
            let isGemini = (grp.displayName ?? grp.name ?? "").lowercased().contains("gemini")
            for b in grp.buckets ?? [] {
                if let frac = b.remainingFraction {
                    minFraction = min(minFraction, frac)
                    if isGemini && (b.window == "5h" || (b.displayName ?? "").contains("Five Hour")) {
                        primaryFraction = frac
                    }
                }
            }
        }
        let effective = primaryFraction ?? minFraction
        return Int(round(effective * 100))
    }

    func updateStatusTitle(with quota: QuotaData) {
        let pct = computeDisplayPercent(for: quota)
        let tierName = quota.tier ?? "Google AI Ultra"
        onUpdateStatusTitle?("✦ \(pct)%", "Antigravity Quota (\(tierName)): \(pct)% primary capacity")
    }

    func syncToAppGroup(_ quota: QuotaData) {
        let pct = computeDisplayPercent(for: quota)
        if let defaults = UserDefaults(suiteName: "group.com.dad.aiusage") {
            defaults.set(pct, forKey: "antigravity.quotaPercent")
            defaults.set(Date(), forKey: "antigravity.lastUpdated")
            defaults.set(quota.tier ?? "Google AI Ultra", forKey: "antigravity.tier")
            defaults.set(quota.account ?? "Active Account", forKey: "antigravity.account")
            WidgetCenter.shared.reloadTimelines(ofKind: "AntigravityUsageWidget")
        }
    }

    func copyRemoteCommand() {
        let cmd = quota?.remoteCommand ?? "curl -s http://192.168.5.67:3007"
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

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct CustomProgressBar: View {
    let fraction: Double

    var color: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(fraction))))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fraction)
            }
        }
        .frame(height: 5)
    }
}

struct HeaderView: View {
    @ObservedObject var appState: AppState

    var tierText: String {
        let t = appState.quota?.tier ?? "Ultra"
        return t.lowercased().contains("ultra") ? "Ultra" : t
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Icon + Title + Badge
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)

                Text("Antigravity")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.primary)

                Text(tierText.uppercased())
                    .font(.system(size: 8.5, weight: .heavy))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.18))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 1)
                            )
                    )
            }

            Spacer()

            // 4-Icon Toolbar
            HStack(spacing: 5) {
                // 1. Desktop Widget
                Button {
                    appState.onToggleWidget?()
                } label: {
                    Image(systemName: appState.isWidgetVisible ? "rectangle.fill.on.rectangle.fill" : "rectangle.on.rectangle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(appState.isWidgetVisible ? Color.accentColor : Color.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(appState.isWidgetVisible ? 0.16 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(appState.isWidgetVisible ? "Hide Desktop Widget" : "Add Desktop Widget")

                // 2. Setup & Diagnostics
                Button {
                    withAnimation {
                        appState.currentScreen = (appState.currentScreen == .dashboard) ? .setup : .dashboard
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(appState.currentScreen == .setup ? Color.accentColor : Color.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(appState.currentScreen == .setup ? 0.16 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Settings & Server Diagnostics")

                // 3. Unsnap / Snap
                Button {
                    appState.onToggleUnsnap?()
                } label: {
                    Image(systemName: appState.isUnsnapped ? "arrow.down.left.square" : "arrow.up.right.square")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(appState.isUnsnapped ? Color.accentColor : Color.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(appState.isUnsnapped ? 0.16 : 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(appState.isUnsnapped ? "Snap back to Menu Bar (⌘U)" : "Unsnap to Floating Window (⌘U)")

                // 4. Refresh
                Button {
                    appState.fetchQuota(force: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                        .animation(appState.isLoading ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: appState.isLoading)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Refresh Quota (⌘R)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

struct BucketRowView: View {
    let bucket: QuotaBucket

    var fraction: Double {
        bucket.remainingFraction ?? 1.0
    }

    var percentText: String {
        "\(Int(round(fraction * 100)))%"
    }

    var color: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(bucket.displayName ?? bucket.label ?? bucket.window ?? "Limit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text(percentText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(color)

                    if let secs = bucket.resetsInSeconds, secs > 0 {
                        Text("(\(formatRelativeTime(seconds: secs)))")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            CustomProgressBar(fraction: fraction)
        }
    }
}

struct GroupCardView: View {
    let group: QuotaGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.displayName ?? group.name ?? "Models")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                if let desc = group.description {
                    Text(desc.replacingOccurrences(of: "Models within this group: ", with: ""))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let buckets = group.buckets {
                VStack(spacing: 8) {
                    ForEach(buckets) { bucket in
                        BucketRowView(bucket: bucket)
                    }
                }
            }
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
    }
}

struct RemoteDeviceBar: View {
    @ObservedObject var appState: AppState

    var cmd: String {
        appState.quota?.remoteCommand ?? "curl -s http://192.168.5.67:3007"
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            Text(cmd)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
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
                .foregroundStyle(appState.copiedRemoteCommand ? Color.green : Color.primary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
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
                .foregroundStyle(.tertiary)

            Spacer()

            Button {
                appState.quit()
            } label: {
                Text("Quit")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
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
                    .foregroundStyle(.yellow)
                Text("Daemon Offline")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            Text("LaunchAgent daemon not responding on 127.0.0.1:3007.")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    appState.fetchQuota(force: true)
                } label: {
                    Text("Retry Connection")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.yellow.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct DashboardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            if let account = appState.quota?.account {
                HStack {
                    Text(account)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            if let groups = appState.quota?.groups, !groups.isEmpty {
                ForEach(groups) { group in
                    GroupCardView(group: group)
                }
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
                .padding(.horizontal, 16)
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
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
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
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("AUTHENTICATION & IDENTITY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)

                SetupRow(label: "Account", value: appState.quota?.account ?? "ohheysean@gmail.com")
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
                    .foregroundStyle(.tertiary)

                SetupRow(label: "Daemon Status", value: appState.isOffline ? "Offline" : "Running 24/7 (LaunchAgent)")
                SetupRow(label: "Local Port", value: "\(appState.quota?.port ?? 3007)")
                SetupRow(label: "Local LAN IP", value: appState.quota?.localIp ?? "192.168.5.67")
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
                    .foregroundStyle(.tertiary)

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
                            .fill(Color.red.opacity(0.8))
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
        ZStack {
            VisualEffectBackground()

            VStack(spacing: 0) {
                HeaderView(appState: appState)

                Divider()
                    .background(Color.white.opacity(0.1))

                if appState.currentScreen == .dashboard {
                    DashboardView(appState: appState)
                        .transition(.opacity)
                } else {
                    SetupView(appState: appState)
                        .transition(.opacity)
                }
            }
        }
        .frame(width: 360)
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

    var geminiFraction: Double {
        for grp in appState.quota?.groups ?? [] {
            if (grp.displayName ?? grp.name ?? "").lowercased().contains("gemini") {
                for b in grp.buckets ?? [] {
                    if b.window == "5h" || (b.displayName ?? "").contains("Five Hour") {
                        return b.remainingFraction ?? 1.0
                    }
                }
            }
        }
        return 1.0
    }

    var claudeFraction: Double {
        for grp in appState.quota?.groups ?? [] {
            if !(grp.displayName ?? grp.name ?? "").lowercased().contains("gemini") {
                for b in grp.buckets ?? [] {
                    if b.window == "5h" || (b.displayName ?? "").contains("Five Hour") {
                        return b.remainingFraction ?? 1.0
                    }
                }
            }
        }
        return 1.0
    }

    var body: some View {
        ZStack {
            VisualEffectBackground()

            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    Text("Antigravity")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(tierText.uppercased())
                        .font(.system(size: 7.5, weight: .heavy))
                        .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 0.8)
                                )
                        )

                    Spacer()

                    Button {
                        appState.onCloseWidget?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(isHovering ? Color.red : Color.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
                }

                VStack(spacing: 4) {
                    VStack(spacing: 2) {
                        HStack {
                            Text("Gemini (5h)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(round(geminiFraction * 100)))%")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(colorFor(fraction: geminiFraction))
                        }
                        CustomProgressBar(fraction: geminiFraction)
                    }

                    VStack(spacing: 2) {
                        HStack {
                            Text("Claude & GPT")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(round(claudeFraction * 100)))%")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(colorFor(fraction: claudeFraction))
                        }
                        CustomProgressBar(fraction: claudeFraction)
                    }
                }

                Text("Independent personal utility · Not affiliated with Google")
                    .font(.system(size: 7, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(10)
        }
        .frame(width: 240, height: 124)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
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
            self?.statusItem?.button?.title = title
            self?.statusItem?.button?.toolTip = tooltip
        }

        popover = NSPopover()
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 430)
        popover.delegate = self

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
        popover.contentViewController = hostingVC

        setupStatusBar()
        setupMainMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        appState.fetchQuota()
        let timer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
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
            button.title = "✦ --%"
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
            if appState.isUnsnapped, let win = detachedWindow, win.isVisible {
                win.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                togglePopover(sender)
            }
        }
    }

    func snapOutPopover() {
        guard let button = statusItem.button else { return }
        if appState.isUnsnapped {
            detachedWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        if !popover.isShown {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
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
        let winHeight: CGFloat = 430

        var origin = NSPoint(x: 250, y: 350)
        if let button = statusItem.button, let win = button.window {
            let buttonRect = win.convertToScreen(button.bounds)
            origin = NSPoint(x: max(20, buttonRect.origin.x - (winWidth / 2)), y: max(40, buttonRect.origin.y - winHeight - 10))
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: winWidth, height: winHeight)),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        if popover.isShown {
            popover.close()
        }

        let hostingVC = NSHostingController(rootView: MainContainerView(appState: appState))
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
        let widgetHeight: CGFloat = 124

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var targetFrame = NSRect(x: screenFrame.maxX - widgetWidth - 30, y: screenFrame.minY + 40, width: widgetWidth, height: widgetHeight)

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

        if let groups = appState.quota?.groups, !groups.isEmpty {
            for grp in groups {
                let gName = grp.displayName ?? grp.name ?? "Models"
                for b in grp.buckets ?? [] {
                    let bName = b.displayName ?? b.label ?? b.kind ?? "Limit"
                    let frac = b.remainingFraction ?? 1.0
                    let pctStr = String(format: "%.0f%%", frac * 100)
                    let subItem = NSMenuItem(title: "\(gName) (\(bName)): \(pctStr)", action: nil, keyEquivalent: "")
                    subItem.isEnabled = false
                    menu.addItem(subItem)
                }
            }
            menu.addItem(NSMenuItem.separator())
        }

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
        appState.fetchQuota(force: true)
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
