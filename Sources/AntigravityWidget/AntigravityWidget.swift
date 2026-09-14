// Sources/AntigravityWidget/AntigravityWidget.swift
import WidgetKit
import SwiftUI
import SharedQuotaKit

public struct AntigravityTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> QuotaWidgetEntry {
        QuotaWidgetEntry(date: Date(), snapshot: nil)
    }

    public func getSnapshot(in context: Context, completion: @escaping (QuotaWidgetEntry) -> Void) {
        let snapshot = AppGroupPersistence.shared.loadSnapshot(for: .antigravity)
        completion(QuotaWidgetEntry(date: Date(), snapshot: snapshot))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<QuotaWidgetEntry>) -> Void) {
        let snapshot = AppGroupPersistence.shared.loadSnapshot(for: .antigravity)
        let entry = QuotaWidgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct AntigravityWidgetEntryView: View {
    public let entry: QuotaWidgetEntry

    public init(entry: QuotaWidgetEntry) {
        self.entry = entry
    }

    private var primaryPercent: Int {
        entry.snapshot?.groups.first?.primaryLimit.percentage ?? 100
    }

    private var statusColor: Color {
        if primaryPercent >= 50 { return .green }
        if primaryPercent >= 20 { return .yellow }
        return .red
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("✦ Antigravity")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Text(entry.snapshot?.tier.contains("Ultra") == true ? "ULTRA" : (entry.snapshot?.tier ?? "ACTIVE"))
                    .font(.system(size: 8.5, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.yellow)
                    .cornerRadius(4)
            }

            Text("\(primaryPercent)%")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(statusColor)

            ProgressView(value: Double(primaryPercent), total: 100.0)
                .tint(statusColor)

            HStack {
                Text(entry.snapshot?.account ?? "Active Profile")
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                if let updated = entry.snapshot?.lastUpdated {
                    Text(updated, style: .time)
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor).opacity(0.9)
        }
    }
}

public struct AntigravityUsageWidget: Widget {
    public let kind: String = "AntigravityUsageWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AntigravityTimelineProvider()) { entry in
            AntigravityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Antigravity Quota")
        .description("Real-time Google Antigravity quota and rate limit status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
