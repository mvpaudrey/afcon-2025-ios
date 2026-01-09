import SwiftUI

/// View displaying penalty shootout scores
struct PenaltyShootoutView: View {
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int
    let awayTeamId: Int
    let homePenaltyScore: Int
    let awayPenaltyScore: Int
    let homeScore: Int
    let awayScore: Int
    let compact: Bool

    init(
        homeTeam: String,
        awayTeam: String,
        homeTeamId: Int,
        awayTeamId: Int,
        homePenaltyScore: Int,
        awayPenaltyScore: Int,
        homeScore: Int,
        awayScore: Int,
        compact: Bool = false
    ) {
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeTeamId = homeTeamId
        self.awayTeamId = awayTeamId
        self.homePenaltyScore = homePenaltyScore
        self.awayPenaltyScore = awayPenaltyScore
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.compact = compact
    }

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    private var compactView: some View {
        VStack(spacing: 2) {
            // Regular score
            HStack(spacing: 4) {
                Text("\(homeScore)")
                    .font(.body)
                    .fontWeight(.bold)
                    .monospacedDigit()

                Text(":")
                    .foregroundColor(.secondary)

                Text("\(awayScore)")
                    .font(.body)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            // Penalty score
            Text("Pens: \(homePenaltyScore)-\(awayPenaltyScore)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(homePenaltyScore > awayPenaltyScore ? Color("moroccoGreen") : (awayPenaltyScore > homePenaltyScore ? Color("moroccoRed") : .secondary))
                .monospacedDigit()
        }
    }

    private var fullView: some View {
        HStack(alignment: .center, spacing: 20) {
            // Home team - Left side
            VStack(spacing: 8) {
                if let homeFlag = TeamFlagMapper.flagAssetName(for: homeTeamId) {
                    Image(homeFlag)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }

                Text(localizedTeamName(homeTeam))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            // Center - Scores
            VStack(spacing: 4) {
                // Regular score (large)
                HStack(spacing: 8) {
                    Text("\(homeScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text(":")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.secondary)

                    Text("\(awayScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }

                // Penalty score (below)
                Text("Pens: \(homePenaltyScore)-\(awayPenaltyScore)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(homePenaltyScore > awayPenaltyScore ? Color("moroccoGreen") : (awayPenaltyScore > homePenaltyScore ? Color("moroccoRed") : .secondary))
                    .monospacedDigit()
            }

            Spacer()

            // Away team - Right side
            VStack(spacing: 8) {
                if let awayFlag = TeamFlagMapper.flagAssetName(for: awayTeamId) {
                    Image(awayFlag)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }

                Text(localizedTeamName(awayTeam))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

}

// MARK: - Previews
#Preview("Full Penalty Shootout") {
    VStack(spacing: 20) {
        // Mali vs Tunisia - 1-1 draw, Mali wins 3-2 on penalties
        PenaltyShootoutView(
            homeTeam: "Mali",
            awayTeam: "Tunisia",
            homeTeamId: 1551,
            awayTeamId: 1530,
            homePenaltyScore: 3,
            awayPenaltyScore: 2,
            homeScore: 1,
            awayScore: 1,
            compact: false
        )

        PenaltyShootoutView(
            homeTeam: "Morocco",
            awayTeam: "Egypt",
            homeTeamId: 31,
            awayTeamId: 32,
            homePenaltyScore: 3,
            awayPenaltyScore: 2,
            homeScore: 1,
            awayScore: 1,
            compact: false
        )

        PenaltyShootoutView(
            homeTeam: "Senegal",
            awayTeam: "Nigeria",
            homeTeamId: 13,
            awayTeamId: 19,
            homePenaltyScore: 4,
            awayPenaltyScore: 5,
            homeScore: 0,
            awayScore: 0,
            compact: false
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Penalty Shootout") {
    VStack(spacing: 16) {
        // Mali vs Tunisia - 1-1 draw, Mali wins 3-2 on penalties
        PenaltyShootoutView(
            homeTeam: "Mali",
            awayTeam: "Tunisia",
            homeTeamId: 1551,
            awayTeamId: 1530,
            homePenaltyScore: 3,
            awayPenaltyScore: 2,
            homeScore: 1,
            awayScore: 1,
            compact: true
        )

        PenaltyShootoutView(
            homeTeam: "Morocco",
            awayTeam: "Egypt",
            homeTeamId: 31,
            awayTeamId: 32,
            homePenaltyScore: 3,
            awayPenaltyScore: 2,
            homeScore: 1,
            awayScore: 1,
            compact: true
        )

        PenaltyShootoutView(
            homeTeam: "Senegal",
            awayTeam: "Nigeria",
            homeTeamId: 13,
            awayTeamId: 19,
            homePenaltyScore: 4,
            awayPenaltyScore: 5,
            homeScore: 0,
            awayScore: 0,
            compact: true
        )
    }
    .padding()
}
