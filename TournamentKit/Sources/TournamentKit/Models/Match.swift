import Foundation

public struct Game: Identifiable {
    public let id: Int
    public let homeTeam: String
    public let awayTeam: String
    public let homeTeamId: Int
    public let awayTeamId: Int
    public let homeScore: Int
    public let awayScore: Int
    public let homePenaltyScore: Int?
    public let awayPenaltyScore: Int?
    public let status: MatchStatus
    public let minute: String
    public let statusElapsed: Int
    public let statusExtra: Int
    public let lastUpdated: Date
    public let competition: String
    public let venue: String
    public let date: Date
    public let statusShort: String

    public init(
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

public enum MatchStatus {
    case live
    case finished
    case upcoming
}

// MARK: - Team Flag Support
extension Game {
    /// Returns the asset name for the home team's flag
    public var homeTeamFlagAsset: String? {
        TeamFlagMapper.flagAssetName(for: homeTeamId)
    }

    /// Returns the asset name for the away team's flag
    public var awayTeamFlagAsset: String? {
        TeamFlagMapper.flagAssetName(for: awayTeamId)
    }
}

extension Game {
    public var displayMinute: String {
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

    public func effectiveElapsedMinutes() -> Int {
        let statusUpper = statusShort.uppercased()
        let hasElapsed = statusElapsed > 0 || statusExtra > 0
        let shouldTick = hasElapsed && (statusUpper == "1H" || statusUpper == "2H" || statusUpper == "ET" || statusUpper == "LIVE")
        let deltaMinutes = shouldTick ? max(Int(Date().timeIntervalSince(lastUpdated) / 60.0), 0) : 0
        let raw = max(statusElapsed + statusExtra + deltaMinutes, 0)
        // Cap per period so the timer freezes rather than overflowing during status transitions
        switch statusUpper {
        case "ET":   return min(raw, 120)
        case "2H":   return min(raw, 110)
        case "1H":   return min(raw, 60)
        default:     return raw
        }
    }

    public static func formatMinute(statusShort: String, elapsed: Int) -> String {
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
