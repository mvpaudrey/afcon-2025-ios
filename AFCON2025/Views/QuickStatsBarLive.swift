import SwiftUI
import AFCONClient
import SwiftData

struct QuickStatsBarLive: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: QuickStatsViewModel?

    @Environment(\.tabBarMinimized) private var _isMinimized: Bool

    private var isMinimized: Bool { _isMinimized }

    var body: some View {
        VStack(spacing: 0) {
            if let viewModel = viewModel {
                HStack {
                    HStack(spacing: isMinimized ? 8 : 12) {
                        // Current live match or latest result
                        if let liveMatch = viewModel.liveMatch {
                            liveMatchView(liveMatch, isMinimized: isMinimized)
                        } else if viewModel.isLoading {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                if !isMinimized {
                                    Text(LocalizedStringKey("Loading..."))
                                        .font(.caption)
                                        .opacity(0.7)
                                }
                            }
                        } else {
                            // Show next match if no live match
                            if let nextMatch = viewModel.nextMatch {
                                upcomingMatchView(nextMatch, isMinimized: isMinimized)
                            } else {
                                if !isMinimized {
                                    HStack(spacing: 4) {
                                        Text(LocalizedStringKey("No matches scheduled"))
                                            .font(.caption)
                                            .opacity(0.7)
                                    }
                                }
                            }
                        }

                        Spacer()

                        if !isMinimized, let statusText = viewModel.statusText {
                            Text(LocalizedStringKey(statusText))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .opacity(0.8)
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, isMinimized ? 8 : 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoGreen")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            } else {
                // Loading state while viewModel initializes
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoGreen")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = QuickStatsViewModel(modelContext: modelContext)
            }
            Task {
                await viewModel?.loadData()
            }
        }
        .onDisappear {
            viewModel?.cleanup()
        }
    }

    @ViewBuilder
    private func liveMatchView(_ liveMatch: LiveMatchInfo, isMinimized: Bool) -> some View {
        HStack(spacing: 6) {
            // Halftime icon
            if liveMatch.isHalftime {
                Image(systemName: "pause.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            // Home team
            if let homeFlag = TeamFlagMapper.flagAssetName(for: liveMatch.homeTeamId) {
                Image(homeFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            Text("\(liveMatch.homeScore)-\(liveMatch.awayScore)")
                .fontWeight(.bold)

            // Away team
            if let awayFlag = TeamFlagMapper.flagAssetName(for: liveMatch.awayTeamId) {
                Image(awayFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            Text(liveMatch.displayMinute)
                .fontWeight(liveMatch.isHalftime ? .semibold : .medium)
                .foregroundColor(liveMatch.isHalftime ? .orange : .white)
                .opacity(liveMatch.isHalftime ? 1.0 : 0.9)
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private func upcomingMatchView(_ nextMatch: UpcomingMatchInfo, isMinimized: Bool) -> some View {
        let timeUntilMatch = nextMatch.matchDate.timeIntervalSince(Date())
        let showCountdown = timeUntilMatch > 0 && timeUntilMatch < 3600 && Calendar.current.isDateInToday(nextMatch.matchDate)

        HStack(spacing: 6) {
            // Home team
            if let homeFlag = TeamFlagMapper.flagAssetName(for: nextMatch.homeTeamId) {
                Image(homeFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            Text(LocalizedStringKey("vs"))
                .fontWeight(.medium)
                .opacity(0.8)

            // Away team
            if let awayFlag = TeamFlagMapper.flagAssetName(for: nextMatch.awayTeamId) {
                Image(awayFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            if !isMinimized {
                Text("•")
                    .opacity(0.5)

                // Use SwiftUI countdown timer for matches less than 1 hour away
                if showCountdown {
                    Text(nextMatch.matchDate, style: .timer)
                        .fontWeight(.medium)
                        .opacity(0.9)
                        .monospacedDigit()
                } else {
                    Text(nextMatch.dateTime)
                        .fontWeight(.medium)
                        .opacity(0.9)
                }
            }
        }
        .font(.subheadline)
    }
}

// MARK: - ViewModel
@Observable
final class QuickStatsViewModel {
    var liveMatch: LiveMatchInfo?
    var nextMatch: UpcomingMatchInfo?
    var isLoading = false
    var statusText: String? = NSLocalizedString("Live updates", comment: "")

    private var dataManager: FixtureDataManager?
    private var updateTask: Task<Void, Never>?
    private var scheduleTask: Task<Void, Never>?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = FixtureDataManager(modelContext: modelContext)
    }

    @MainActor
    func loadData() async {
        isLoading = true

        guard let dataManager = dataManager else {
            isLoading = false
            return
        }

        do {
            // Load fixtures from SwiftData
            let allFixtures = try dataManager.getAllFixtures()
            let allGames = allFixtures.map { $0.toGame() }

            let now = Date()
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)

            // Separate into categories
            let liveGames = allGames.filter { $0.status == .live }
            let upcomingGames = allGames.filter { $0.status == .upcoming && $0.date > now }
                .sorted { $0.date < $1.date }

            // Process live match
            if let firstLive = liveGames.first {
                let isHalftime = firstLive.statusShort.uppercased() == "HT"
                liveMatch = LiveMatchInfo(
                    homeTeam: firstLive.homeTeam,
                    awayTeam: firstLive.awayTeam,
                    homeTeamId: firstLive.homeTeamId,
                    awayTeamId: firstLive.awayTeamId,
                    homeScore: firstLive.homeScore,
                    awayScore: firstLive.awayScore,
                    minute: firstLive.minute,
                    statusShort: firstLive.statusShort
                )
                statusText = isHalftime ? NSLocalizedString("match.status.halftime", value: "HALFTIME", comment: "Halftime status") : NSLocalizedString("quickstats.live", value: "Live now", comment: "Live now status")
            } else {
                liveMatch = nil
                statusText = nil
            }

            // Process next upcoming match
            if let firstUpcoming = upcomingGames.first {
                nextMatch = UpcomingMatchInfo(
                    homeTeam: firstUpcoming.homeTeam,
                    awayTeam: firstUpcoming.awayTeam,
                    homeTeamId: firstUpcoming.homeTeamId,
                    awayTeamId: firstUpcoming.awayTeamId,
                    dateTime: formatMatchDate(firstUpcoming.date),
                    matchDate: firstUpcoming.date
                )
            } else {
                nextMatch = nil
            }

            // Start auto-refresh for live matches
            if liveMatch != nil {
                startAutoRefresh()
            } else if nextMatch != nil {
                scheduleUpcomingMatchUpdates(nextMatch!.matchDate)
            }
        } catch {
            print("❌ QuickStatsViewModel failed to load fixtures: \(error)")
        }

        isLoading = false
    }

    private func startAutoRefresh() {
        // Cancel existing task
        updateTask?.cancel()

        // Refresh every 15 seconds if there's a live match
        updateTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds

                // Reload from SwiftData
                await loadData()

                // Stop if no more live matches
                if liveMatch == nil {
                    break
                }
            }
        }
    }

    private func formatMatchDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        // Check if today - just show time (SwiftUI timer handles countdown)
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        // Check if tomorrow
        if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm"
            let tomorrow = NSLocalizedString("Tomorrow", comment: "")
            return "\(tomorrow), \(formatter.string(from: date))"
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

    private func scheduleUpcomingMatchUpdates(_ fixtureDate: Date) {
        scheduleTask?.cancel()

        let now = Date()

        scheduleTask = Task { @MainActor in
            // Calculate time until match start
            if fixtureDate > now && !Task.isCancelled {
                let timeUntilMatch = fixtureDate.timeIntervalSince(now)

                try? await Task.sleep(nanoseconds: UInt64(timeUntilMatch * 1_000_000_000))

                if !Task.isCancelled {
                    // Match should be starting - reload to check for live matches
                    await loadData()
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
            return NSLocalizedString("soon", comment: "")
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
    let statusShort: String

    var isHalftime: Bool {
        statusShort.uppercased() == "HT"
    }

    var displayMinute: String {
        if isHalftime {
            return NSLocalizedString("match.status.halftime", value: "HALFTIME", comment: "Halftime status")
        }
        return minute
    }
}

struct UpcomingMatchInfo {
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int
    let awayTeamId: Int
    let dateTime: String
    let matchDate: Date
}

// MARK: - Preview
#Preview {
    QuickStatsBarLive()
}
