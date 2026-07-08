import Foundation
import Observation
import AFCONClient

/// Wrapper around AFCONClient for SwiftUI @Observable support
@Observable
public class TournamentServiceWrapper: @unchecked Sendable {
    nonisolated(unsafe) public static let defaultHost = ProcessInfo.processInfo.environment["AFCON_API_HOST"]
        ?? "production-grpc-nlb-3fc4bc51bc4f783c.elb.eu-west-3.amazonaws.com"
    nonisolated(unsafe) public static let defaultPort = Int(ProcessInfo.processInfo.environment["AFCON_API_PORT"] ?? "") ?? 50051

    private let service: AFCONService

    public init(host: String = TournamentServiceWrapper.defaultHost, port: Int = TournamentServiceWrapper.defaultPort) {
        self.service = AFCONService(host: host, port: port)
    }

    private var config: any TournamentConfig { TournamentConfigStore.current }

    // MARK: - API Methods (delegate to AFCONClient service)

    /// Get league information
    public func getLeague(
        leagueId: Int32? = nil, season: Int32? = nil
    ) async throws -> Afcon_LeagueResponse {
        return try await service.getLeague(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season
        )
    }

    /// Get all teams
    public func getTeams(
        leagueId: Int32? = nil, season: Int32? = nil
    ) async throws -> [Afcon_TeamInfo] {
        return try await service.getTeams(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season
        )
    }

    /// Get fixtures
    public func getFixtures(
        leagueId: Int32? = nil,
        season: Int32? = nil,
        date: String? = nil,
        teamId: Int32? = nil,
        live: Bool = false
    ) async throws -> [Afcon_Fixture] {
        return try await service.getFixtures(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season,
            date: date,
            teamId: teamId,
            live: live
        )
    }

    /// Get live fixtures
    public func getLiveFixtures(leagueId: Int32? = nil) async throws -> [Afcon_Fixture] {
        return try await service.getLiveFixtures(leagueId: leagueId ?? config.leagueId)
    }

    public func getFixturesByDate(
        leagueId: Int32? = nil,
        season: Int32? = nil,
        date: String
    ) async throws -> [Afcon_Fixture] {
        return try await service.getFixturesByDate(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season,
            date: date
        )
    }

    /// Get team details
    public func getTeamDetails(teamId: Int32) async throws -> Afcon_TeamDetailsResponse {
        return try await service.getTeamDetails(teamId: teamId)
    }

    /// Get standings
    public func getStandings(
        leagueId: Int32? = nil, season: Int32? = nil
    ) async throws -> Afcon_StandingsResponse {
        return try await service.getStandings(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season
        )
    }

    /// Get standings parsed into TournamentKit types — no AFCONClient import needed by callers.
    /// Supports all group letters (A–Z) for multi-group tournaments like FWC2026.
    public func getParsedStandings(
        leagueId: Int32? = nil, season: Int32? = nil
    ) async throws -> (groups: [String: [Team]], thirdPlace: [Team]) {
        let response = try await getStandings(leagueId: leagueId, season: season)

        var groupStandings: [String: [Team]] = [:]
        var thirdPlaceTeams: [Team] = []

        for standingGroup in response.groups {
            let teams = standingGroup.standings.map { standing in
                Team(
                    name: standing.team.name,
                    teamId: Int(standing.team.id),
                    played: Int(standing.all.played),
                    won: Int(standing.all.win),
                    drawn: Int(standing.all.draw),
                    lost: Int(standing.all.lose),
                    gf: Int(standing.all.goals.for),
                    ga: Int(standing.all.goals.against),
                    points: Int(standing.points),
                    position: Int(standing.rank),
                    groupName: standing.group
                )
            }

            let lowercasedName = standingGroup.groupName.lowercased()
            if lowercasedName.contains("third") || lowercasedName.contains("3rd") ||
               lowercasedName.contains("troisième") {
                thirdPlaceTeams = teams
            } else if let letter = groupLetterFromName(standingGroup.groupName) {
                groupStandings[letter] = teams
            }
        }

        return (groupStandings, thirdPlaceTeams)
    }

    private func groupLetterFromName(_ name: String) -> String? {
        let pattern = "(?:group|groupe)\\s*([A-Z])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        guard let match = regex.firstMatch(in: name, options: [], range: range),
              match.numberOfRanges > 1,
              let letterRange = Range(match.range(at: 1), in: name) else {
            return nil
        }
        return String(name[letterRange]).uppercased()
    }

    /// Get fixture lineups
    public func getLineups(fixtureId: Int32) async throws -> [Afcon_FixtureLineup] {
        return try await service.getLineups(fixtureId: fixtureId)
    }

    public func getFixtureEvents(fixtureId: Int32) async throws -> [Afcon_FixtureEvent] {
        return try await service.getFixtureEvents(fixtureId: fixtureId)
    }

    /// Stream live match updates
    public func streamLiveMatches(
        leagueId: Int32? = nil,
        season: Int32? = nil,
        onUpdate: @escaping @Sendable (Afcon_LiveMatchUpdate) -> Void
    ) async throws {
        try await service.streamLiveMatches(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season,
            onUpdate: onUpdate
        )
    }

    /// Sync fixtures to server database (admin operation)
    public func syncFixtures(
        leagueId: Int32? = nil,
        season: Int32? = nil,
        competition: String? = nil
    ) async throws -> Afcon_SyncFixturesResponse {
        return try await service.syncFixtures(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season,
            competition: competition ?? config.competitionName
        )
    }

    // MARK: - Push Notifications & Subscriptions

    /// Register device for push notifications
    public func registerDevice(
        userId: String,
        deviceToken: String,
        deviceId: String,
        appVersion: String,
        osVersion: String,
        language: String = "en",
        timezone: String = TimeZone.current.identifier
    ) async throws -> Afcon_RegisterDeviceResponse {
        return try await service.registerDevice(
            userId: userId,
            deviceToken: deviceToken,
            platform: "ios",
            deviceId: deviceId,
            appVersion: appVersion,
            osVersion: osVersion,
            language: language,
            timezone: timezone
        )
    }

    /// Update favorite team subscription
    public func updateFavoriteTeam(
        deviceUuid: String,
        favoriteTeamId: Int32,
        leagueId: Int32? = nil,
        season: Int32? = nil
    ) async throws -> Afcon_UpdateSubscriptionsResponse {
        return try await updateFavoriteTeams(
            deviceUuid: deviceUuid,
            favoriteTeamIds: [favoriteTeamId],
            leagueId: leagueId,
            season: season
        )
    }

    /// Update favorite team subscriptions for multiple teams
    public func updateFavoriteTeams(
        deviceUuid: String,
        favoriteTeamIds: [Int32],
        leagueId: Int32? = nil,
        season: Int32? = nil
    ) async throws -> Afcon_UpdateSubscriptionsResponse {
        let resolvedLeagueId = leagueId ?? config.leagueId
        let resolvedSeason = season ?? config.season
        let subscriptions = favoriteTeamIds.map {
            makeFavoriteTeamSubscription(teamId: $0, leagueId: resolvedLeagueId, season: resolvedSeason)
        }

        return try await service.updateSubscriptions(
            deviceUuid: deviceUuid,
            subscriptions: subscriptions
        )
    }

    private func makeFavoriteTeamSubscription(
        teamId: Int32,
        leagueId: Int32,
        season: Int32
    ) -> Afcon_Subscription {
        var subscription = Afcon_Subscription()
        subscription.leagueID = leagueId
        subscription.season = season
        subscription.teamID = teamId

        var preferences = Afcon_NotificationPreferences()
        preferences.notifyGoals = true
        preferences.notifyMatchStart = true
        preferences.notifyMatchEnd = true
        preferences.notifyRedCards = true
        preferences.notifyLineups = false
        preferences.notifyVar = false
        preferences.matchStartMinutesBefore = 15

        subscription.preferences = preferences
        return subscription
    }

    /// Get current subscriptions for device
    public func getSubscriptions(deviceUuid: String) async throws -> Afcon_GetSubscriptionsResponse {
        return try await service.getSubscriptions(deviceUuid: deviceUuid)
    }

    /// Start a Live Activity for a specific match
    public func startLiveActivity(
        deviceUuid: String,
        fixtureId: Int32,
        activityId: String,
        pushToken: String,
        updateFrequency: String = "all_events"
    ) async throws -> Afcon_StartLiveActivityResponse {
        return try await service.startLiveActivity(
            deviceUuid: deviceUuid,
            fixtureId: fixtureId,
            activityId: activityId,
            pushToken: pushToken,
            updateFrequency: updateFrequency
        )
    }

    /// End a Live Activity
    public func endLiveActivity(activityUuid: String) async throws -> Afcon_EndLiveActivityResponse {
        return try await service.endLiveActivity(activityUuid: activityUuid)
    }
}

// MARK: - Shared Instance
extension TournamentServiceWrapper {
    nonisolated(unsafe) public static let shared = TournamentServiceWrapper()
}
