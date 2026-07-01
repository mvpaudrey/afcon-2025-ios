import WidgetKit
import SwiftUI
import TournamentKit

struct LiveScoreScheduleEntry: TimelineEntry {
    let date: Date
    let matches: [LiveMatchWidgetSnapshot]
}

struct LiveScoreScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> LiveScoreScheduleEntry {
        print("📅 Schedule Widget placeholder() called")
        return LiveScoreScheduleEntry(date: Date(), matches: [.sample, .finishedSample, .upcomingSample])
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveScoreScheduleEntry) -> Void) {
        print("📅 Schedule Widget getSnapshot() called")
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveScoreScheduleEntry>) -> Void) {
        print("📅📅📅 SCHEDULE WIDGET TIMELINE CALLED 📅📅📅")
        let matches = prioritizedMatches()
        print("📅 Schedule Widget - Total matches to display: \(matches.count)")
        let entry = LiveScoreScheduleEntry(date: Date(), matches: matches)
        let refresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func prioritizedMatches() -> [LiveMatchWidgetSnapshot] {
        let allMatches = AppGroupMatchStore.shared.snapshots()
        print("📅 Schedule Widget - Found \(allMatches.count) total snapshots")

        let calendar = Calendar(identifier: .gregorian)
        let today = Date()

        let todaysMatches = allMatches.filter { snapshot in
            if let kickoff = snapshot.kickoffDate {
                return calendar.isDate(kickoff, inSameDayAs: today)
            }
            return calendar.isDate(snapshot.lastUpdated, inSameDayAs: today)
        }
        print("📅 Schedule Widget - \(todaysMatches.count) matches today")

        let live = todaysMatches.filter { $0.isLive }
        let upcoming = todaysMatches.filter { !$0.isLive && !$0.isFinished }
            .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }
        let finished = todaysMatches.filter { $0.isFinished }
            .sorted { $0.lastUpdated > $1.lastUpdated }

        print("📅 Schedule Widget - Live: \(live.count), Upcoming: \(upcoming.count), Finished: \(finished.count)")

        return Array((live + upcoming + finished).prefix(6))
    }
}

struct LiveScoreScheduleWidget: Widget {
    let kind = "LiveScoreScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LiveScoreScheduleProvider()) { entry in
            LiveScoreScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("Match Schedule")
        .description("Track live, upcoming, and finished matches at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct LiveScoreScheduleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LiveScoreScheduleEntry

    var body: some View {
        if entry.matches.isEmpty {
            NoMatchScheduleView()
        } else {
            switch family {
            case .systemLarge:
                ScheduleListView(matches: Array(entry.matches.prefix(6)))
            default:
                ScheduleMediumView(matches: Array(entry.matches.prefix(2)))
            }
        }
    }
}

// Medium widget: 2 rows filling the full height
private struct ScheduleMediumView: View {
    let matches: [LiveMatchWidgetSnapshot]

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element.fixtureID) { index, match in
                    ScheduleMediumRow(match: match)
                        .frame(maxHeight: .infinity)
                    if index < matches.count - 1 {
                        Divider().opacity(0.2)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct ScheduleListView: View {
    let matches: [LiveMatchWidgetSnapshot]

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color("WidgetBackground", bundle: .main).opacity(0.95))

            VStack(alignment: .leading, spacing: 10) {
                Text(scheduleWidgetTitle())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                    ForEach(Array(matches.enumerated()), id: \.element.fixtureID) { index, match in
                        ScheduleRow(match: match)

                        if index < matches.count - 1 {
                            GridRow {
                                Divider()
                                    .gridCellColumns(3)
                                    .overlay(Color.white.opacity(0.1))
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
    }
}

// MARK: - Shared helpers

private func scheduleWidgetTitle() -> String {
    let lang = Locale.current.language.languageCode?.identifier ?? "en"
    switch lang {
    case "fr": return "Programme"
    case "ar": return "جدول المباريات"
    default:   return "Match Schedule"
    }
}

private func matchStatusInfo(for match: LiveMatchWidgetSnapshot) -> (String, Color) {
    if match.isLive { return ("LIVE", .green) }
    if match.isFinished { return ("FT", .gray) }
    if let kickoff = match.kickoffDate, kickoff > Date() { return ("SOON", .blue) }
    return ("NS", .gray)
}

private func matchStatusBadgeView(for match: LiveMatchWidgetSnapshot) -> some View {
    let (label, color) = matchStatusInfo(for: match)
    return Text(label)
        .font(.system(size: 10, weight: .bold))
        .lineLimit(1)
        .frame(minWidth: 38, alignment: .center)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 6))
}

private struct TeamScoreLine: View {
    let name: String
    let logoPath: String?
    let score: Int
    let showScore: Bool

    var body: some View {
        HStack(spacing: 6) {
            LogoImageView(path: logoPath, size: CGSize(width: 20, height: 20), useCircle: true)
            Text(localizedTeamName(name))
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 4)
            if showScore {
                Text("\(score)")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.primary)
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.systemGray3))
            }
        }
    }
}

// MARK: - Row layouts

private struct ScheduleMediumRow: View {
    let match: LiveMatchWidgetSnapshot
    private var showScore: Bool { match.isLive || match.isFinished }

    var body: some View {
        HStack(spacing: 8) {
            matchStatusBadgeView(for: match)

            VStack(alignment: .leading, spacing: 5) {
                TeamScoreLine(name: match.homeTeam, logoPath: match.homeLogoPath,
                              score: match.homeScore, showScore: showScore)
                TeamScoreLine(name: match.awayTeam, logoPath: match.awayLogoPath,
                              score: match.awayScore, showScore: showScore)
            }

            kickoffOrTimer
        }
    }

    @ViewBuilder private var kickoffOrTimer: some View {
        if match.isLive {
            LiveMatchTimerLabel(match: match)
        } else if !match.isFinished, let kickoff = match.kickoffDate, kickoff > Date() {
            VStack(alignment: .trailing, spacing: 1) {
                Text(kickoff, style: .time)
                    .font(.system(size: 11, weight: .semibold))
                Text(kickoff, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct ScheduleRow: View {
    let match: LiveMatchWidgetSnapshot
    private var showScore: Bool { match.isLive || match.isFinished }

    var body: some View {
        GridRow(alignment: .center) {
            matchStatusBadgeView(for: match)

            VStack(alignment: .leading, spacing: 5) {
                TeamScoreLine(name: match.homeTeam, logoPath: match.homeLogoPath,
                              score: match.homeScore, showScore: showScore)
                TeamScoreLine(name: match.awayTeam, logoPath: match.awayLogoPath,
                              score: match.awayScore, showScore: showScore)
            }

            kickoffOrTimer
        }
    }

    @ViewBuilder private var kickoffOrTimer: some View {
        if match.isLive {
            LiveMatchTimerLabel(match: match)
        } else if !match.isFinished, let kickoff = match.kickoffDate, kickoff > Date() {
            VStack(alignment: .trailing, spacing: 2) {
                Text(kickoff, style: .time)
                    .font(.system(size: 11, weight: .semibold))
                Text(kickoff, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        } else {
            EmptyView()
        }
    }
}

private struct NoMatchScheduleView: View {
    var body: some View {
        ZStack {
            ContainerRelativeShape().fill(Color("WidgetBackground", bundle: .main))
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No matches scheduled")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct LiveMatchTimerLabel: View {
    let match: LiveMatchWidgetSnapshot

    private var elapsedMinute: Int { match.elapsedSeconds / 60 }
    private var secondsAnchor: Date {
        match.lastUpdated.addingTimeInterval(-TimeInterval(match.elapsedSeconds % 60))
    }

    var body: some View {
        let size: CGFloat = 10
        let dw = size * 0.62
        let cw = size * 0.35
        HStack(spacing: 0) {
            Text("\(elapsedMinute):")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(.green)
                .monospacedDigit()
            Color.clear
                .frame(width: dw * 2, height: size * 1.3)
                .overlay(
                    Text(secondsAnchor, style: .timer)
                        .font(.system(size: size, weight: .bold))
                        .foregroundColor(.green)
                        .monospacedDigit()
                        .fixedSize()
                        .offset(x: -(dw + cw)),
                    alignment: .leading
                )
                .clipped()
        }
    }
}

private extension LiveMatchWidgetSnapshot {
    static let finishedSample = LiveMatchWidgetSnapshot(
        fixtureID: 2222,
        homeTeam: "Spain",
        awayTeam: "France",
        competition: "Nations League",
        homeScore: 1,
        awayScore: 0,
        status: "FT",
        elapsedSeconds: 90 * 60,
        lastUpdated: Date().addingTimeInterval(-600),
        homeLogoPath: nil,
        awayLogoPath: nil,
        homeGoalEvents: ["73' Morata"],
        awayGoalEvents: [],
        fixtureTimestamp: Int(Date().addingTimeInterval(-3600).timeIntervalSince1970)
    )

    static let upcomingSample = LiveMatchWidgetSnapshot(
        fixtureID: 3333,
        homeTeam: "Brazil",
        awayTeam: "Argentina",
        competition: "World Cup Qualifiers",
        homeScore: 0,
        awayScore: 0,
        status: "NS",
        elapsedSeconds: 0,
        lastUpdated: Date(),
        homeLogoPath: nil,
        awayLogoPath: nil,
        homeGoalEvents: [],
        awayGoalEvents: [],
        fixtureTimestamp: Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
    )
}
