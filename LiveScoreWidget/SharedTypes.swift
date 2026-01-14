import Foundation

// Shared types for both app and widget extension
struct LiveMatchWidgetSnapshot: Codable, Equatable {
    let fixtureID: Int32
    let homeTeam: String
    let awayTeam: String
    let competition: String
    let homeScore: Int
    let awayScore: Int
    let status: String
    let elapsedSeconds: Int
    let lastUpdated: Date
    let homeLogoPath: String?
    let awayLogoPath: String?
    let homeGoalEvents: [String]
    let awayGoalEvents: [String]
    let fixtureTimestamp: Int?
}
