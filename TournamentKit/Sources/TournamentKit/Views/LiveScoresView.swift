import SwiftUI
import SwiftData
#if canImport(ActivityKit)
import ActivityKit
#endif

public struct LiveScoresView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tournamentConfig) private var config
    @State private var viewModel: LiveScoresViewModel?
    private let onOpenSchedule: (() -> Void)?

    public init(viewModel: LiveScoresViewModel? = nil, onOpenSchedule: (() -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenSchedule = onOpenSchedule
    }

    public var body: some View {
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
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color(config.accentColorName))
                        Text(LocalizedStringKey("Live Scores"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                        } else if !viewModel.liveMatches.isEmpty {
                            // Show countdown for next update
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(viewModel.secondsUntilNextUpdate)s")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
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
                                        events: viewModel.fixtureEvents[match.id] ?? [],
                                        showsCompetition: false
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
                                        events: [],
                                        showsCompetition: false
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
                                        .foregroundColor(Color(config.accentColorName))
                                    Text(NSLocalizedString("matches.section.upcoming", value: "UPCOMING", comment: "Upcoming matches section"))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(config.accentColorName))
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.upcomingTodayMatches) { match in
                                    MatchCard(match: match, showsCompetition: false)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Empty State (only if no games today)
                        if !viewModel.hasGamesToday && !viewModel.isLoading {
                            EmptyStateView(
                                minHeight: max(200, proxy.size.height * 0.6),
                                showScheduleButton: onOpenSchedule != nil,
                                onOpenSchedule: onOpenSchedule
                            )
                            .equatable()
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.fetchLiveMatches()
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

@MainActor
private struct EmptyStateView: View, Equatable {
    let minHeight: CGFloat
    let showScheduleButton: Bool
    let onOpenSchedule: (() -> Void)?

    nonisolated static func == (lhs: EmptyStateView, rhs: EmptyStateView) -> Bool {
        lhs.minHeight == rhs.minHeight && lhs.showScheduleButton == rhs.showScheduleButton
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                Image(systemName: "sportscourt")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text(LocalizedStringKey("No matches today"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if showScheduleButton, let onOpenSchedule {
                    Button(LocalizedStringKey("View Schedule")) {
                        onOpenSchedule()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight)
    }
}
