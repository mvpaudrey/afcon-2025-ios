import WidgetKit
import SwiftUI

struct LiveScoreHomeEntry: TimelineEntry {
    let date: Date
    let match: LiveMatchWidgetSnapshot?
}

struct LiveScoreHomeProvider: AppIntentTimelineProvider {
    init() {
        print("🔵🔵🔵 WIDGET PROVIDER INIT 🔵🔵🔵")
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.cheulah.afcon") {
            print("🔵 Widget Init - App Group Container: \(containerURL.path)")
        } else {
            print("❌❌❌ Widget Init - NO APP GROUP ACCESS ❌❌❌")
        }
    }

    func placeholder(in context: Context) -> LiveScoreHomeEntry {
        print("🔵 Widget placeholder() called")
        return LiveScoreHomeEntry(date: Date(), match: .sample)
    }

    func snapshot(for configuration: SelectMatchIntent, in context: Context) async -> LiveScoreHomeEntry {
        print("🔵 Widget snapshot() called - isPreview: \(context.isPreview)")
        if context.isPreview {
            return LiveScoreHomeEntry(date: Date(), match: .sample)
        }
        return LiveScoreHomeEntry(date: Date(), match: match(for: configuration))
    }

    func timeline(for configuration: SelectMatchIntent, in context: Context) async -> Timeline<LiveScoreHomeEntry> {
        print("🔵🔵🔵 WIDGET TIMELINE CALLED 🔵🔵🔵")
        let matchData = match(for: configuration)
        print("🔵 Widget Timeline - Match data: \(matchData != nil ? "Found" : "nil")")
        let entry = LiveScoreHomeEntry(date: Date(), match: matchData)
        let refresh = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func match(for configuration: SelectMatchIntent) -> LiveMatchWidgetSnapshot? {
        let snapshots = AppGroupMatchStore.shared.snapshots()
        print("🔵 Widget - Found \(snapshots.count) snapshots")

        if let selected = configuration.match {
            let match = AppGroupMatchStore.shared.snapshot(for: selected.fixtureID)
            print("🔵 Widget - Selected match \(selected.fixtureID): \(match != nil ? "Found" : "nil")")
            return match
        }

        let firstMatch = snapshots.first
        print("🔵 Widget - First match: \(firstMatch?.homeTeam ?? "nil") vs \(firstMatch?.awayTeam ?? "nil")")
        return firstMatch
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

    private var isHalftime: Bool {
        match.status.uppercased() == "HT"
    }

    private var statusBadgeColor: Color {
        if isHalftime {
            return .orange
        } else if match.isLive {
            return Color("moroccoRed")
        } else {
            return Color(.systemGray5)
        }
    }

    private var statusBadgeTextColor: Color {
        (match.isLive || isHalftime) ? .white : .secondary
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(spacing: 12) {
                // Header matching MatchCard
                HStack {
                    HStack(spacing: 4) {
                        if match.isLive {
                            Image(systemName: "clock")
                                .font(.caption2)
                        } else if isHalftime {
                            Image(systemName: "pause.circle.fill")
                                .font(.caption2)
                        }
                        Text(match.statusLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBadgeColor)
                    .foregroundColor(statusBadgeTextColor)
                    .cornerRadius(12)

                    Spacer()

                    Text(match.competition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Teams and Scores matching MatchCard layout
                HStack(alignment: .center, spacing: 8) {
                    // Home Team
                    HStack(spacing: 8) {
                        LogoImageView(path: match.homeLogoPath, size: CGSize(width: 40, height: 40), useCircle: true)

                        Text(localizedTeamName(match.homeTeam))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)

                    // Score
                    HStack(spacing: 12) {
                        Text("\(match.homeScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("moroccoRed"))

                        Text("-")
                            .foregroundColor(.secondary)

                        Text("\(match.awayScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("moroccoGreen"))
                    }
                    .fixedSize()

                    // Away Team
                    HStack(spacing: 8) {
                        Text(localizedTeamName(match.awayTeam))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        LogoImageView(path: match.awayLogoPath, size: CGSize(width: 40, height: 40), useCircle: true)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Timer/Status
                if match.isLive {
                    Text(match.timerText(reference: date))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .monospacedDigit()
                }
            }
            .padding()
        }
    }
}

private struct LargeLiveScoreView: View {
    let match: LiveMatchWidgetSnapshot
    let date: Date

    private var isHalftime: Bool {
        match.status.uppercased() == "HT"
    }

    private var statusBadgeColor: Color {
        if isHalftime {
            return .orange
        } else if match.isLive {
            return Color("moroccoRed")
        } else {
            return Color(.systemGray5)
        }
    }

    private var statusBadgeTextColor: Color {
        (match.isLive || isHalftime) ? .white : .secondary
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(spacing: 12) {
                // Header matching MatchCard
                HStack {
                    HStack(spacing: 4) {
                        if match.isLive {
                            Image(systemName: "clock")
                                .font(.caption2)
                        } else if isHalftime {
                            Image(systemName: "pause.circle.fill")
                                .font(.caption2)
                        }
                        Text(match.statusLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBadgeColor)
                    .foregroundColor(statusBadgeTextColor)
                    .cornerRadius(12)

                    Spacer()

                    Text(match.competition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Teams and Scores matching MatchCard layout
                HStack(alignment: .center, spacing: 8) {
                    // Home Team
                    HStack(spacing: 12) {
                        LogoImageView(path: match.homeLogoPath, size: CGSize(width: 50, height: 50), useCircle: true)

                        Text(localizedTeamName(match.homeTeam))
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)

                    // Score
                    HStack(spacing: 16) {
                        Text("\(match.homeScore)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("moroccoRed"))

                        Text("-")
                            .font(.title)
                            .foregroundColor(.secondary)

                        Text("\(match.awayScore)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("moroccoGreen"))
                    }
                    .fixedSize()

                    // Away Team
                    HStack(spacing: 12) {
                        Text(localizedTeamName(match.awayTeam))
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        LogoImageView(path: match.awayLogoPath, size: CGSize(width: 50, height: 50), useCircle: true)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Timer
                if match.isLive {
                    Text(match.timerText(reference: date))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .monospacedDigit()
                }

                // Goals Section
                if !match.homeGoalEvents.isEmpty || !match.awayGoalEvents.isEmpty {
                    Divider()

                    GoalListView(home: match.homeGoalEvents, away: match.awayGoalEvents)
                }
            }
            .padding()
        }
    }
}

private struct GoalListView: View {
    let home: [String]
    let away: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Goals")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(home.count + away.count) goal\(home.count + away.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ForEach(home, id: \.self) { goal in
                HStack(spacing: 6) {
                    Text(sanitized(goal))
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()
                }
            }

            ForEach(away, id: \.self) { goal in
                HStack(spacing: 6) {
                    Spacer()

                    Text(sanitized(goal))
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .lineLimit(1)
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
        case "BT": return "Break Time"
        case "P": return "Penalty In Progress"
        case "FT": return "Full Time"
        case "AET": return "After Extra Time"
        case "PEN": return "Penalty Shootout"
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
        print("🔵 AppGroupMatchStore - Container URL: \(containerURL?.path ?? "nil")")
        print("🔵 AppGroupMatchStore - Snapshots URL: \(snapshotsURL?.path ?? "nil")")

        if let url = snapshotsURL {
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            print("🔵 AppGroupMatchStore - File exists: \(fileExists)")

            if let data = try? Data(contentsOf: url) {
                print("🔵 AppGroupMatchStore - Data loaded: \(data.count) bytes")

                if let decoded = try? decoder.decode([LiveMatchWidgetSnapshot].self, from: data) {
                    print("🔵 AppGroupMatchStore - Decoded \(decoded.count) snapshots")
                    let sorted = decoded.sorted { $0.lastUpdated > $1.lastUpdated }
                    return Array(sorted.prefix(20))
                } else {
                    print("❌ AppGroupMatchStore - Failed to decode data")
                }
            } else {
                print("❌ AppGroupMatchStore - Failed to load data from \(url.path)")
            }
        }

        if let legacyURL {
            print("🔵 AppGroupMatchStore - Checking legacy URL: \(legacyURL.path)")
            if let data = try? Data(contentsOf: legacyURL),
               let snapshot = try? decoder.decode(LiveMatchWidgetSnapshot.self, from: data) {
                print("🔵 AppGroupMatchStore - Found legacy snapshot")
                return [snapshot]
            }
        }

        print("❌ AppGroupMatchStore - No snapshots found, returning empty array")
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

