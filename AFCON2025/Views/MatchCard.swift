import SwiftUI

struct MatchCard: View {
    let match: Game

    private var statusText: String {
        switch match.status {
        case .live:
            return match.minute
        case .upcoming:
            return formatMatchTime(match.date)
        case .finished:
            return "FINISHED"
        }
    }

    private func formatMatchTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    if match.status == .live || match.status == .upcoming {
                        Image(systemName: "clock")
                            .font(.caption2)
                    }
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    match.status == .live ?
                    Color("moroccoRed") : Color(.systemGray5)
                )
                .foregroundColor(
                    match.status == .live ? .white : .secondary
                )
                .cornerRadius(12)
                
                Spacer()
                
                Text(match.competition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                // Home Team
                HStack(spacing: 12) {
                    if let flagAsset = match.homeTeamFlagAsset {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("moroccoRed"), Color("moroccoRedDark")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Text(String(match.homeTeam.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }

                    Text(match.homeTeam)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Score
                HStack(spacing: 16) {
                    Text("\(match.homeScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("moroccoRed"))
                    
                    Text("-")
                        .foregroundColor(.secondary)
                    
                    Text("\(match.awayScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color("moroccoGreen"))
                }
                
                Spacer()
                
                // Away Team
                HStack(spacing: 12) {
                    Text(match.awayTeam)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let flagAsset = match.awayTeamFlagAsset {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("moroccoGreen"), Color("moroccoGreenDark")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Text(String(match.awayTeam.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            Text(match.venue)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
