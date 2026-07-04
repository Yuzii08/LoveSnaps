import WidgetKit
import SwiftUI

// ── Data Model ───────────────────────────────────────────────────────────────

struct LoveSnapEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let daysCount: Int
    let partnerName: String
    let distance: String
    let streakAtRisk: Bool
    let missYouReceived: Bool
}

// ── Colors ───────────────────────────────────────────────────────────────────

struct KawaiiColors {
    static let primary = Color(red: 0.361, green: 0.365, blue: 0.431)
    static let primaryContainer = Color(red: 0.902, green: 0.902, blue: 0.980)
    static let tertiary = Color(red: 0.529, green: 0.306, blue: 0.345)
    static let tertiaryContainer = Color(red: 1.0, green: 0.878, blue: 0.890)
    static let onTertiaryContainer = Color(red: 0.569, green: 0.341, blue: 0.380)
    static let surface = Color(red: 0.976, green: 0.976, blue: 1.0)
    static let warning = Color(red: 0.73, green: 0.1, blue: 0.1)
}

// ── Data Provider ────────────────────────────────────────────────────────────

struct LoveSnapProvider: TimelineProvider {

    /// Shared UserDefaults (App Group — set up in Xcode Signing & Capabilities)
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.lovesnaps.app")
    }

    func placeholder(in context: Context) -> LoveSnapEntry {
        LoveSnapEntry(
            date: Date(),
            streakCount: 14,
            daysCount: 87,
            partnerName: "Partner",
            distance: "2.3 km away",
            streakAtRisk: false,
            missYouReceived: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LoveSnapEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LoveSnapEntry>) -> Void) {
        let entry = readEntry()
        // Refresh every 20 minutes; also refreshed immediately by the Flutter app on state change
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 20, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readEntry() -> LoveSnapEntry {
        let defaults = sharedDefaults
        return LoveSnapEntry(
            date: Date(),
            streakCount: defaults?.integer(forKey: "streak_count") ?? 0,
            daysCount: defaults?.integer(forKey: "days_count") ?? 0,
            partnerName: defaults?.string(forKey: "partner_name") ?? "Partner",
            distance: defaults?.string(forKey: "distance") ?? "—",
            streakAtRisk: defaults?.bool(forKey: "streak_at_risk") ?? false,
            missYouReceived: defaults?.bool(forKey: "miss_you_received") ?? false
        )
    }
}

// ── Small Widget View (systemSmall) ───────────────────────────────────────────

struct LoveSnapSmallView: View {
    let entry: LoveSnapEntry

    var body: some View {
        VStack(spacing: 4) {
            // Streak section
            VStack(spacing: 2) {
                Text(entry.streakAtRisk ? "⚠️" : (entry.streakCount > 0 ? "🔥" : "💤"))
                    .font(.system(size: 28))
                Text("\(entry.streakCount)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(KawaiiColors.tertiary)
                Text("streak")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Divider()
                .padding(.horizontal, 12)

            // Days section
            VStack(spacing: 2) {
                Text("💕")
                    .font(.system(size: 16))
                Text("Day \(entry.daysCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(KawaiiColors.primary)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    KawaiiColors.surface,
                    KawaiiColors.primaryContainer,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .widgetURL(URL(string: "lovesnaps://home"))
    }
}

// ── Medium Widget View (systemMedium) ─────────────────────────────────────────

struct LoveSnapMediumView: View {
    let entry: LoveSnapEntry

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Streak + Days
            HStack(spacing: 0) {
                // Streak
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.streakAtRisk ? "⚠️" : "🔥")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(entry.streakCount) day\(entry.streakCount == 1 ? "" : "s")")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundColor(KawaiiColors.tertiary)
                            Text(entry.streakAtRisk ? "⚠️ at risk!" : "streak")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(entry.streakAtRisk
                                    ? KawaiiColors.warning
                                    : .secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 36)
                    .padding(.horizontal, 8)

                // Days Together
                VStack(alignment: .leading, spacing: 2) {
                    Text("💕 Together")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Day \(entry.daysCount)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(KawaiiColors.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // Bottom row: Distance + Miss You
            HStack(spacing: 8) {
                // Distance
                VStack(alignment: .leading, spacing: 2) {
                    Text("📍 Distance")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(entry.distance)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(KawaiiColors.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Miss You button (opens app to trigger the action)
                Link(destination: URL(string: "lovesnaps://missyou")!) {
                    HStack(spacing: 4) {
                        Text(entry.missYouReceived ? "💌" : "💕")
                            .font(.system(size: 14))
                        Text(entry.missYouReceived
                            ? "\(entry.partnerName) 💌"
                            : "Miss You")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(KawaiiColors.onTertiaryContainer)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(KawaiiColors.tertiaryContainer)
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    KawaiiColors.surface,
                    KawaiiColors.primaryContainer,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .widgetURL(URL(string: "lovesnaps://home"))
    }
}

// ── Widget Configuration ───────────────────────────────────────────────────────

struct LoveSnapsWidget: Widget {
    let kind: String = "LoveSnapsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoveSnapProvider()) { entry in
            Group {
                // Render different views based on widget family
                LoveSnapSmallView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            }
        }
        .configurationDisplayName("LoveSnaps")
        .description("Stay connected — streak, days together, distance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// ── Widget Entry Point ─────────────────────────────────────────────────────────

@main
struct LoveSnapsWidgetBundle: WidgetBundle {
    var body: some Widget {
        LoveSnapsWidget()
    }
}

// ── View selection by family ───────────────────────────────────────────────────

extension LoveSnapsWidget {
    @ViewBuilder
    static func view(for family: WidgetFamily, entry: LoveSnapEntry) -> some View {
        switch family {
        case .systemSmall:
            LoveSnapSmallView(entry: entry)
        case .systemMedium:
            LoveSnapMediumView(entry: entry)
        default:
            LoveSnapSmallView(entry: entry)
        }
    }
}
