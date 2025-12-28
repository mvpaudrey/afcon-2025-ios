import SwiftUI
import SwiftData

/// Example view showing how to display fixtures from SwiftData
/// You can adapt this pattern for your LiveScoresView and ScheduleView
struct FixturesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FixtureModel.date) private var allFixtures: [FixtureModel]

    // Filter queries
    @Query(
        filter: #Predicate<FixtureModel> { fixture in
            ["LIVE", "1H", "2H", "HT", "ET", "P"].contains(fixture.statusShort)
        },
        sort: \FixtureModel.date
    ) private var liveFixtures: [FixtureModel]

    @Query(
        filter: #Predicate<FixtureModel> { fixture in
            !["LIVE", "1H", "2H", "HT", "ET", "P", "FT", "AET", "PEN"].contains(fixture.statusShort)
        },
        sort: \FixtureModel.date
    ) private var upcomingFixtures: [FixtureModel]

    @Query(
        filter: #Predicate<FixtureModel> { fixture in
            ["FT", "AET", "PEN"].contains(fixture.statusShort)
        },
        sort: \FixtureModel.date
    ) private var finishedFixtures: [FixtureModel]

    @State private var selectedFilter: FilterOption = .all

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case live = "Live"
        case upcoming = "Upcoming"
        case finished = "Finished"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Fixtures List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if displayedFixtures.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(displayedFixtures) { fixture in
                                SwiftDataFixtureCard(fixture: fixture)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Fixtures")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var displayedFixtures: [FixtureModel] {
        switch selectedFilter {
        case .all:
            return allFixtures
        case .live:
            return liveFixtures
        case .upcoming:
            return upcomingFixtures
        case .finished:
            return finishedFixtures
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No fixtures found")
                .font(.headline)
            Text("Initialize fixtures in Settings tab")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// Card view for displaying a single fixture from SwiftData
struct SwiftDataFixtureCard: View {
    let fixture: FixtureModel

    var body: some View {
        VStack(spacing: 12) {
            // Status and Date Header
            HStack {
                statusBadge
                Spacer()
                Text(fixture.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Teams and Score
            HStack(alignment: .center, spacing: 20) {
                // Home Team
                VStack(spacing: 8) {
                    teamIcon(fixture.homeTeamName)
                    Text(fixture.homeTeamName)
                        .font(.subheadline)
                        .fontWeight(fixture.homeTeamWinner ? .bold : .regular)
                        .foregroundColor(fixture.homeTeamWinner ? Color("moroccoRed") : .primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)

                // Score
                if fixture.isFinished || fixture.isLive {
                    HStack(spacing: 12) {
                        Text("\(fixture.homeGoals)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("-")
                            .foregroundColor(.secondary)
                        Text("\(fixture.awayGoals)")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                } else {
                    Text(fixture.formattedTime)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Away Team
                VStack(spacing: 8) {
                    teamIcon(fixture.awayTeamName)
                    Text(fixture.awayTeamName)
                        .font(.subheadline)
                        .fontWeight(fixture.awayTeamWinner ? .bold : .regular)
                        .foregroundColor(fixture.awayTeamWinner ? Color("moroccoGreen") : .primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }

            // Venue
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(fixture.fullVenue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            if fixture.isLive {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                Text(fixture.statusShort)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Text(fixture.statusShort)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(fixture.isFinished ? .green : .secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(fixture.isLive ? Color.red : Color(.systemGray5))
        .cornerRadius(8)
    }

    private func teamIcon(_ teamName: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("moroccoRed").opacity(0.8), Color("moroccoGreen").opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            Text(String(teamName.prefix(2)))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    FixturesListView()
        .modelContainer(for: FixtureModel.self)
}
