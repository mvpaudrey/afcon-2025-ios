import SwiftUI

struct GroupsView: View {
    let groups = [
        Group(
            name: "Group A - AFCON 2025",
            teams: [
                Team(name: "Morocco", teamId: 31, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 1),
                Team(name: "Mali", teamId: 1500, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 2),
                Team(name: "Zambia", teamId: 1507, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 3),
                Team(name: "Comoros", teamId: 1524, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 4)
            ]
        ),
        Group(
            name: "Group B - AFCON 2025",
            teams: [
                Team(name: "Egypt", teamId: 32, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 1),
                Team(name: "South Africa", teamId: 1531, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 2),
                Team(name: "Angola", teamId: 1529, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 3),
                Team(name: "Zimbabwe", teamId: 1522, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 4)
            ]
        ),
        Group(
            name: "Group C - AFCON 2025",
            teams: [
                Team(name: "Nigeria", teamId: 19, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 1),
                Team(name: "Tunisia", teamId: 28, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 2),
                Team(name: "Uganda", teamId: 1519, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 3),
                Team(name: "Tanzania", teamId: 1489, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 4)
            ]
        ),
        Group(
            name: "Group D - AFCON 2025",
            teams: [
                Team(name: "Senegal", teamId: 13, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 1),
                Team(name: "DR Congo", teamId: 1508, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 2),
                Team(name: "Benin", teamId: 1516, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 3),
                Team(name: "Botswana", teamId: 1520, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 4)
            ]
        ),
        Group(
            name: "Group E - AFCON 2025",
            teams: [
                Team(name: "Algeria", teamId: 1532, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 1),
                Team(name: "Burkina Faso", teamId: 1502, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 2),
                Team(name: "Equatorial Guinea", teamId: 1521, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 3),
                Team(name: "Sudan", teamId: 1510, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 4)
            ]
        ),
        Group(
            name: "Group F - AFCON 2025",
            teams: [
                Team(name: "Ivory Coast", teamId: 1501, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 1),
                Team(name: "Cameroon", teamId: 1530, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 2),
                Team(name: "Gabon", teamId: 1503, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 3),
                Team(name: "Mozambique", teamId: 1512, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, points: 0, position: 4)
            ]
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(groups, id: \.name) { group in
                    GroupCard(group: group)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
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
                        .frame(width: 32, alignment: .center)
                    Text(LocalizedStringKey("Team"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(LocalizedStringKey("P"))
                        .frame(width: 28, alignment: .center)
                    Text(LocalizedStringKey("W"))
                        .frame(width: 28, alignment: .center)
                    Text(LocalizedStringKey("D"))
                        .frame(width: 28, alignment: .center)
                    Text(LocalizedStringKey("L"))
                        .frame(width: 28, alignment: .center)
                    Text(LocalizedStringKey("GD"))
                        .frame(width: 32, alignment: .center)
                    Text(LocalizedStringKey("Pts"))
                        .frame(width: 36, alignment: .center)
                        .fontWeight(.bold)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
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
                    .frame(width: 32, alignment: .center)

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
                    .frame(width: 28, alignment: .center)

                Text("\(team.won)")
                    .font(.caption)
                    .foregroundColor(Color("moroccoGreen"))
                    .fontWeight(.bold)
                    .frame(width: 28, alignment: .center)

                Text("\(team.drawn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                    .frame(width: 28, alignment: .center)

                Text("\(team.lost)")
                    .font(.caption)
                    .foregroundColor(Color("moroccoRed"))
                    .fontWeight(.bold)
                    .frame(width: 28, alignment: .center)

                Text(goalDifferenceText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(goalDifferenceColor)
                    .frame(width: 32, alignment: .center)

                Text("\(team.points)")
                    .font(.footnote)
                    .fontWeight(.black)
                    .foregroundColor(Color("moroccoRed"))
                    .frame(width: 36, alignment: .center)
            }
            .padding(.horizontal, 16)
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

// MARK: - Data Models
struct Group {
    let name: String
    let teams: [Team]
}

struct Team {
    let name: String
    let teamId: Int
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let gf: Int
    let ga: Int
    let points: Int
    let position: Int
}

#Preview {
    GroupsView()
}
