//
//  Live Activity attributes for live match score updates
//

import ActivityKit
import Foundation

/// Attributes for the Live Score Live Activity
/// These are set once when the activity starts and cannot be changed
struct LiveScoreActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that updates during the match
        var homeScore: Int32
        var awayScore: Int32
        var status: String  // "1H", "HT", "2H", "FT", etc.
        var elapsed: Int32  // Minutes elapsed
        var lastUpdateTime: Date
        var firstPeriodStart: Date?
        var secondPeriodStart: Date?
        var homeTeamLogoPath: String?
        var awayTeamLogoPath: String?
        var homeGoalEvents: [String]
        var awayGoalEvents: [String]
    }

    // Static attributes (set once, never change)
    let fixtureID: Int32
    let homeTeam: String
    let awayTeam: String
    let competition: String  // e.g., "Champions League"
    let matchDate: Date
}
