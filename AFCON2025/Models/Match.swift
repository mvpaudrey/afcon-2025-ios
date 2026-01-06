import Foundation

struct Game: Identifiable {
    let id: Int
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int
    let awayTeamId: Int
    let homeScore: Int
    let awayScore: Int
    let homePenaltyScore: Int?
    let awayPenaltyScore: Int?
    let status: MatchStatus
    let minute: String
    let competition: String
    let venue: String
    let date: Date
    let statusShort: String
}

enum MatchStatus {
    case live
    case finished
    case upcoming
}

// MARK: - Team Flag Support
extension Game {
    /// Returns the asset name for the home team's flag
    var homeTeamFlagAsset: String? {
        TeamFlagMapper.flagAssetName(for: homeTeamId)
    }

    /// Returns the asset name for the away team's flag
    var awayTeamFlagAsset: String? {
        TeamFlagMapper.flagAssetName(for: awayTeamId)
    }
}
