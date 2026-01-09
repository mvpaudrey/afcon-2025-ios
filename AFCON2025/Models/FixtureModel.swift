import Foundation
import SwiftData

/// SwiftData model for storing AFCON fixtures locally
@Model
final class FixtureModel {
    var id: Int
    var referee: String
    var timezone: String
    var date: Date
    var timestamp: Int

    // Venue
    var venueId: Int
    var venueName: String
    var venueCity: String

    // Status
    var statusLong: String
    var statusShort: String
    var statusElapsed: Int
    var statusExtra: Int

    // Teams
    var homeTeamId: Int
    var homeTeamName: String
    var homeTeamLogo: String
    var homeTeamWinner: Bool

    var awayTeamId: Int
    var awayTeamName: String
    var awayTeamLogo: String
    var awayTeamWinner: Bool

    // Goals
    var homeGoals: Int
    var awayGoals: Int

    // Score details
    var halftimeHome: Int
    var halftimeAway: Int
    var fulltimeHome: Int
    var fulltimeAway: Int
    var penaltyHome: Int
    var penaltyAway: Int

    // Additional metadata
    var competition: String
    var round: String?
    var lastUpdated: Date

    init(
        id: Int,
        referee: String = "",
        timezone: String = "",
        date: Date,
        timestamp: Int,
        venueId: Int,
        venueName: String,
        venueCity: String,
        statusLong: String,
        statusShort: String,
        statusElapsed: Int,
        statusExtra: Int = 0,
        homeTeamId: Int,
        homeTeamName: String,
        homeTeamLogo: String,
        homeTeamWinner: Bool,
        awayTeamId: Int,
        awayTeamName: String,
        awayTeamLogo: String,
        awayTeamWinner: Bool,
        homeGoals: Int,
        awayGoals: Int,
        halftimeHome: Int,
        halftimeAway: Int,
        fulltimeHome: Int,
        fulltimeAway: Int,
        penaltyHome: Int = 0,
        penaltyAway: Int = 0,
        competition: String,
        round: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.referee = referee
        self.timezone = timezone
        self.date = date
        self.timestamp = timestamp
        self.venueId = venueId
        self.venueName = venueName
        self.venueCity = venueCity
        self.statusLong = statusLong
        self.statusShort = statusShort
        self.statusElapsed = statusElapsed
        self.statusExtra = statusExtra
        self.homeTeamId = homeTeamId
        self.homeTeamName = homeTeamName
        self.homeTeamLogo = homeTeamLogo
        self.homeTeamWinner = homeTeamWinner
        self.awayTeamId = awayTeamId
        self.awayTeamName = awayTeamName
        self.awayTeamLogo = awayTeamLogo
        self.awayTeamWinner = awayTeamWinner
        self.homeGoals = homeGoals
        self.awayGoals = awayGoals
        self.halftimeHome = halftimeHome
        self.halftimeAway = halftimeAway
        self.fulltimeHome = fulltimeHome
        self.fulltimeAway = fulltimeAway
        self.penaltyHome = penaltyHome
        self.penaltyAway = penaltyAway
        self.competition = competition
        self.round = round
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Convenience Properties
extension FixtureModel {
    var isLive: Bool {
        ["LIVE", "1H", "2H", "HT", "ET", "P"].contains(statusShort)
    }

    var isFinished: Bool {
        ["FT", "AET", "PEN"].contains(statusShort)
    }

    var isUpcoming: Bool {
        !isLive && !isFinished
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var fullVenue: String {
        venueCity.isEmpty ? venueName : "\(venueName), \(venueCity)"
    }

    /// Convert FixtureModel to Game for UI display
    @MainActor func toGame() -> Game {
        let status: MatchStatus
        switch statusShort {
        case "LIVE", "1H", "2H", "HT", "ET", "P":
            status = .live
        case "FT", "AET", "PEN":
            status = .finished
        default:
            status = .upcoming
        }

        // Display minute with extra time from API
        let minute: String
        if statusElapsed > 0 {
            if statusExtra > 0 {
                // Use the extra time provided by the API
                minute = "\(statusElapsed)'+\(statusExtra)"
            } else {
                // Calculate extra time if elapsed exceeds normal period limits
                let statusUpper = statusShort.uppercased()
                if statusUpper == "1H" && statusElapsed > 45 {
                    // First half extra time
                    let extraTime = statusElapsed - 45
                    minute = "45'+\(extraTime)"
                } else if statusUpper == "2H" && statusElapsed > 90 {
                    // Second half extra time
                    let extraTime = statusElapsed - 90
                    minute = "90'+\(extraTime)"
                } else if statusUpper == "ET" && statusElapsed > 105 {
                    // First half of extra time
                    let extraTime = statusElapsed - 105
                    minute = "105'+\(extraTime)"
                } else if statusUpper == "ET" && statusElapsed > 120 {
                    // Second half of extra time
                    let extraTime = statusElapsed - 120
                    minute = "120'+\(extraTime)"
                } else {
                    minute = "\(statusElapsed)'"
                }
            }
        } else {
            minute = statusShort
        }

        return Game(
            id: id,
            homeTeam: homeTeamName,
            awayTeam: awayTeamName,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            homeScore: homeGoals,
            awayScore: awayGoals,
            homePenaltyScore: penaltyHome > 0 ? penaltyHome : nil,
            awayPenaltyScore: penaltyAway > 0 ? penaltyAway : nil,
            status: status,
            minute: minute,
            statusElapsed: statusElapsed,
            statusExtra: statusExtra,
            lastUpdated: lastUpdated,
            competition: competition,
            venue: fullVenue,
            date: date,
            statusShort: statusShort
        )
    }
}

