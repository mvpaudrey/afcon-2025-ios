import Foundation

// Shared type for both app and widget extension
public struct LiveMatchWidgetSnapshot: Codable, Equatable, Sendable {
    public let fixtureID: Int32
    public let homeTeam: String
    public let awayTeam: String
    public let competition: String
    public let homeScore: Int
    public let awayScore: Int
    public let status: String
    public let elapsedSeconds: Int
    public let lastUpdated: Date
    public let homeLogoPath: String?
    public let awayLogoPath: String?
    public let homeGoalEvents: [String]
    public let awayGoalEvents: [String]
    public let fixtureTimestamp: Int?

    public init(
        fixtureID: Int32,
        homeTeam: String,
        awayTeam: String,
        competition: String,
        homeScore: Int,
        awayScore: Int,
        status: String,
        elapsedSeconds: Int,
        lastUpdated: Date,
        homeLogoPath: String? = nil,
        awayLogoPath: String? = nil,
        homeGoalEvents: [String] = [],
        awayGoalEvents: [String] = [],
        fixtureTimestamp: Int? = nil
    ) {
        self.fixtureID = fixtureID
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.competition = competition
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.status = status
        self.elapsedSeconds = elapsedSeconds
        self.lastUpdated = lastUpdated
        self.homeLogoPath = homeLogoPath
        self.awayLogoPath = awayLogoPath
        self.homeGoalEvents = homeGoalEvents
        self.awayGoalEvents = awayGoalEvents
        self.fixtureTimestamp = fixtureTimestamp
    }
}
