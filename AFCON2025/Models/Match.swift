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
    let statusElapsed: Int
    let statusExtra: Int
    let lastUpdated: Date
    let competition: String
    let venue: String
    let date: Date
    let statusShort: String

    init(
        id: Int,
        homeTeam: String,
        awayTeam: String,
        homeTeamId: Int,
        awayTeamId: Int,
        homeScore: Int,
        awayScore: Int,
        homePenaltyScore: Int?,
        awayPenaltyScore: Int?,
        status: MatchStatus,
        minute: String,
        statusElapsed: Int = 0,
        statusExtra: Int = 0,
        lastUpdated: Date = Date(),
        competition: String,
        venue: String,
        date: Date,
        statusShort: String
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeTeamId = homeTeamId
        self.awayTeamId = awayTeamId
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.homePenaltyScore = homePenaltyScore
        self.awayPenaltyScore = awayPenaltyScore
        self.status = status
        self.minute = minute
        self.statusElapsed = statusElapsed
        self.statusExtra = statusExtra
        self.lastUpdated = lastUpdated
        self.competition = competition
        self.venue = venue
        self.date = date
        self.statusShort = statusShort
    }
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

extension Game {
    var displayMinute: String {
        guard status == .live else { return minute }

        let statusUpper = statusShort.uppercased()
        if statusUpper == "HT" || statusUpper == "BT" || statusUpper == "P" {
            return minute
        }

        let totalElapsed = effectiveElapsedMinutes()
        guard totalElapsed > 0 else {
            return minute.isEmpty ? statusShort : minute
        }

        return Game.formatMinute(statusShort: statusShort, elapsed: totalElapsed)
    }

    func effectiveElapsedMinutes() -> Int {
        let statusUpper = statusShort.uppercased()
        let hasElapsed = statusElapsed > 0 || statusExtra > 0
        let shouldTick = hasElapsed && (statusUpper == "1H" || statusUpper == "2H" || statusUpper == "ET" || statusUpper == "LIVE")
        let deltaMinutes = shouldTick ? max(Int(Date().timeIntervalSince(lastUpdated) / 60.0), 0) : 0
        return max(statusElapsed + statusExtra + deltaMinutes, 0)
    }

    static func formatMinute(statusShort: String, elapsed: Int) -> String {
        let statusUpper = statusShort.uppercased()
        if statusUpper == "1H" && elapsed > 45 {
            return "45'+\(elapsed - 45)"
        }
        if statusUpper == "2H" && elapsed > 90 {
            return "90'+\(elapsed - 90)"
        }
        if statusUpper == "ET" {
            return "\(elapsed)'"
        }
        return "\(elapsed)'"
    }
}
