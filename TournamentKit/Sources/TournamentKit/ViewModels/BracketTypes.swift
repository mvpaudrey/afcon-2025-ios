import Foundation

// MARK: - Round Selection
public enum BracketRound: String, CaseIterable {
    case roundOf16 = "Round of 16"
    case quarterFinals = "Quarter Finals"
    case semiFinals = "Semi Finals"
    case final = "Final"

    public var localizedKey: String {
        self.rawValue
    }
}

// MARK: - Bracket Match Model
public struct BracketMatch: Sendable {
    public let id: Int
    public let date: String
    public let time: String
    public let team1: String
    public let team2: String
    public let team1Id: Int?
    public let team2Id: Int?
    public let venue: String
    public let score1: Int?
    public let score2: Int?
    public var penalty1: Int? = nil
    public var penalty2: Int? = nil

    public init(
        id: Int,
        date: String,
        time: String,
        team1: String,
        team2: String,
        team1Id: Int?,
        team2Id: Int?,
        venue: String,
        score1: Int?,
        score2: Int?,
        penalty1: Int? = nil,
        penalty2: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.time = time
        self.team1 = team1
        self.team2 = team2
        self.team1Id = team1Id
        self.team2Id = team2Id
        self.venue = venue
        self.score1 = score1
        self.score2 = score2
        self.penalty1 = penalty1
        self.penalty2 = penalty2
    }
}

// MARK: - Bracket Matches Container
public struct BracketMatches: Sendable {
    public let roundOf16: [BracketMatch]
    public let quarterFinals: [BracketMatch]
    public let semiFinals: [BracketMatch]
    public let final: BracketMatch
    public let thirdPlace: BracketMatch

    public init(
        roundOf16: [BracketMatch],
        quarterFinals: [BracketMatch],
        semiFinals: [BracketMatch],
        final: BracketMatch,
        thirdPlace: BracketMatch
    ) {
        self.roundOf16 = roundOf16
        self.quarterFinals = quarterFinals
        self.semiFinals = semiFinals
        self.final = final
        self.thirdPlace = thirdPlace
    }
}

// MARK: - Bracket Static Data
public struct BracketData {
    public static let allMatches = BracketMatches(
        roundOf16: [
            // 37: 3 January - Tangier, 17:00
            BracketMatch(id: 37, date: "2026-01-03", time: "17:00", team1: "1D", team2: "3B/E/F", team1Id: nil, team2Id: nil, venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // 38: 3 January - Casablanca, 20:00
            BracketMatch(id: 38, date: "2026-01-03", time: "20:00", team1: "2A", team2: "2C", team1Id: nil, team2Id: nil, venue: "Mohammed V Stadium, Casablanca", score1: nil, score2: nil),
            // 39: 4 January - Rabat, 17:00
            BracketMatch(id: 39, date: "2026-01-04", time: "17:00", team1: "1A", team2: "3C/D/E", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
            // 40: 4 January - Rabat, 20:00
            BracketMatch(id: 40, date: "2026-01-04", time: "20:00", team1: "2B", team2: "2F", team1Id: nil, team2Id: nil, venue: "Al Barid Stadium, Rabat", score1: nil, score2: nil),
            // 42: 5 January - Fez, 20:00
            BracketMatch(id: 42, date: "2026-01-05", time: "20:00", team1: "1C", team2: "3A/B/F", team1Id: nil, team2Id: nil, venue: "Fez Stadium, Fez", score1: nil, score2: nil),
            // 43: 6 January - Rabat, 17:00
            BracketMatch(id: 43, date: "2026-01-06", time: "17:00", team1: "1E", team2: "2D", team1Id: nil, team2Id: nil, venue: "Moulay Hassan Stadium, Rabat", score1: nil, score2: nil),
            // 41: 5 January - Agadir, 17:00
            BracketMatch(id: 41, date: "2026-01-05", time: "17:00", team1: "1B", team2: "3A/C/D", team1Id: nil, team2Id: nil, venue: "Adrar Stadium, Agadir", score1: nil, score2: nil),
            // 44: 6 January - Marrakesh, 20:00
            BracketMatch(id: 44, date: "2026-01-06", time: "20:00", team1: "1F", team2: "2E", team1Id: nil, team2Id: nil, venue: "Marrakesh Stadium, Marrakesh", score1: nil, score2: nil)
        ],
        quarterFinals: [
            // 45: 9 January - Tangier, 17:00
            BracketMatch(id: 45, date: "2026-01-09", time: "17:00", team1: "W38", team2: "W37", team1Id: nil, team2Id: nil, venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // 46: 9 January - Rabat, 20:00
            BracketMatch(id: 46, date: "2026-01-09", time: "20:00", team1: "W40", team2: "W39", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
            // 47: 10 January - Marrakesh, 17:00
            BracketMatch(id: 47, date: "2026-01-10", time: "17:00", team1: "W43", team2: "W42", team1Id: nil, team2Id: nil, venue: "Marrakesh Stadium, Marrakesh", score1: nil, score2: nil),
            // 48: 10 January - Agadir, 20:00
            BracketMatch(id: 48, date: "2026-01-10", time: "20:00", team1: "W41", team2: "W44", team1Id: nil, team2Id: nil, venue: "Adrar Stadium, Agadir", score1: nil, score2: nil)
        ],
        semiFinals: [
            // 49: 14 January - Tangier, 18:00
            BracketMatch(id: 49, date: "2026-01-14", time: "18:00", team1: "W45", team2: "W48", team1Id: nil, team2Id: nil, venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // 50: 14 January - Rabat, 21:00
            BracketMatch(id: 50, date: "2026-01-14", time: "21:00", team1: "W46", team2: "W47", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil)
        ],
        // Final: 18 January - Rabat, 20:00
        final: BracketMatch(id: 52, date: "2026-01-18", time: "20:00", team1: "W49", team2: "W50", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
        // Third Place: 17 January - Casablanca, 17:00
        thirdPlace: BracketMatch(id: 51, date: "2026-01-17", time: "17:00", team1: "L49", team2: "L50", team1Id: nil, team2Id: nil, venue: "Mohammed V Stadium, Casablanca", score1: nil, score2: nil)
    )
}
