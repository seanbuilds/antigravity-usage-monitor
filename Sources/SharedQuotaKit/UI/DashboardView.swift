// Sources/SharedQuotaKit/UI/DashboardView.swift
import SwiftUI

public struct CustomProgressBar: View {
    public let fraction: Double
    public let height: CGFloat

    public init(fraction: Double, height: CGFloat = 4) {
        self.fraction = max(0.0, min(1.0, fraction))
        self.height = height
    }

    private var barColor: Color {
        if fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: height)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [barColor.opacity(0.85), barColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(3, geo.size.width * CGFloat(fraction)), height: height)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: fraction)
            }
        }
        .frame(height: height)
    }
}

public struct RateLimitCardView: View {
    public let limit: RateLimitWindow

    public init(limit: RateLimitWindow) {
        self.limit = limit
    }

    private var barColor: Color {
        if limit.fraction < 0.20 { return Color(red: 1.0, green: 0.27, blue: 0.23) }
        if limit.fraction < 0.50 { return Color(red: 1.0, green: 0.84, blue: 0.04) }
        return Color(red: 0.19, green: 0.82, blue: 0.35)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: limit.iconName)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color.white.opacity(0.60))
                    Text(limit.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()

                HStack(spacing: 6) {
                    // Live Countdown Timer Badge
                    Text(formatRelativeTime(seconds: limit.resetsInSeconds))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.72, blue: 1.0))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(red: 0.04, green: 0.52, blue: 1.0).opacity(0.30), lineWidth: 0.8)
                                )
                        )

                    Text("\(limit.percentage)%")
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(barColor)
                }
            }

            CustomProgressBar(fraction: limit.fraction, height: 4)
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

public struct ModelGroupCardView: View {
    public let group: ModelQuotaGroup

    public init(group: ModelQuotaGroup) {
        self.group = group
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(group.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(group.subtitle)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.50))
                    .lineLimit(1)
            }

            VStack(spacing: 6) {
                RateLimitCardView(limit: group.primaryLimit)
                RateLimitCardView(limit: group.secondaryLimit)
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

@MainActor
public class DashboardViewModel: ObservableObject {
    @Published public var snapshot: UnifiedQuotaSnapshot?
    @Published public var isLoading: Bool = false
    @Published public var isOffline: Bool = false
    @Published public var isUnsnapped: Bool = false
    @Published public var showDiagnostics: Bool = false
    @Published public var refreshRotation: Double = 0

    public var onToggleUnsnap: (() -> Void)?
    public var onRefresh: (() -> Void)?
    public var onQuit: (() -> Void)?

    public init(snapshot: UnifiedQuotaSnapshot? = nil) {
        self.snapshot = snapshot
    }

    public func triggerRefresh() {
        withAnimation(.easeInOut(duration: 0.6)) {
            refreshRotation += 360
        }
        onRefresh?()
    }
}

public struct SharedDashboardView: View {
    @ObservedObject public var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header Bar
            HStack(spacing: 7) {
                Text(viewModel.snapshot?.brand.statusSymbol ?? "✦")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(viewModel.snapshot?.brand.accentColor ?? .blue)

                Text(viewModel.snapshot?.brand.displayName.uppercased() ?? "QUOTA")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text((viewModel.snapshot?.tier ?? "ULTRA").uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.04))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .strokeBorder(Color(red: 1.0, green: 0.84, blue: 0.04).opacity(0.35), lineWidth: 1)
                            )
                    )

                Spacer()

                // Actions: Diagnostics, Unsnap, Refresh
                HStack(spacing: 6) {
                    Button {
                        viewModel.showDiagnostics.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(viewModel.showDiagnostics ? Color.blue : Color.white.opacity(0.65))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.onToggleUnsnap?()
                    } label: {
                        Image(systemName: viewModel.isUnsnapped ? "arrow.down.left.square" : "arrow.up.right.square")
                            .font(.system(size: 11))
                            .foregroundStyle(viewModel.isUnsnapped ? Color.blue : Color.white.opacity(0.65))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.triggerRefresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .rotationEffect(.degrees(viewModel.refreshRotation))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.showDiagnostics {
                // Diagnostics Screen
                VStack(alignment: .leading, spacing: 8) {
                    Text("SYSTEM DIAGNOSTICS")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.70))

                    Text("• Account: \(viewModel.snapshot?.account ?? "N/A")")
                    Text("• Tier: \(viewModel.snapshot?.tier ?? "N/A") (\(viewModel.snapshot?.tierId ?? "N/A"))")
                    Text("• Last Updated: \(viewModel.snapshot?.lastUpdated.formatted() ?? "N/A")")
                    Text("• Mode: \(viewModel.isUnsnapped ? "Floating HUD" : "Snapped Popover")")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.35))
                .cornerRadius(8)
            } else {
                // Main Rate Limit Matrix
                if let groups = viewModel.snapshot?.groups, !groups.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(groups) { grp in
                            ModelGroupCardView(group: grp)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Connecting to local engine...")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.60))
                    }
                    .frame(height: 160)
                }
            }

            // Footer
            HStack {
                Text(viewModel.snapshot?.account ?? "Active Profile")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.50))
                    .lineLimit(1)

                Spacer()

                Button("Quit") {
                    viewModel.onQuit?()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.red.opacity(0.85))
            }
        }
        .padding(14)
        .frame(width: 360)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .overlay(Color(red: 13/255, green: 16/255, blue: 23/255).opacity(0.92))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
