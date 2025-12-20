import SwiftUI
import AFCONClient

struct QuickStatsBarLive: View {
    @State private var viewModel = QuickStatsViewModel()

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    // Current live match or latest result
                    if let liveMatch = viewModel.liveMatch {
                        HStack(spacing: 6) {
                            // Home team
                            if let homeFlag = TeamFlagMapper.flagAssetName(for: liveMatch.homeTeamId) {
                                Image(homeFlag)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                            }
                            Text(liveMatch.homeTeam)
                                .fontWeight(.semibold)
                                .lineLimit(1)

                            Text("\(liveMatch.homeScore)-\(liveMatch.awayScore)")
                                .fontWeight(.bold)

                            // Away team
                            Text(liveMatch.awayTeam)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            if let awayFlag = TeamFlagMapper.flagAssetName(for: liveMatch.awayTeamId) {
                                Image(awayFlag)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 20, height: 20)
                                    .clipShape(Circle())
                            }

                            Text(liveMatch.minute)
                                .fontWeight(.medium)
                                .opacity(0.9)
                        }
                        .font(.subheadline)
                    } else if viewModel.isLoading {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading...")
                                .font(.caption)
                                .opacity(0.7)
                        }
                    } else {
                        // Show next match if no live match
                        if let nextMatch = viewModel.nextMatch {
                            HStack(spacing: 6) {
                                // Home team
                                if let homeFlag = TeamFlagMapper.flagAssetName(for: nextMatch.homeTeamId) {
                                    Image(homeFlag)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
                                }
                                Text(nextMatch.homeTeam)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                Text("vs")
                                    .fontWeight(.medium)
                                    .opacity(0.8)

                                // Away team
                                Text(nextMatch.awayTeam)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                if let awayFlag = TeamFlagMapper.flagAssetName(for: nextMatch.awayTeamId) {
                                    Image(awayFlag)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 20, height: 20)
                                        .clipShape(Circle())
                                }

                                Text("•")
                                    .opacity(0.5)
                                Text(nextMatch.dateTime)
                                    .fontWeight(.medium)
                                    .opacity(0.9)
                            }
                            .font(.subheadline)
                        } else {
                            HStack(spacing: 4) {
                                Text("No matches scheduled")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                        }
                    }
                }

                Spacer()

                Text(viewModel.statusText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .opacity(0.8)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color("moroccoRed"), Color("moroccoGreen")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - ViewModel
@Observable
final class QuickStatsViewModel {
    var liveMatch: LiveMatchInfo?
    var nextMatch: UpcomingMatchInfo?
    var isLoading = false
    var statusText = "Live updates"

    private var afconService: AFCONServiceWrapper?
    private var updateTask: Task<Void, Never>?
    private var scheduleTask: Task<Void, Never>?

    // League configuration - African Cup of Nations
    private let leagueID: Int32 = 6
    private let season: Int32 = 2025

    init() {
        self.afconService = AFCONServiceWrapper.shared
    }

    @MainActor
    func loadData() async {
        isLoading = true

        // Fetch live matches and upcoming matches in parallel
        async let liveFixtures = fetchLiveFixtures()
        async let upcomingFixtures = fetchUpcomingFixtures()

        // Wait for both to complete
        let (live, upcoming) = await (liveFixtures, upcomingFixtures)

        // Process live match
        if let firstLive = live?.first {
            liveMatch = LiveMatchInfo(
                homeTeam: firstLive.teams.home.name,
                awayTeam: firstLive.teams.away.name,
                homeTeamId: Int(firstLive.teams.home.id),
                awayTeamId: Int(firstLive.teams.away.id),
                homeScore: Int(firstLive.goals.home),
                awayScore: Int(firstLive.goals.away),
                minute: "\(firstLive.status.elapsed)'"
            )
            statusText = "Live now"
        }

        // Process next upcoming match
        if let firstUpcoming = upcoming?.first {
            let date = Date(timeIntervalSince1970: TimeInterval(firstUpcoming.timestamp))
            nextMatch = UpcomingMatchInfo(
                homeTeam: firstUpcoming.teams.home.name,
                awayTeam: firstUpcoming.teams.away.name,
                homeTeamId: Int(firstUpcoming.teams.home.id),
                awayTeamId: Int(firstUpcoming.teams.away.id),
                dateTime: formatMatchDate(date)
            )
        }

        isLoading = false

        // Start auto-refresh for live matches
        if liveMatch != nil {
            startAutoRefresh()
        } else if let firstUpcoming = upcoming?.first {
            // No live matches - schedule updates for upcoming match
            scheduleUpcomingMatchUpdates(firstUpcoming)
        }
    }

    private func fetchLiveFixtures() async -> [Afcon_Fixture]? {
        guard let service = afconService else { return nil }

        do {
            return try await service.getFixtures(
                leagueId: leagueID,
                season: season,
                live: true
            )
        } catch {
            print("❌ Failed to fetch live fixtures: \(error)")
            return nil
        }
    }

    private func fetchUpcomingFixtures() async -> [Afcon_Fixture]? {
        guard let service = afconService else { return nil }

        do {
            // Fetch ALL fixtures for the season (not just today)
            let fixtures = try await service.getFixtures(
                leagueId: leagueID,
                season: season
            )

            // Filter for upcoming matches only (not started) and in the future
            let now = Date()
            let upcoming = fixtures.filter { fixture in
                let status = fixture.status.short
                let fixtureDate = Date(timeIntervalSince1970: TimeInterval(fixture.timestamp))
                return (status == "NS" || status == "TBD") && fixtureDate > now
            }

            // Sort by timestamp (earliest first)
            return upcoming.sorted { $0.timestamp < $1.timestamp }

        } catch {
            print("❌ Failed to fetch upcoming fixtures: \(error)")
            return nil
        }
    }

    private func startAutoRefresh() {
        // Cancel existing task
        updateTask?.cancel()

        // Refresh every 15 seconds if there's a live match
        updateTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds

                if let fixtures = await fetchLiveFixtures(), let firstLive = fixtures.first {
                    liveMatch = LiveMatchInfo(
                        homeTeam: firstLive.teams.home.name,
                        awayTeam: firstLive.teams.away.name,
                        homeTeamId: Int(firstLive.teams.home.id),
                        awayTeamId: Int(firstLive.teams.away.id),
                        homeScore: Int(firstLive.goals.home),
                        awayScore: Int(firstLive.goals.away),
                        minute: "\(firstLive.status.elapsed)'"
                    )
                    statusText = "Live now"
                } else {
                    // No more live matches, stop refreshing
                    liveMatch = nil
                    statusText = "Live updates"
                    break
                }
            }
        }
    }

    private func formatMatchDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        // Check if today
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Today, \(formatter.string(from: date))"
        }

        // Check if tomorrow
        if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm"
            return "Tomorrow, \(formatter.string(from: date))"
        }

        // Otherwise, show full date
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    func cleanup() {
        updateTask?.cancel()
        updateTask = nil
        scheduleTask?.cancel()
        scheduleTask = nil
    }

    // MARK: - Scheduled Updates

    private func scheduleUpcomingMatchUpdates(_ fixture: Afcon_Fixture) {
        scheduleTask?.cancel()

        let fixtureDate = Date(timeIntervalSince1970: TimeInterval(fixture.timestamp))
        let now = Date()

        scheduleTask = Task { @MainActor in
            // Calculate time until match start
            if fixtureDate > now && !Task.isCancelled {
                let timeUntilMatch = fixtureDate.timeIntervalSince(now)
                statusText = "Match starts in \(formatTimeInterval(timeUntilMatch))"

                try? await Task.sleep(nanoseconds: UInt64(timeUntilMatch * 1_000_000_000))

                if !Task.isCancelled {
                    // Match should be starting - begin live updates
                    statusText = "Match starting..."
                    await loadData() // Reload to check for live matches
                }
            }
        }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "soon"
        }
    }
}

// MARK: - Supporting Types
struct LiveMatchInfo {
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int
    let awayTeamId: Int
    let homeScore: Int
    let awayScore: Int
    let minute: String
}

struct UpcomingMatchInfo {
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int
    let awayTeamId: Int
    let dateTime: String
}

// MARK: - Preview
#Preview {
    QuickStatsBarLive()
}
