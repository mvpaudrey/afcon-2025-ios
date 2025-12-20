import Foundation
import AFCONClient
internal import SwiftProtobuf

// MARK: - Convert gRPC Fixture to FixtureModel (SwiftData)
extension Afcon_Fixture {
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
            competition: "AFCON 2025"
        )
    }
}

// MARK: - Convert gRPC Fixture to Game model
extension Afcon_Fixture {
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

        let minute = self.status.elapsed > 0 ? "\(self.status.elapsed)'" : self.status.short

        // Get the date from the fixture
        let fixtureDate: Date
        if self.hasDate {
            fixtureDate = Date(timeIntervalSince1970: TimeInterval(self.date.seconds))
        } else {
            fixtureDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp))
        }

        return Game(
            id: Int(self.id),
            homeTeam: self.teams.home.name,
            awayTeam: self.teams.away.name,
            homeTeamId: Int(self.teams.home.id),
            awayTeamId: Int(self.teams.away.id),
            homeScore: Int(self.goals.home),
            awayScore: Int(self.goals.away),
            status: status,
            minute: minute,
            competition: "African Cup of Nations",
            venue: self.venue.name.isEmpty ? "TBD" : "\(self.venue.name), \(self.venue.city)",
            date: fixtureDate,
            statusShort: self.status.short
        )
    }
}

// MARK: - Convert array of fixtures
extension Array where Element == Afcon_Fixture {
    func toGames() -> [Game] {
        return self.map { $0.toGame() }
    }
}

// MARK: - Team extensions
extension Afcon_Team {
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
extension Afcon_FixtureStatus {
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
