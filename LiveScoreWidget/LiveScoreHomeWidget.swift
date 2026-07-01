import WidgetKit
import SwiftUI
import TournamentKit

struct LiveScoreHomeEntry: TimelineEntry {
    let date: Date
    let match: LiveMatchWidgetSnapshot?
    let accentColorName: String
    let secondaryColorName: String
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
        let config = loadWidgetTournamentConfig()
        return LiveScoreHomeEntry(date: Date(), match: .sample, accentColorName: config.accentColorName, secondaryColorName: config.secondaryColorName)
    }

    func snapshot(for configuration: SelectMatchIntent, in context: Context) async -> LiveScoreHomeEntry {
        print("🔵 Widget snapshot() called - isPreview: \(context.isPreview)")
        let config = loadWidgetTournamentConfig()
        if context.isPreview {
            return LiveScoreHomeEntry(date: Date(), match: .sample, accentColorName: config.accentColorName, secondaryColorName: config.secondaryColorName)
        }
        return LiveScoreHomeEntry(date: Date(), match: match(for: configuration), accentColorName: config.accentColorName, secondaryColorName: config.secondaryColorName)
    }

    func timeline(for configuration: SelectMatchIntent, in context: Context) async -> Timeline<LiveScoreHomeEntry> {
        print("🔵🔵🔵 WIDGET TIMELINE CALLED 🔵🔵🔵")
        let config = loadWidgetTournamentConfig()
        let matchData = match(for: configuration)
        print("🔵 Widget Timeline - Match data: \(matchData != nil ? "Found" : "nil")")
        let entry = LiveScoreHomeEntry(date: Date(), match: matchData, accentColorName: config.accentColorName, secondaryColorName: config.secondaryColorName)
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
                LargeLiveScoreView(match: match, date: entry.date, accentColorName: entry.accentColorName, secondaryColorName: entry.secondaryColorName)
            default:
                MediumLiveScoreView(match: match, date: entry.date, accentColorName: entry.accentColorName, secondaryColorName: entry.secondaryColorName)
            }
        } else {
            NoMatchView()
        }
    }
}

private struct MediumLiveScoreView: View {
    let match: LiveMatchWidgetSnapshot
    let date: Date
    let accentColorName: String
    let secondaryColorName: String

    private var isHalftime: Bool { match.status.uppercased() == "HT" }

    private var badgeColor: Color {
        isHalftime ? .orange : (match.isLive ? Color(accentColorName) : Color(.systemGray4))
    }

    private var isPenalty: Bool { match.status.uppercased() == "P" }
    private var isAET: Bool { match.status.uppercased() == "AET" }
    private var isPEN: Bool { match.status.uppercased() == "PEN" }
    private var hasGoalEvents: Bool { !match.homeGoalEvents.isEmpty || !match.awayGoalEvents.isEmpty }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        if match.isLive || isPenalty {
                            Circle().fill(Color.white).frame(width: 5, height: 5)
                        } else if isHalftime {
                            Image(systemName: "pause.circle.fill").font(.system(size: 9))
                        }
                        Text(match.statusLabel)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(badgeColor)
                    .foregroundColor(match.isLive || isHalftime || isPenalty ? .white : .secondary)
                    .clipShape(Capsule())

                    Text(match.competition)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)

                    if match.isLive || isPenalty {
                        MatchTimerView(match: match, fontSize: 11)
                    }
                }
                .padding(.bottom, 8)

                // Score rows — each fills equal vertical space
                TeamScoreRow(
                    logoPath: match.homeLogoPath,
                    name: localizedTeamName(match.homeTeam),
                    score: match.homeScore,
                    scoreColor: Color(accentColorName),
                    scoreSize: 28
                )
                .frame(maxHeight: .infinity)

                Divider().opacity(0.2)

                TeamScoreRow(
                    logoPath: match.awayLogoPath,
                    name: localizedTeamName(match.awayTeam),
                    score: match.awayScore,
                    scoreColor: Color(secondaryColorName),
                    scoreSize: 28
                )
                .frame(maxHeight: .infinity)

                // Extra info row
                if isAET || isPEN || hasGoalEvents {
                    Divider().opacity(0.15).padding(.top, 2)
                    extraInfoView.padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private var extraInfoView: some View {
        if hasGoalEvents {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(grouped(match.homeGoalEvents).prefix(3), id: \.player) { g in
                        Text("⚽ \(g.minutes) \(g.player)")
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 1) {
                    ForEach(grouped(match.awayGoalEvents).prefix(3), id: \.player) { g in
                        Text("\(g.minutes) \(g.player) ⚽")
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        } else {
            Text(isAET ? "After Extra Time" : "Decided on Penalties")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.orange)
        }
    }
}

// Shows "MM:SS" at any minute by rendering the minute as static text and clipping
// the "0:" prefix from Text(.timer), which always shows "0:SS" when anchored to
// the start of the current elapsed minute (< 60 s ago).
private struct MatchTimerView: View {
    let match: LiveMatchWidgetSnapshot
    let fontSize: CGFloat

    private var elapsedMinute: Int { match.elapsedSeconds / 60 }

    // Anchor to start of the current elapsed minute → .timer shows "0:SS"
    private var secondsAnchor: Date {
        match.lastUpdated.addingTimeInterval(-TimeInterval(match.elapsedSeconds % 60))
    }

    // SF Mono digit metrics used to clip the "0:" prefix
    private var digitWidth: CGFloat { fontSize * 0.62 }
    private var colonWidth: CGFloat { fontSize * 0.35 }

    var body: some View {
        HStack(spacing: 0) {
            Text("\(elapsedMinute):")
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(.green)
                .monospacedDigit()

            // Clip container sized for "SS" only; shifts the "0:SS" text left so "0:" is outside bounds
            Color.clear
                .frame(width: digitWidth * 2, height: fontSize * 1.3)
                .overlay(
                    Text(secondsAnchor, style: .timer)
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundColor(.green)
                        .monospacedDigit()
                        .fixedSize()
                        .offset(x: -(digitWidth + colonWidth)),
                    alignment: .leading
                )
                .clipped()
        }
    }
}

// Groups goal events by player: ["53' Barcola", "74' Mbappe", "88' Mbappe"]
// → [(player:"Mbappe", minutes:"74', 88'"), (player:"Barcola", minutes:"53'")]
private func grouped(_ events: [String]) -> [(player: String, minutes: String)] {
    var order: [String] = []
    var map: [String: [String]] = [:]
    for raw in events {
        let text = sanitized(raw)
        let parts = text.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let minute = String(parts[0])
        let player = String(parts[1])
        if map[player] == nil {
            order.append(player)
            map[player] = []
        }
        map[player]!.append(minute)
    }
    return order.compactMap { p in
        guard let mins = map[p] else { return nil }
        return (player: p, minutes: mins.joined(separator: ", "))
    }
}

private struct LargeLiveScoreView: View {
    let match: LiveMatchWidgetSnapshot
    let date: Date
    let accentColorName: String
    let secondaryColorName: String

    private var isHalftime: Bool { match.status.uppercased() == "HT" }

    private var badgeColor: Color {
        isHalftime ? .orange : (match.isLive ? Color(accentColorName) : Color(.systemGray4))
    }

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        if match.isLive {
                            Circle().fill(Color.white).frame(width: 5, height: 5)
                        } else if isHalftime {
                            Image(systemName: "pause.circle.fill").font(.system(size: 9))
                        }
                        Text(match.statusLabel)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor)
                    .foregroundColor(match.isLive || isHalftime ? .white : .secondary)
                    .clipShape(Capsule())

                    Text(match.competition)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if match.isLive {
                        MatchTimerView(match: match, fontSize: 12)
                    }
                }

                // Two score rows (larger)
                VStack(spacing: 10) {
                    TeamScoreRow(
                        logoPath: match.homeLogoPath,
                        name: localizedTeamName(match.homeTeam),
                        score: match.homeScore,
                        scoreColor: Color(accentColorName),
                        scoreSize: 38
                    )
                    Divider().opacity(0.25)
                    TeamScoreRow(
                        logoPath: match.awayLogoPath,
                        name: localizedTeamName(match.awayTeam),
                        score: match.awayScore,
                        scoreColor: Color(secondaryColorName),
                        scoreSize: 38
                    )
                }

                // Goals
                if !match.homeGoalEvents.isEmpty || !match.awayGoalEvents.isEmpty {
                    Divider().opacity(0.3)
                    GoalListView(home: match.homeGoalEvents, away: match.awayGoalEvents)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct TeamScoreRow: View {
    let logoPath: String?
    let name: String
    let score: Int
    let scoreColor: Color
    var scoreSize: CGFloat = 28

    private var logoSize: CGFloat { scoreSize < 34 ? 26 : 34 }

    var body: some View {
        HStack(spacing: 10) {
            LogoImageView(
                path: logoPath,
                size: CGSize(width: logoSize, height: logoSize),
                useCircle: true
            )
            Text(name)
                .font(.system(size: scoreSize < 34 ? 14 : 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            Text("\(score)")
                .font(.system(size: scoreSize, weight: .black))
                .foregroundColor(scoreColor)
                .monospacedDigit()
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

    var timerStartDate: Date {
        lastUpdated.addingTimeInterval(-TimeInterval(elapsedSeconds))
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

