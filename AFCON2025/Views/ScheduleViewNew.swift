import SwiftUI
import SwiftData

struct ScheduleViewNew: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ScheduleViewModel

    init(viewModel: ScheduleViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            _viewModel = State(initialValue: ScheduleViewModel())
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("moroccoRed"))
                    Text(LocalizedStringKey("Upcoming Matches"))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()

                    // Refresh button
                    if viewModel.hasFixtures {
                        Button(action: {
                            Task {
                                await viewModel.refreshFixtures()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color("moroccoRed"))
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(.horizontal)

                // Loading indicator
                if viewModel.isLoading {
                    ProgressView(LocalizedStringKey("Loading fixtures..."))
                        .padding()
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(Color("moroccoRed"))
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(LocalizedStringKey("Retry")) {
                            Task {
                                await viewModel.fetchAllFixtures()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("moroccoRed"))
                    }
                    .padding()
                }

                // Empty state
                if !viewModel.hasFixtures && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(Color("moroccoRed").opacity(0.5))
                        Text(LocalizedStringKey("No fixtures available"))
                            .font(.title3)
                            .fontWeight(.medium)
                        Text(LocalizedStringKey("Tap below to fetch fixtures from the server"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button(LocalizedStringKey("Fetch Fixtures")) {
                            Task {
                                await viewModel.fetchAllFixtures()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("moroccoRed"))
                    }
                    .padding()
                    .padding(.top, 60)
                }

                // Fixtures list
                ForEach(viewModel.upcomingFixtures) { fixture in
                    FixtureCard(fixture: fixture)
                }

                if !viewModel.finishedFixtures.isEmpty {
                    HStack {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(Color("moroccoRed"))
                        Text(LocalizedStringKey("Finished Matches"))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.finishedFixtures.sorted { $0.date > $1.date }) { fixture in
                        FixtureCard(fixture: fixture)
                    }
                }
            }
            .padding()
        }
        .task {
            // Set modelContext in viewModel
            viewModel.modelContext = modelContext

            // Small delay to ensure bundled fixtures are loaded first
            try? await Task.sleep(for: .milliseconds(500))

            // Load from database first
            viewModel.loadFixturesFromDatabase()

            // If no fixtures, fetch from server
            if !viewModel.hasFixtures {
                await viewModel.fetchAllFixtures()
            } else if viewModel.shouldRefreshFixtures() {
                await viewModel.fetchAllFixtures()
            }
        }
    }
}

struct FixtureCard: View {
    let fixture: FixtureModel
    private var showsScore: Bool {
        fixture.isFinished || fixture.isLive
    }
    private var showsPenaltyScore: Bool {
        fixture.penaltyHome > 0 || fixture.penaltyAway > 0
    }
    private var homeScoreColor: Color {
        if showsPenaltyScore { return .secondary }
        if fixture.homeTeamWinner { return Color("moroccoGreen") }
        if fixture.awayTeamWinner { return Color("moroccoRed") }
        return .secondary
    }
    private var awayScoreColor: Color {
        if showsPenaltyScore { return .secondary }
        if fixture.awayTeamWinner { return Color("moroccoGreen") }
        if fixture.homeTeamWinner { return Color("moroccoRed") }
        return .secondary
    }
    private var homePenaltyColor: Color {
        if fixture.penaltyHome > fixture.penaltyAway { return Color("moroccoGreen") }
        if fixture.penaltyHome < fixture.penaltyAway { return Color("moroccoRed") }
        return .secondary
    }
    private var awayPenaltyColor: Color {
        if fixture.penaltyAway > fixture.penaltyHome { return Color("moroccoGreen") }
        if fixture.penaltyAway < fixture.penaltyHome { return Color("moroccoRed") }
        return .secondary
    }
    private var penaltyScoreText: AttributedString {
        let penaltyFormat = String(localized: "Pens: %lld-%lld", comment: "Penalty shootout score label")
        let penaltyText = String.localizedStringWithFormat(
            penaltyFormat,
            Int64(fixture.penaltyHome),
            Int64(fixture.penaltyAway)
        )

        var attributed = AttributedString(penaltyText)
        attributed.foregroundColor = .secondary

        let homeText = String(fixture.penaltyHome)
        let awayText = String(fixture.penaltyAway)

        if let homeRange = attributed.range(of: homeText) {
            attributed[homeRange].foregroundColor = homePenaltyColor

            let searchStart = homeRange.upperBound
            let tail = attributed[searchStart...]
            if let awayRangeInTail = tail.range(of: awayText) {
                attributed[awayRangeInTail].foregroundColor = awayPenaltyColor
            } else if let awayRange = attributed.range(of: awayText) {
                attributed[awayRange].foregroundColor = awayPenaltyColor
            }
        } else if let awayRange = attributed.range(of: awayText) {
            attributed[awayRange].foregroundColor = awayPenaltyColor
        }

        return attributed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date and status
            HStack {
                HStack(spacing: 8) {
                    Text(fixture.formattedDate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("moroccoRed").opacity(0.1))
                        .foregroundColor(Color("moroccoRed"))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color("moroccoRed"), lineWidth: 1)
                        )

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(fixture.formattedTime)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicator
                if fixture.isLive {
                    Text(LocalizedStringKey(fixture.statusShort))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                }
            }

            // Teams
            HStack(spacing: 24) {
                // Home team
                VStack(spacing: 8) {
                    if let flagAsset = TeamFlagMapper.flagAssetName(for: fixture.homeTeamId) {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("moroccoRed"), Color("moroccoRedDark")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(String(fixture.homeTeamName.prefix(3)).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }

                    Text(localizedTeamName(fixture.homeTeamName))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                if showsScore {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\(fixture.homeGoals)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(homeScoreColor)
                            Text("-")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("\(fixture.awayGoals)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(awayScoreColor)
                        }

                        if showsPenaltyScore {
                            Text(penaltyScoreText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(minWidth: 140)
                } else {
                    Text(LocalizedStringKey("VS"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                // Away team
                VStack(spacing: 8) {
                    if let flagAsset = TeamFlagMapper.flagAssetName(for: fixture.awayTeamId) {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("moroccoGreen"), Color("moroccoGreenDark")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(String(fixture.awayTeamName.prefix(3)).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }

                    Text(localizedTeamName(fixture.awayTeamName))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)

            // Venue and city
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(Color("moroccoRedDark"))
                Text(fixture.fullVenue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview
#Preview {
    ScheduleViewNew()
        .modelContainer(for: FixtureModel.self, inMemory: true)
}
