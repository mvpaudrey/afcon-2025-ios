import Foundation
import AFCONClient
internal import SwiftProtobuf

// MARK: - Convert gRPC Fixture to FixtureModel (SwiftData)
public extension Afcon_Fixture {
    func toFixtureModel() -> FixtureModel {
        // Convert Google Protobuf Timestamp to Foundation Date
        let fixtureDate: Date
        if self.hasDate {
            fixtureDate = Date(timeIntervalSince1970: TimeInterval(self.date.seconds))
        } else {
            // Fallback to timestamp
            fixtureDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp))
        }

        return FixtureModel(
            id: Int(self.id),
            referee: self.referee,
            timezone: self.timezone,
            date: fixtureDate,
            timestamp: Int(self.timestamp),
            venueId: Int(self.venue.id),
            venueName: self.venue.name,
            venueCity: self.venue.city,
            statusLong: self.status.long,
            statusShort: self.status.short,
            statusElapsed: Int(self.status.elapsed),
            statusExtra: Int(self.status.extra),
            homeTeamId: Int(self.teams.home.id),
            homeTeamName: self.teams.home.name,
            homeTeamLogo: self.teams.home.logo,
            homeTeamWinner: self.teams.home.winner,
            awayTeamId: Int(self.teams.away.id),
            awayTeamName: self.teams.away.name,
            awayTeamLogo: self.teams.away.logo,
            awayTeamWinner: self.teams.away.winner,
            homeGoals: Int(self.goals.home),
            awayGoals: Int(self.goals.away),
            halftimeHome: Int(self.score.halftime.home),
            halftimeAway: Int(self.score.halftime.away),
            fulltimeHome: Int(self.score.fulltime.home),
            fulltimeAway: Int(self.score.fulltime.away),
            penaltyHome: Int(self.score.penalty.home),
            penaltyAway: Int(self.score.penalty.away),
            competition: "AFCON 2025",
            round: nil  // Round info not available from gRPC API
        )
    }
}

// MARK: - Convert gRPC Fixture to Game model
public extension Afcon_Fixture {
    func toGame() -> Game {
        let status: MatchStatus
        switch self.status.short {
        case "LIVE", "1H", "2H", "HT", "ET", "P":
            status = .live
        case "FT", "AET", "PEN":
            status = .finished
        default:
            status = .upcoming
        }

        // Display minute with extra time from API
        let minute: String
        if self.status.elapsed > 0 {
            let statusUpper = self.status.short.uppercased()
            if statusUpper == "ET" {
                let totalElapsed = Int(self.status.elapsed) + Int(self.status.extra)
                minute = "\(totalElapsed)'"
            } else if self.status.extra > 0 {
                // Use the extra time provided by the API
                minute = "\(self.status.elapsed)'+\(self.status.extra)"
            } else {
                // Calculate extra time if elapsed exceeds normal period limits
                if statusUpper == "1H" && self.status.elapsed > 45 {
                    // First half extra time
                    let extraTime = self.status.elapsed - 45
                    minute = "45'+\(extraTime)"
                } else if statusUpper == "2H" && self.status.elapsed > 90 {
                    // Second half extra time
                    let extraTime = self.status.elapsed - 90
                    minute = "90'+\(extraTime)"
                } else if statusUpper == "ET" && self.status.elapsed > 105 {
                    // First half of extra time
                    let extraTime = self.status.elapsed - 105
                    minute = "105'+\(extraTime)"
                } else if statusUpper == "ET" && self.status.elapsed > 120 {
                    // Second half of extra time
                    let extraTime = self.status.elapsed - 120
                    minute = "120'+\(extraTime)"
                } else {
                    minute = "\(self.status.elapsed)'"
                }
            }
        } else {
            minute = self.status.short
        }

        // Get the date from the fixture
        let fixtureDate: Date
        if self.hasDate {
            fixtureDate = Date(timeIntervalSince1970: TimeInterval(self.date.seconds))
        } else {
            fixtureDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp))
        }

        return Game(
            id: Int(self.id),
            homeTeam: localizedTeamName(self.teams.home.name),
            awayTeam: localizedTeamName(self.teams.away.name),
            homeTeamId: Int(self.teams.home.id),
            awayTeamId: Int(self.teams.away.id),
            homeScore: Int(self.goals.home),
            awayScore: Int(self.goals.away),
            homePenaltyScore: self.score.penalty.home > 0 ? Int(self.score.penalty.home) : nil,
            awayPenaltyScore: self.score.penalty.away > 0 ? Int(self.score.penalty.away) : nil,
            status: status,
            minute: minute,
            statusElapsed: Int(self.status.elapsed),
            statusExtra: Int(self.status.extra),
            lastUpdated: Date(),
            competition: "AFCON 2025",
            venue: self.venue.name.isEmpty ? "TBD" : "\(self.venue.name), \(self.venue.city)",
            date: fixtureDate,
            statusShort: self.status.short
        )
    }
}

// MARK: - Convert array of fixtures
public extension Array where Element == Afcon_Fixture {
    func toGames() -> [Game] {
        return self.map { $0.toGame() }
    }
}

// MARK: - Team extensions
public extension Afcon_Team {
    var flagEmoji: String {
        // Map country names to flag emojis
        let countryFlags: [String: String] = [
            "Senegal": "🇸🇳",
            "Nigeria": "🇳🇬",
            "Morocco": "🇲🇦",
            "Egypt": "🇪🇬",
            "Algeria": "🇩🇿",
            "Tunisia": "🇹🇳",
            "Cameroon": "🇨🇲",
            "Ghana": "🇬🇭",
            "Ivory Coast": "🇨🇮",
            "Mali": "🇲🇱",
            "Burkina Faso": "🇧🇫",
            "Guinea": "🇬🇳",
            "South Africa": "🇿🇦",
            "Gabon": "🇬🇦",
            "DR Congo": "🇨🇩",
            "Angola": "🇦🇴",
            "Zambia": "🇿🇲",
            "Mozambique": "🇲🇿",
            "Tanzania": "🇹🇿",
            "Botswana": "🇧🇼",
            "Zimbabwe": "🇿🇼",
            "Comoros": "🇰🇲",
            "Uganda": "🇺🇬",
            "Sudan": "🇸🇩"
        ]

        return countryFlags[self.country] ?? "🏴"
    }
}

// MARK: - Fixture Status helpers
public extension Afcon_FixtureStatus {
    var isLive: Bool {
        ["LIVE", "1H", "2H", "HT", "ET", "P"].contains(self.short)
    }

    var isFinished: Bool {
        ["FT", "AET", "PEN"].contains(self.short)
    }

    var isUpcoming: Bool {
        !isLive && !isFinished
    }
}
