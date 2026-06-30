import Foundation
import SwiftData
import AFCONClient

/// SwiftData model for storing fixture events (goals, cards, substitutions, etc.)
@Model
public final class FixtureEventModel {
    // Composite ID: fixtureId + timeElapsed + playerName ensures uniqueness
    public var id: String

    // Fixture relationship
    public var fixtureId: Int

    // Time information
    public var timeElapsed: Int
    public var timeExtra: Int

    // Team information
    public var teamId: Int
    public var teamName: String
    public var teamLogo: String

    // Player information
    public var playerId: Int
    public var playerName: String

    // Assist information
    public var assistId: Int
    public var assistName: String

    // Event details
    public var eventType: String  // "Goal", "Card", "subst", "Var"
    public var eventDetail: String  // "Normal Goal", "Yellow Card", etc.
    public var comments: String

    // Metadata
    public var createdAt: Date

    public init(
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
    public func toAfconFixtureEvent() -> Afcon_FixtureEvent {
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
    public static func from(_ grpcEvent: Afcon_FixtureEvent, fixtureId: Int) -> FixtureEventModel {
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
    public var isGoal: Bool {
        eventType.lowercased() == "goal"
    }

    public var isCard: Bool {
        eventType.lowercased() == "card"
    }

    public var isSubstitution: Bool {
        eventType.lowercased() == "subst"
    }

    public var isVAR: Bool {
        eventType.lowercased() == "var"
    }
}
