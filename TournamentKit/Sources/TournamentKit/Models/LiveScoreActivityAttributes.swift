//
//  Live Activity attributes for live match score updates
//

import ActivityKit
import Foundation

/// Attributes for the Live Score Live Activity
/// These are set once when the activity starts and cannot be changed
public struct LiveScoreActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        // Dynamic state that updates during the match
        public var homeScore: Int32
        public var awayScore: Int32
        public var status: String  // "1H", "HT", "2H", "FT", etc.
        public var elapsed: Int32  // Minutes elapsed
        public var lastUpdateTime: Date
        public var firstPeriodStart: Date?
        public var secondPeriodStart: Date?
        public var homeTeamLogoPath: String?
        public var awayTeamLogoPath: String?
        public var homeGoalEvents: [String]
        public var awayGoalEvents: [String]

        public init(
            homeScore: Int32,
            awayScore: Int32,
            status: String,
            elapsed: Int32,
            lastUpdateTime: Date,
            firstPeriodStart: Date? = nil,
            secondPeriodStart: Date? = nil,
            homeTeamLogoPath: String? = nil,
            awayTeamLogoPath: String? = nil,
            homeGoalEvents: [String] = [],
            awayGoalEvents: [String] = []
        ) {
            self.homeScore = homeScore
            self.awayScore = awayScore
            self.status = status
            self.elapsed = elapsed
            self.lastUpdateTime = lastUpdateTime
            self.firstPeriodStart = firstPeriodStart
            self.secondPeriodStart = secondPeriodStart
            self.homeTeamLogoPath = homeTeamLogoPath
            self.awayTeamLogoPath = awayTeamLogoPath
            self.homeGoalEvents = homeGoalEvents
            self.awayGoalEvents = awayGoalEvents
        }
    }

    // Static attributes (set once, never change)
    public let fixtureID: Int32
    public let homeTeam: String
    public let awayTeam: String
    public let competition: String  // e.g., "Champions League"
    public let matchDate: Date

    public init(fixtureID: Int32, homeTeam: String, awayTeam: String, competition: String, matchDate: Date) {
        self.fixtureID = fixtureID
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.competition = competition
        self.matchDate = matchDate
    }
}
