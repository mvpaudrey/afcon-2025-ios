 import Foundation
import Observation
import AFCONClient

/// Wrapper around AFCONClient for SwiftUI @Observable support
@Observable
class AFCONServiceWrapper {
    private static let defaultHost = ProcessInfo.processInfo.environment["AFCON_API_HOST"] ?? "staging-grpc-nlb-823dd7fe6a5be8b9.elb.eu-north-1.amazonaws.com"
    private static let defaultPort = Int(ProcessInfo.processInfo.environment["AFCON_API_PORT"] ?? "") ?? 50051

    private let service: AFCONService

    init(host: String = defaultHost, port: Int = defaultPort) {
        self.service = AFCONService(host: host, port: port)
    }

    // MARK: - API Methods (delegate to AFCONClient service)

    /// Get league information for AFCON
    func getLeague(leagueId: Int32 = 6, season: Int32 = 2025) async throws -> Afcon_LeagueResponse {
        return try await service.getLeague(leagueId: leagueId, season: season)
    }

    /// Get all teams for AFCON
    func getTeams(leagueId: Int32 = 6, season: Int32 = 2025) async throws -> [Afcon_TeamInfo] {
        return try await service.getTeams(leagueId: leagueId, season: season)
    }

    /// Get fixtures for AFCON
    func getFixtures(
        leagueId: Int32 = 6,
        season: Int32 = 2025,
        date: String? = nil,
        teamId: Int32? = nil,
        live: Bool = false
    ) async throws -> [Afcon_Fixture] {
        return try await service.getFixtures(
            leagueId: leagueId,
            season: season,
            date: date,
            teamId: teamId,
            live: live
        )
    }

    /// Get live fixtures
    func getLiveFixtures(leagueId: Int32 = 6) async throws -> [Afcon_Fixture] {
        return try await service.getLiveFixtures(leagueId: leagueId)
    }

    func getFixturesByDate(
        leagueId: Int32 = 6,
        season: Int32 = 2025,
        date: String
    ) async throws -> [Afcon_Fixture] {
        return try await service.getFixturesByDate(
            leagueId: leagueId,
            season: season,
            date: date
        )
    }

    /// Get team details
    func getTeamDetails(teamId: Int32) async throws -> Afcon_TeamDetailsResponse {
        return try await service.getTeamDetails(teamId: teamId)
    }

    /// Get standings
    func getStandings(leagueId: Int32 = 6, season: Int32 = 2025) async throws -> Afcon_StandingsResponse {
        return try await service.getStandings(leagueId: leagueId, season: season)
    }

    /// Get fixture lineups
    func getLineups(fixtureId: Int32) async throws -> [Afcon_FixtureLineup] {
        return try await service.getLineups(fixtureId: fixtureId)
    }

    func getFixtureEvents(fixtureId: Int32) async throws -> [Afcon_FixtureEvent] {
        return try await service.getFixtureEvents(fixtureId: fixtureId)
    }

    /// Stream live match updates
    func streamLiveMatches(
        leagueId: Int32 = 6,
        season: Int32 = 2025,
        onUpdate: @escaping @Sendable (Afcon_LiveMatchUpdate) -> Void
    ) async throws {
        try await service.streamLiveMatches(
            leagueId: leagueId,
            season: season,
            onUpdate: onUpdate
        )
    }

    /// Sync fixtures to server database (admin operation)
    func syncFixtures(
        leagueId: Int32 = 6,
        season: Int32 = 2025,
        competition: String = "AFCON 2025"
    ) async throws -> Afcon_SyncFixturesResponse {
        return try await service.syncFixtures(
            leagueId: leagueId,
            season: season,
            competition: competition
        )
    }

    // MARK: - Push Notifications & Subscriptions

    /// Register device for push notifications
    func registerDevice(
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

    /// Update favorite team subscription - call this when user changes their favorite team
    /// - Parameters:
    ///   - deviceUuid: Device UUID from registration
    ///   - favoriteTeamId: Team ID (e.g., 1530 for Cameroon, 1532 for Algeria)
    ///   - leagueId: League ID (default: 6 for AFCON)
    ///   - season: Season year (default: 2025)
    func updateFavoriteTeam(
        deviceUuid: String,
        favoriteTeamId: Int32,
        leagueId: Int32 = 6,
        season: Int32 = 2025
    ) async throws -> Afcon_UpdateSubscriptionsResponse {
        // Create subscription for favorite team
        var subscription = Afcon_Subscription()
        subscription.leagueID = leagueId
        subscription.season = season
        subscription.teamID = favoriteTeamId

        // Set notification preferences
        var preferences = Afcon_NotificationPreferences()
        preferences.notifyGoals = true
        preferences.notifyMatchStart = true
        preferences.notifyMatchEnd = true
        preferences.notifyRedCards = true
        preferences.notifyLineups = false
        preferences.notifyVar = false
        preferences.matchStartMinutesBefore = 15

        subscription.preferences = preferences

        return try await service.updateSubscriptions(
            deviceUuid: deviceUuid,
            subscriptions: [subscription]
        )
    }

    /// Get current subscriptions for device
    func getSubscriptions(deviceUuid: String) async throws -> Afcon_GetSubscriptionsResponse {
        return try await service.getSubscriptions(deviceUuid: deviceUuid)
    }

    /// Start a Live Activity for a specific match
    func startLiveActivity(
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
    func endLiveActivity(activityUuid: String) async throws -> Afcon_EndLiveActivityResponse {
        return try await service.endLiveActivity(activityUuid: activityUuid)
    }
}

// MARK: - Shared Instance
extension AFCONServiceWrapper {
    static let shared = AFCONServiceWrapper()
}
