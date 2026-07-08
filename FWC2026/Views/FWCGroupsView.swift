import SwiftUI
import SwiftData
import TournamentKit

private enum Metrics {
    static let horizontalPadding: CGFloat = 16
    static let positionWidth: CGFloat = 24
    static let statWidth: CGFloat = 26
    static let gdWidth: CGFloat = 30
    static let pointsWidth: CGFloat = 34
}

public struct FWCGroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GroupsViewModel()

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(LocalizedStringKey("Retry")) {
                            Task { await viewModel.loadStandings() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    ForEach(viewModel.groups, id: \.name) { group in
                        FWCGroupCard(group: group)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.loadStandings()
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadStandings()
        }
    }
}

private struct FWCGroupCard: View {
    let group: TournamentKit.Group

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "globe.americas.fill")
                        .foregroundColor(Color("fifaBlue"))
                        .font(.title2)

                    Text(localizedGroupName(group.name))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()
                }

                HStack(spacing: 4) {
                    Text(LocalizedStringKey("#"))
                        .frame(minWidth: Metrics.positionWidth, maxWidth: Metrics.positionWidth, alignment: .trailing)
                        .monospacedDigit()
                    Text(LocalizedStringKey("Team"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(LocalizedStringKey("P"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .trailing)
                        .monospacedDigit()
                    Text(LocalizedStringKey("W"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .trailing)
                        .monospacedDigit()
                    Text(LocalizedStringKey("D"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .trailing)
                        .monospacedDigit()
                    Text(LocalizedStringKey("L"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .trailing)
                        .monospacedDigit()
                    Text(LocalizedStringKey("GD"))
                        .frame(minWidth: Metrics.gdWidth, maxWidth: Metrics.gdWidth, alignment: .trailing)
                        .monospacedDigit()
                    Text(LocalizedStringKey("Pts"))
                        .frame(minWidth: Metrics.pointsWidth, maxWidth: Metrics.pointsWidth, alignment: .trailing)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, Metrics.horizontalPadding - 6)
                .padding(.vertical, 12)
                .background(Color("fifaBlue").opacity(0.05))
            }
            .padding(.top, 20)
            .padding(.horizontal, Metrics.horizontalPadding)
            .background(Color(.systemBackground))

            VStack(spacing: 0) {
                ForEach(Array(group.teams.enumerated()), id: \.element.name) { index, team in
                    FWCTeamRow(team: team, isLast: index == group.teams.count - 1)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("fifaBlue").opacity(0.12), lineWidth: 1)
        )
    }
}

private struct FWCTeamRow: View {
    let team: Team
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("\(team.position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(positionBadgeColor)
                    .cornerRadius(6)
                    .frame(width: Metrics.positionWidth, alignment: .trailing)

                HStack(spacing: 10) {
                    if let flagAsset = TeamFlagMapper.flagAssetName(for: team.teamId) {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    } else {
                        Circle()
                            .fill(Color("fifaBlue").opacity(0.15))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(team.name.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("fifaBlue"))
                            )
                    }

                    Text(localizedTeamName(team.name))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(team.played)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                    .monospacedDigit()

                Text("\(team.won)")
                    .font(.caption)
                    .foregroundColor(Color("fifaBlue"))
                    .fontWeight(.bold)
                    .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                    .monospacedDigit()

                Text("\(team.drawn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                    .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                    .monospacedDigit()

                Text("\(team.lost)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
                    .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                    .monospacedDigit()

                Text(goalDifferenceText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(goalDifferenceColor)
                    .frame(minWidth: Metrics.gdWidth, maxWidth: Metrics.gdWidth, alignment: .center)
                    .monospacedDigit()

                Text("\(team.points)")
                    .font(.footnote)
                    .fontWeight(.black)
                    .foregroundColor(Color("fifaGold"))
                    .frame(minWidth: Metrics.pointsWidth, maxWidth: Metrics.pointsWidth, alignment: .center)
                    .monospacedDigit()
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, 16)

            if !isLast {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }

    private var positionBadgeColor: Color {
        switch team.position {
        case 1: return Color("fifaBlue")
        case 2: return Color("fifaBlue").opacity(0.75)
        default: return Color.gray
        }
    }

    private var goalDifferenceText: String {
        let diff = team.gf - team.ga
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }

    private var goalDifferenceColor: Color {
        let diff = team.gf - team.ga
        if diff > 0 { return Color("fifaBlue") }
        if diff < 0 { return .orange }
        return .secondary
    }
}

#Preview {
    FWCGroupsView()
}
