// AntigravityWidget/AntigravityWidget.swift
// v1 – Native macOS WidgetKit TimelineProvider and Views
import WidgetKit
import SwiftUI

struct AntigravityEntry: TimelineEntry {
    let date: Date
    let quotaPercent: Int
    let tier: String
    let account: String
    let lastUpdated: Date?
}

struct AntigravityProvider: TimelineProvider {
    func placeholder(in context: Context) -> AntigravityEntry {
        AntigravityEntry(
            date: Date(),
            quotaPercent: 84,
            tier: "Google AI Ultra",
            account: "account@example.com",
            lastUpdated: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AntigravityEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.dad.aiusage")
        let pct = defaults?.integer(forKey: "antigravity.quotaPercent") ?? 84
        let tier = defaults?.string(forKey: "antigravity.tier") ?? "Google AI Ultra"
        let account = defaults?.string(forKey: "antigravity.account") ?? "Active Account"
        let updated = defaults?.object(forKey: "antigravity.lastUpdated") as? Date

        completion(AntigravityEntry(
            date: Date(),
            quotaPercent: pct,
            tier: tier,
            account: account,
            lastUpdated: updated
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AntigravityEntry>) -> Void) {
        getSnapshot(in: context) { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct AntigravityWidgetEntryView: View {
    var entry: AntigravityProvider.Entry

    var colorForPercent: Color {
        if entry.quotaPercent >= 50 { return Color.green }
        if entry.quotaPercent >= 20 { return Color.yellow }
        return Color.red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("✦ Antigravity")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Text(entry.tier.contains("Ultra") ? "Ultra" : entry.tier)
                    .font(.system(size: 8.5, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.yellow)
                    .cornerRadius(4)
            }

            Text("\(entry.quotaPercent)%")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(colorForPercent)

            ProgressView(value: Double(entry.quotaPercent), total: 100.0)
                .tint(colorForPercent)

            HStack {
                Text(entry.account)
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                if let updated = entry.lastUpdated {
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

struct AntigravityUsageWidget: Widget {
    let kind: String = "AntigravityUsageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AntigravityProvider()) { entry in
            AntigravityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Antigravity Quota")
        .description("Real-time view of your Google Antigravity quota and tier.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
