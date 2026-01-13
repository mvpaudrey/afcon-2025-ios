import WidgetKit
import SwiftUI

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
                ScheduleListView(matches: Array(entry.matches.prefix(3)))
            }
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
                Text("Match Schedule")
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

private struct ScheduleRow: View {
    let match: LiveMatchWidgetSnapshot

    var body: some View {
        GridRow(alignment: .center) {
            // Column 1: Status badge (auto-sized, aligns all badges)
            statusBadge

            // Column 2: Team names (auto-sized, all team columns align)
            VStack(alignment: .leading, spacing: 6) {
                TeamLine(name: match.homeTeam, logoPath: match.homeLogoPath)
                TeamLine(name: match.awayTeam, logoPath: match.awayLogoPath)
            }

            // Column 3: Score/Time (auto-sized, trailing alignment)
            scoreAndTimerSection
        }
    }

    private var statusBadge: some View {
        let (label, color) = statusLabelAndColor(for: match)
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func statusLabelAndColor(for match: LiveMatchWidgetSnapshot) -> (String, Color) {
        if match.isLive {
            return ("LIVE", .green)
        } else if match.isFinished {
            return ("FT", .gray)
        } else {
            return ("SOON", .blue)
        }
    }

    private var scoreAndTimerSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if match.isLive {
                Text("\(match.homeScore) - \(match.awayScore)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .monospacedDigit()

                LiveMatchTimerLabel(match: match)
            } else if match.isFinished {
                Text("\(match.homeScore) - \(match.awayScore)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .monospacedDigit()

                Text("FT")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            } else if let kickoff = match.kickoffDate, kickoff > Date() {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(kickoff, style: .time)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(kickoff, format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(minWidth: 50, alignment: .trailing)
            } else {
                Text(match.statusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 60, alignment: .trailing)
    }

    private struct TeamLine: View {
        let name: String
        let logoPath: String?

        var body: some View {
            HStack(spacing: 6) {
                LogoImageView(path: logoPath, size: CGSize(width: 22, height: 22), useCircle: true)
                Text(localizedTeamName(name))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Text(match.timerText(reference: timeline.date))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green)
                .monospacedDigit()
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
