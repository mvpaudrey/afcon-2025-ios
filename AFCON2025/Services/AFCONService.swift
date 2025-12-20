 import Foundation
import Observation
import AFCONClient

/// Wrapper around AFCONClient for SwiftUI @Observable support
@Observable
class AFCONServiceWrapper {
    private static let defaultHost = ProcessInfo.processInfo.environment["AFCON_API_HOST"] ?? "localhost"
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
        onUpdate: @escaping @Sendable (Afcon_LiveMatchUpdate) -> Void
    ) async throws {
        try await service.streamLiveMatches(leagueId: leagueId, onUpdate: onUpdate)
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
}

// MARK: - Shared Instance
extension AFCONServiceWrapper {
    static let shared = AFCONServiceWrapper()
}
