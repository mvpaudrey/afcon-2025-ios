import Foundation
import SwiftData
import AFCONClient

/// SwiftData model for storing fixture events (goals, cards, substitutions, etc.)
@Model
final class FixtureEventModel {
    // Composite ID: fixtureId + timeElapsed + playerName ensures uniqueness
    var id: String

    // Fixture relationship
    var fixtureId: Int

    // Time information
    var timeElapsed: Int
    var timeExtra: Int

    // Team information
    var teamId: Int
    var teamName: String
    var teamLogo: String

    // Player information
    var playerId: Int
    var playerName: String

    // Assist information
    var assistId: Int
    var assistName: String

    // Event details
    var eventType: String  // "Goal", "Card", "subst", "Var"
    var eventDetail: String  // "Normal Goal", "Yellow Card", etc.
    var comments: String

    // Metadata
    var createdAt: Date

    init(
        fixtureId: Int,
        timeElapsed: Int,
        timeExtra: Int,
        teamId: Int,
        teamName: String,
        teamLogo: String,
        playerId: Int,
        playerName: String,
        assistId: Int,
        assistName: String,
        eventType: String,
        eventDetail: String,
        comments: String,
        createdAt: Date = Date()
    ) {
        // Create unique ID from fixture, time, and player
        self.id = "\(fixtureId)_\(timeElapsed)_\(playerName)_\(eventType)"

        self.fixtureId = fixtureId
        self.timeElapsed = timeElapsed
        self.timeExtra = timeExtra
        self.teamId = teamId
        self.teamName = teamName
        self.teamLogo = teamLogo
        self.playerId = playerId
        self.playerName = playerName
        self.assistId = assistId
        self.assistName = assistName
        self.eventType = eventType
        self.eventDetail = eventDetail
        self.comments = comments
        self.createdAt = createdAt
    }
}

// MARK: - Conversion Extensions

extension FixtureEventModel {
    /// Convert FixtureEventModel to Afcon_FixtureEvent for UI display
    func toAfconFixtureEvent() -> Afcon_FixtureEvent {
        var event = Afcon_FixtureEvent()

        // Time
        var time = Afcon_EventTime()
        time.elapsed = Int32(timeElapsed)
        time.extra = Int32(timeExtra)
        event.time = time

        // Team
        var team = Afcon_EventTeam()
        team.id = Int32(teamId)
        team.name = teamName
        team.logo = teamLogo
        event.team = team

        // Player
        var player = Afcon_EventPlayer()
        player.id = Int32(playerId)
        player.name = playerName
        event.player = player

        // Assist
        var assist = Afcon_EventPlayer()
        assist.id = Int32(assistId)
        assist.name = assistName
        event.assist = assist

        // Event details
        event.type = eventType
        event.detail = eventDetail
        event.comments = comments

        return event
    }

    /// Create FixtureEventModel from Afcon_FixtureEvent
    static func from(_ grpcEvent: Afcon_FixtureEvent, fixtureId: Int) -> FixtureEventModel {
        return FixtureEventModel(
            fixtureId: fixtureId,
            timeElapsed: Int(grpcEvent.time.elapsed),
            timeExtra: Int(grpcEvent.time.extra),
            teamId: Int(grpcEvent.team.id),
            teamName: grpcEvent.team.name,
            teamLogo: grpcEvent.team.logo,
            playerId: Int(grpcEvent.player.id),
            playerName: grpcEvent.player.name,
            assistId: Int(grpcEvent.assist.id),
            assistName: grpcEvent.assist.name,
            eventType: grpcEvent.type,
            eventDetail: grpcEvent.detail,
            comments: grpcEvent.comments
        )
    }
}

// MARK: - Convenience Properties

extension FixtureEventModel {
    var isGoal: Bool {
        eventType.lowercased() == "goal"
    }

    var isCard: Bool {
        eventType.lowercased() == "card"
    }

    var isSubstitution: Bool {
        eventType.lowercased() == "subst"
    }

    var isVAR: Bool {
        eventType.lowercased() == "var"
    }
}
