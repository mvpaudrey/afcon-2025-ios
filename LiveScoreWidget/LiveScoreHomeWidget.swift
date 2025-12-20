import WidgetKit
import SwiftUI

struct LiveScoreHomeEntry: TimelineEntry {
    let date: Date
    let match: LiveMatchWidgetSnapshot?
}

struct LiveScoreHomeProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LiveScoreHomeEntry {
        LiveScoreHomeEntry(date: Date(), match: .sample)
    }

    func snapshot(for configuration: SelectMatchIntent, in context: Context) async -> LiveScoreHomeEntry {
        if context.isPreview {
            return LiveScoreHomeEntry(date: Date(), match: .sample)
        }
        return LiveScoreHomeEntry(date: Date(), match: match(for: configuration))
    }

    func timeline(for configuration: SelectMatchIntent, in context: Context) async -> Timeline<LiveScoreHomeEntry> {
        let entry = LiveScoreHomeEntry(date: Date(), match: match(for: configuration))
        let refresh = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func match(for configuration: SelectMatchIntent) -> LiveMatchWidgetSnapshot? {
        if let selected = configuration.match {
            return AppGroupMatchStore.shared.snapshot(for: selected.fixtureID)
        }
        return AppGroupMatchStore.shared.snapshots().first
    }
}

struct LiveScoreHomeWidget: Widget {
    let kind = "LiveScoreHomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectMatchIntent.self, provider: LiveScoreHomeProvider()) { entry in
            LiveScoreHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Live Match Score")
        .description("See the latest match score on your Home Screen.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct LiveScoreHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LiveScoreHomeEntry

    var body: some View {
        if let match = entry.match {
            switch family {
            case .systemLarge:
                LargeLiveScoreView(match: match, date: entry.date)
            default:
                MediumLiveScoreView(match: match, date: entry.date)
            }
        } else {
            NoMatchView()
        }
    }
}

private struct MediumLiveScoreView: View {
    let match: LiveMatchWidgetSnapshot
    let date: Date

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(alignment: .leading, spacing: 12) {
                Header(status: match.statusLabel, updated: match.updatedText(reference: date))

                Text(match.competition.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    TeamColumn(
                        name: match.homeTeam,
                        score: match.homeScore,
                        logoPath: match.homeLogoPath,
                        isHome: true
                    )

                    Divider()
                        .frame(height: 44)
                        .overlay(Color.primary.opacity(0.15))

                    TeamColumn(
                        name: match.awayTeam,
                        score: match.awayScore,
                        logoPath: match.awayLogoPath,
                        isHome: false
                    )
                }

                if match.isLive {
                    Text(match.timerText(reference: date))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .monospacedDigit()
                } else {
                    Text(match.statusLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

private struct LargeLiveScoreView: View {
    let match: LiveMatchWidgetSnapshot
    let date: Date

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(alignment: .leading, spacing: 16) {
                Header(status: match.statusLabel, updated: match.updatedText(reference: date))

                HStack(spacing: 16) {
                    TeamColumn(
                        name: match.homeTeam,
                        score: match.homeScore,
                        logoPath: match.homeLogoPath,
                        isHome: true
                    )

                    Spacer(minLength: 12)

                    VStack(spacing: 4) {
                        Text(match.isLive ? match.timerText(reference: date) : match.statusLabel)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(match.isLive ? .green : .secondary)
                            .monospacedDigit()
                        Text(match.competition.uppercased())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 12)

                    TeamColumn(
                        name: match.awayTeam,
                        score: match.awayScore,
                        logoPath: match.awayLogoPath,
                        isHome: false
                    )
                }

                GoalListView(home: match.homeGoalEvents, away: match.awayGoalEvents)
            }
            .padding()
        }
    }
}

private struct Header: View {
    let status: String
    let updated: String

    var body: some View {
        HStack {
            Label(status, systemImage: "bolt.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            Spacer()
            Text(updated)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

private struct TeamColumn: View {
    let name: String
    let score: Int
    let logoPath: String?
    let isHome: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    var body: some View {
        HStack(spacing: 8) {
            if isHome {
                LogoImageView(path: logoPath, size: CGSize(width: 32, height: 32))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: isHome ? .leading : .trailing, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(textColor)
            }

            if !isHome {
                LogoImageView(path: logoPath, size: CGSize(width: 32, height: 32))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private struct GoalListView: View {
    let home: [String]
    let away: [String]
    @Environment(\.colorScheme) private var colorScheme

    private var goalTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.primary
    }

    var body: some View {
        let maxCount = max(home.count, away.count)
        if maxCount == 0 {
            HStack {
                Image(systemName: "minus.circle")
                    .foregroundColor(.secondary)
                Text("No goals yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                ForEach(0..<maxCount, id: \.self) { index in
                    HStack(alignment: .top) {
                        Text(home.count > index ? sanitized(home[index]) : "")
                            .font(.caption2)
                            .foregroundColor(goalTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(away.count > index ? sanitized(away[index]) : "")
                            .font(.caption2)
                            .foregroundColor(goalTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }
}

private struct NoMatchView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape().fill(Color("WidgetBackground", bundle: .main))
            VStack(spacing: 8) {
                Image(systemName: "sportscourt")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No live matches")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private func sanitized(_ text: String) -> String {
    guard let range = text.range(of: "(Ast.") else { return text }
    var result = text
    var lower = range.lowerBound
    if lower > result.startIndex {
        let before = result.index(before: lower)
        if result[before].isWhitespace { lower = before }
    }

    if let end = result[range.lowerBound...].firstIndex(of: ")") {
        result.removeSubrange(lower...end)
    } else {
        result.removeSubrange(lower..<result.endIndex)
    }

    while result.contains("  ") {
        result = result.replacingOccurrences(of: "  ", with: " ")
    }
    return result.trimmingCharacters(in: .whitespaces)
}

extension LiveMatchWidgetSnapshot {
    var isLive: Bool {
        ["LIVE", "1H", "2H", "ET", "P"].contains(status.uppercased())
    }

    var isFinished: Bool {
        let finished: Set<String> = ["FT", "AET", "PEN", "AWD", "WO", "ABD", "CANC", "SUSP"]
        return finished.contains(status.uppercased())
    }

    var statusLabel: String {
        switch status.uppercased() {
        case "1H": return "1st Half"
        case "HT": return "Half Time"
        case "2H": return "2nd Half"
        case "ET": return "Extra Time"
        case "P": return "Penalties"
        case "FT": return "Full Time"
        default: return status.uppercased()
        }
    }

    func timerText(reference: Date) -> String {
        let total = max(elapsedSeconds + Int(reference.timeIntervalSince(lastUpdated)), 0)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func updatedText(reference: Date) -> String {
        let seconds = Int(reference.timeIntervalSince(lastUpdated))
        if seconds < 60 { return "Updated just now" }
        if seconds < 3600 { return "Updated \(seconds / 60)m ago" }
        return "Updated \(seconds / 3600)h ago"
    }

    var kickoffDate: Date? {
        guard let ts = fixtureTimestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    static let sample = LiveMatchWidgetSnapshot(
        fixtureID: 9876,
        homeTeam: "Morocco",
        awayTeam: "Nigeria",
        competition: "AFCON 2025",
        homeScore: 2,
        awayScore: 1,
        status: "2H",
        elapsedSeconds: 68 * 60,
        lastUpdated: Date().addingTimeInterval(-120),
        homeLogoPath: nil,
        awayLogoPath: nil,
        homeGoalEvents: ["18' En-Nesyri", "63' Ziyech"],
        awayGoalEvents: ["55' Osimhen"],
        fixtureTimestamp: Int(Date().addingTimeInterval(-600).timeIntervalSince1970)
    )
}

final class AppGroupMatchStore: Sendable {
    static let shared = AppGroupMatchStore()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let snapshotsFileName = "live_match_snapshots.json"
    private let legacyFileName = "live_match_snapshot.json"

    private init() {}

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)
    }

    private var snapshotsURL: URL? {
        containerURL?.appendingPathComponent(snapshotsFileName)
    }

    private var legacyURL: URL? {
        containerURL?.appendingPathComponent(legacyFileName)
    }

    func snapshots() -> [LiveMatchWidgetSnapshot] {
        if let url = snapshotsURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? decoder.decode([LiveMatchWidgetSnapshot].self, from: data) {
            let sorted = decoded.sorted { $0.lastUpdated > $1.lastUpdated }
            return Array(sorted.prefix(20))
        }

        if let legacyURL,
           let data = try? Data(contentsOf: legacyURL),
           let snapshot = try? decoder.decode(LiveMatchWidgetSnapshot.self, from: data) {
            return [snapshot]
        }

        return []
    }

    func snapshot(for fixtureID: Int32?) -> LiveMatchWidgetSnapshot? {
        let all = snapshots()
        guard let fixtureID else {
            return all.first
        }
        return all.first { $0.fixtureID == fixtureID } ?? all.first
    }

    func latestSnapshot() -> LiveMatchWidgetSnapshot? {
        snapshot(for: nil)
    }
}

