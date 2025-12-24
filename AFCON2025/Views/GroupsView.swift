import SwiftUI
import SwiftData

private enum Metrics {
    static let horizontalPadding: CGFloat = 20
    static let positionWidth: CGFloat = 32
    static let statWidth: CGFloat = 28
    static let gdWidth: CGFloat = 32
    static let pointsWidth: CGFloat = 36
}

struct GroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GroupsViewModel()

    var body: some View {
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
                            Task {
                                await viewModel.loadStandings()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    ForEach(viewModel.groups, id: \.name) { group in
                        GroupCard(group: group)
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

struct GroupCard: View {
    let group: Group

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header with Morocco flag colors
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color("moroccoGreen"))
                        .font(.title2)

                    Text(group.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()
                }

                // Table Header with better spacing
                HStack(spacing: 4) {
                    Text(LocalizedStringKey("#"))
                        .frame(minWidth: Metrics.positionWidth, maxWidth: Metrics.positionWidth, alignment: .center)
                        .monospacedDigit()
                    Text(LocalizedStringKey("Team"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(LocalizedStringKey("P"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                        .monospacedDigit()
                    Text(LocalizedStringKey("W"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                        .monospacedDigit()
                    Text(LocalizedStringKey("D"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                        .monospacedDigit()
                    Text(LocalizedStringKey("L"))
                        .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                        .monospacedDigit()
                    Text(LocalizedStringKey("GD"))
                        .frame(minWidth: Metrics.gdWidth, maxWidth: Metrics.gdWidth, alignment: .center)
                        .monospacedDigit()
                    Text(LocalizedStringKey("Pts"))
                        .frame(minWidth: Metrics.pointsWidth, maxWidth: Metrics.pointsWidth, alignment: .center)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, Metrics.horizontalPadding)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("moroccoRed").opacity(0.05),
                            Color("moroccoGreen").opacity(0.05)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))

            // Team rows with improved design
            VStack(spacing: 0) {
                ForEach(Array(group.teams.enumerated()), id: \.element.name) { index, team in
                    TeamRow(team: team, isLast: index == group.teams.count - 1)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("moroccoRed").opacity(0.1), lineWidth: 1)
        )
    }
}

struct TeamRow: View {
    let team: Team
    let isLast: Bool
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                // Enhanced Position Badge
                Text("\(team.position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(positionBadgeColor)
                    .cornerRadius(6)
                    .frame(width: Metrics.positionWidth, alignment: .center)

                // Team with flag
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
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoGreen")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(team.name.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(team.name)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(team.played)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(minWidth: Metrics.statWidth, maxWidth: Metrics.statWidth, alignment: .center)
                    .monospacedDigit()

                Text("\(team.won)")
                    .font(.caption)
                    .foregroundColor(Color("moroccoGreen"))
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
                    .foregroundColor(Color("moroccoRed"))
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
                    .foregroundColor(Color("moroccoRed"))
                    .frame(minWidth: Metrics.pointsWidth, maxWidth: Metrics.pointsWidth, alignment: .center)
                    .monospacedDigit()
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(rowBackgroundColor)
                    .opacity(isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                // Add tap action if needed
            }
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                isPressed = pressing
            }, perform: {})

            if !isLast {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }

    private var positionBadgeColor: Color {
        switch team.position {
        case 1:
            return Color("moroccoGreen")
        case 2:
            return Color("moroccoGreen").opacity(0.8)
        case 3...4:
            return Color("moroccoRed")
        default:
            return Color.gray
        }
    }

    private var goalDifferenceText: String {
        let diff = team.gf - team.ga
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }

    private var goalDifferenceColor: Color {
        let diff = team.gf - team.ga
        if diff > 0 {
            return Color("moroccoGreen")
        } else if diff < 0 {
            return Color("moroccoRed")
        } else {
            return .secondary
        }
    }

    private var rowBackgroundColor: Color {
        switch team.position {
        case 1:
            return Color("moroccoGreen").opacity(0.03)
        case 2:
            return Color("moroccoGreen").opacity(0.02)
        case 3...4:
            return Color("moroccoRed").opacity(0.02)
        default:
            return Color(.systemBackground)
        }
    }
}

#Preview {
    GroupsView()
}

