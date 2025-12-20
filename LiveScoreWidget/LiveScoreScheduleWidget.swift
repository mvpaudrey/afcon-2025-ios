import WidgetKit
import SwiftUI

struct LiveScoreScheduleEntry: TimelineEntry {
    let date: Date
    let matches: [LiveMatchWidgetSnapshot]
}

struct LiveScoreScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> LiveScoreScheduleEntry {
        LiveScoreScheduleEntry(date: Date(), matches: [.sample, .finishedSample, .upcomingSample])
    }

    func getSnapshot(in context: Context, completion: @escaping (LiveScoreScheduleEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiveScoreScheduleEntry>) -> Void) {
        let matches = prioritizedMatches()
        let entry = LiveScoreScheduleEntry(date: Date(), matches: matches)
        let refresh = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func prioritizedMatches() -> [LiveMatchWidgetSnapshot] {
        let allMatches = AppGroupMatchStore.shared.snapshots()
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()

        let todaysMatches = allMatches.filter { snapshot in
            if let kickoff = snapshot.kickoffDate {
                return calendar.isDate(kickoff, inSameDayAs: today)
            }
            return calendar.isDate(snapshot.lastUpdated, inSameDayAs: today)
        }

        let live = todaysMatches.filter { $0.isLive }
        let upcoming = todaysMatches.filter { !$0.isLive && !$0.isFinished }
            .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }
        let finished = todaysMatches.filter { $0.isFinished }
            .sorted { $0.lastUpdated > $1.lastUpdated }

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

                ForEach(Array(matches.enumerated()), id: \.element.fixtureID) { index, match in
                    ScheduleRow(match: match)
                    if index < matches.count - 1 {
                        Divider().overlay(Color.white.opacity(0.1))
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
        HStack(alignment: .center, spacing: 10) {
            statusBadge

            VStack(alignment: .leading, spacing: 6) {
                TeamLine(name: match.homeTeam, logoPath: match.homeLogoPath)
                TeamLine(name: match.awayTeam, logoPath: match.awayLogoPath)
            }

            Spacer()

            scoreAndTimerSection
        }
    }

    private var statusBadge: some View {
        let (label, color) = statusLabelAndColor(for: match)
        return Text(label)
            .font(.caption2)
            .fontWeight(.bold)
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
            return ("UPCOMING", .blue)
        }
    }

    private var scoreAndTimerSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if match.isLive {
                Text("\(match.homeScore) - \(match.awayScore)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .monospacedDigit()

                LiveMatchTimerLabel(match: match)
            } else if match.isFinished {
                Text("\(match.homeScore) - \(match.awayScore)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .monospacedDigit()

                Text("FT")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else if let kickoff = match.kickoffDate, kickoff > Date() {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(kickoff, style: .time)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(kickoff, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(match.statusLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
    }

    private struct TeamLine: View {
        let name: String
        let logoPath: String?

        var body: some View {
            HStack(spacing: 6) {
                LogoImageView(path: logoPath, size: CGSize(width: 22, height: 22))
                Text(name)
                    .font(.callout)
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
                .font(.caption)
                .fontWeight(.bold)
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
