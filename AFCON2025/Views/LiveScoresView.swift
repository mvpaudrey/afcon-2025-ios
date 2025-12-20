import SwiftUI

struct LiveScoresView: View {
    @State private var viewModel: LiveScoresViewModel

    init(viewModel: LiveScoresViewModel = LiveScoresViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
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
                                    Text(LocalizedStringKey("LIVE NOW"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.liveMatches) { match in
                                    MatchCard(match: match)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Finished Today Section (when no live matches)
                        if viewModel.shouldShowFinishedToday {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("moroccoGreen"))
                                    Text(LocalizedStringKey("TODAY"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("moroccoRed"))
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.finishedTodayMatches) { match in
                                    MatchCard(match: match)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Next Day Section (when no live and no finished today)
                        if viewModel.shouldShowNextDay {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(LocalizedStringKey("TOMORROW"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("moroccoRed"))
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.nextDayMatches) { match in
                                    MatchCard(match: match)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Upcoming Matches Section (Grouped by Date)
                        if !viewModel.upcomingMatches.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                if !viewModel.liveMatches.isEmpty {
                                    Divider()
                                        .padding(.vertical, 8)
                                }

                                ForEach(viewModel.upcomingMatchesByDate, id: \.date) { dateGroup in
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Date Header
                                        Text(formatDateHeader(dateGroup.date))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("moroccoRed"))
                                            .padding(.horizontal)
                                            .padding(.top, 8)

                                        // Matches for this date
                                        ForEach(dateGroup.matches) { match in
                                            MatchCard(match: match)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }

                        // Empty State (only if both are empty)
                        if viewModel.liveMatches.isEmpty && viewModel.upcomingMatches.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 8) {
                                Image(systemName: "sportscourt")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text(LocalizedStringKey("No matches available"))
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
    init(liveMatches: [Game] = [], finishedToday: [Game] = [], nextDay: [Game] = [], upcoming: [Game] = []) {
        super.init()
        self.liveMatches = liveMatches
        self.finishedTodayMatches = finishedToday
        self.nextDayMatches = nextDay
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

    static func mockFinished(id: Int, homeTeam: String, homeTeamId: Int, awayTeam: String, awayTeamId: Int, homeScore: Int, awayScore: Int) -> Game {
        Game(
            id: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            homeScore: homeScore,
            awayScore: awayScore,
            status: .finished,
            minute: "90'",
            competition: "AFCON 2025",
            venue: "Stade Mohammed V",
            date: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
            statusShort: "FT"
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
        ],
        upcoming: [
            .mockUpcoming(id: 3, homeTeam: "Algeria", homeTeamId: 1532, awayTeam: "Tunisia", awayTeamId: 28, hoursFromNow: 6),
            .mockUpcoming(id: 4, homeTeam: "Cameroon", homeTeamId: 1530, awayTeam: "Gabon", awayTeamId: 1503, hoursFromNow: 8)
        ]
    )

    return LiveScoresView(viewModel: viewModel)
}

#Preview("Finished Today") {
    let viewModel = MockLiveScoresViewModel(
        finishedToday: [
            .mockFinished(id: 1, homeTeam: "Morocco", homeTeamId: 31, awayTeam: "Ivory Coast", awayTeamId: 1501, homeScore: 3, awayScore: 1),
            .mockFinished(id: 2, homeTeam: "Senegal", homeTeamId: 13, awayTeam: "Egypt", awayTeamId: 32, homeScore: 1, awayScore: 1),
            .mockFinished(id: 3, homeTeam: "Nigeria", homeTeamId: 19, awayTeam: "Cameroon", awayTeamId: 1530, homeScore: 2, awayScore: 0)
        ],
        upcoming: [
            .mockUpcoming(id: 4, homeTeam: "Algeria", homeTeamId: 1532, awayTeam: "Tunisia", awayTeamId: 28, hoursFromNow: 48),
            .mockUpcoming(id: 5, homeTeam: "Mali", homeTeamId: 1500, awayTeam: "Gabon", awayTeamId: 1503, hoursFromNow: 50)
        ]
    )

    return LiveScoresView(viewModel: viewModel)
}

#Preview("Tomorrow's Games") {
    let viewModel = MockLiveScoresViewModel(
        nextDay: [
            .mockUpcoming(id: 1, homeTeam: "Morocco", homeTeamId: 31, awayTeam: "Comoros", awayTeamId: 1524, hoursFromNow: 26),
            .mockUpcoming(id: 2, homeTeam: "Gabon", homeTeamId: 1503, awayTeam: "Benin", awayTeamId: 1516, hoursFromNow: 29),
            .mockUpcoming(id: 3, homeTeam: "Mali", homeTeamId: 1500, awayTeam: "Zambia", awayTeamId: 1507, hoursFromNow: 32)
        ],
        upcoming: [
            .mockUpcoming(id: 4, homeTeam: "Algeria", homeTeamId: 1532, awayTeam: "Tunisia", awayTeamId: 28, hoursFromNow: 50),
            .mockUpcoming(id: 5, homeTeam: "Egypt", homeTeamId: 32, awayTeam: "Tanzania", awayTeamId: 1489, hoursFromNow: 54)
        ]
    )

    return LiveScoresView(viewModel: viewModel)
}

#Preview("Empty State") {
    let viewModel = MockLiveScoresViewModel()
    return LiveScoresView(viewModel: viewModel)
}
