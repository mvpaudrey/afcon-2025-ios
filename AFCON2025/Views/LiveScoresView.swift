import SwiftUI
import SwiftData
#if canImport(ActivityKit)
import ActivityKit
#endif

struct LiveScoresView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LiveScoresViewModel?

    init(viewModel: LiveScoresViewModel? = nil) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView("Initializing...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LiveScoresViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func contentView(viewModel: LiveScoresViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color("moroccoRed"))
                        Text(LocalizedStringKey("Live Scores"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Button {
                                Task {
                                    await viewModel.fetchLiveMatches()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Color("moroccoRed"))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Error State
                    if let error = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button(LocalizedStringKey("Retry")) {
                                Task {
                                    await viewModel.fetchLiveMatches()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        // Live Matches Section
                        if !viewModel.liveMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    Text(NSLocalizedString("matches.section.live", value: "LIVE NOW", comment: "Live matches section"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.liveMatches) { match in
                                    MatchCard(
                                        match: match,
                                        events: viewModel.fixtureEvents[match.id] ?? []
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Finished Matches Section (Today)
                        if !viewModel.finishedMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(NSLocalizedString("matches.section.finished", value: "FINISHED TODAY", comment: "Finished matches section"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.finishedMatches) { match in
                                    MatchCard(
                                        match: match,
                                        events: []
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Today's Upcoming Matches Section
                        if viewModel.shouldShowUpcomingToday {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(NSLocalizedString("matches.section.upcoming", value: "UPCOMING", comment: "Upcoming matches section"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("moroccoRed"))
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.upcomingTodayMatches) { match in
                                    MatchCard(match: match)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Empty State (only if no games today)
                        if !viewModel.hasGamesToday && !viewModel.isLoading {
                            VStack(spacing: 8) {
                                Image(systemName: "sportscourt")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text(LocalizedStringKey("No matches today"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.fetchLiveMatches()
            viewModel.startLiveUpdates()
        }
        .onDisappear {
            viewModel.stopLiveUpdates()
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return NSLocalizedString("TODAY", comment: "")
        } else if calendar.isDateInTomorrow(date) {
            return NSLocalizedString("TOMORROW", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date).uppercased()
        }
    }
}

// MARK: - Preview Helpers
private class MockLiveScoresViewModel: LiveScoresViewModel {
    init(liveMatches: [Game] = [], upcoming: [Game] = []) {
        super.init()
        self.liveMatches = liveMatches
        self.upcomingMatches = upcoming
    }

    override func fetchLiveMatches() async {
        // Do nothing in preview
    }

    override func startLiveUpdates() {
        // Do nothing in preview
    }
}

// MARK: - Mock Data
private extension Game {
    static func mockLive(id: Int, homeTeam: String, homeTeamId: Int, awayTeam: String, awayTeamId: Int, homeScore: Int, awayScore: Int, minute: String) -> Game {
        Game(
            id: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            homeScore: homeScore,
            awayScore: awayScore,
            status: .live,
            minute: minute,
            competition: "AFCON 2025",
            venue: "Stade Prince Moulay Abdallah",
            date: Date(),
            statusShort: "LIVE"
        )
    }

    static func mockUpcoming(id: Int, homeTeam: String, homeTeamId: Int, awayTeam: String, awayTeamId: Int, hoursFromNow: TimeInterval) -> Game {
        Game(
            id: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            homeScore: 0,
            awayScore: 0,
            status: .upcoming,
            minute: "",
            competition: "AFCON 2025",
            venue: "Stade de Marrakech",
            date: Date().addingTimeInterval(3600 * hoursFromNow),
            statusShort: "NS"
        )
    }
}

// MARK: - Previews
#Preview("Live Matches") {
    let viewModel = MockLiveScoresViewModel(
        liveMatches: [
            .mockLive(id: 1, homeTeam: "Morocco", homeTeamId: 31, awayTeam: "Senegal", awayTeamId: 13, homeScore: 2, awayScore: 1, minute: "67'"),
            .mockLive(id: 2, homeTeam: "Egypt", homeTeamId: 32, awayTeam: "Nigeria", awayTeamId: 19, homeScore: 0, awayScore: 0, minute: "23'")
        ]
    )

    LiveScoresView(viewModel: viewModel)
}

#Preview("Upcoming Today") {
    let viewModel = MockLiveScoresViewModel(
        upcoming: [
            .mockUpcoming(id: 1, homeTeam: "Morocco", homeTeamId: 31, awayTeam: "Ivory Coast", awayTeamId: 1501, hoursFromNow: 2),
            .mockUpcoming(id: 2, homeTeam: "Senegal", homeTeamId: 13, awayTeam: "Egypt", awayTeamId: 32, hoursFromNow: 4),
            .mockUpcoming(id: 3, homeTeam: "Nigeria", homeTeamId: 19, awayTeam: "Cameroon", awayTeamId: 1530, hoursFromNow: 6)
        ]
    )

    LiveScoresView(viewModel: viewModel)
}

#Preview("Empty State") {
    let viewModel = MockLiveScoresViewModel()
    LiveScoresView(viewModel: viewModel)
}
