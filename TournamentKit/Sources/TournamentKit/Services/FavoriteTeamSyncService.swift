import Foundation
import SwiftData
import Observation
import AFCONClient

/// Service that syncs favorite team changes to the server
/// This ensures Live Activities are automatically created for your favorite team's matches
@Observable
public class FavoriteTeamSyncService: @unchecked Sendable {
    private let afconService: TournamentServiceWrapper
    private var deviceUuid: String?

    public init(afconService: TournamentServiceWrapper = .shared) {
        self.afconService = afconService
    }

    /// Store device UUID after registration
    public func setDeviceUuid(_ uuid: String) {
        self.deviceUuid = uuid
        UserDefaults.standard.set(uuid, forKey: "device_uuid")
    }

    /// Get stored device UUID
    public func getDeviceUuid() -> String? {
        if let uuid = deviceUuid {
            return uuid
        }
        let stored = UserDefaults.standard.string(forKey: "device_uuid")
        deviceUuid = stored
        return stored
    }

    /// Call this when user changes their favorite team in your app
    /// - Parameters:
    ///   - teamId: The team ID (e.g., 1530 for Cameroon, 1532 for Algeria)
    ///   - teamName: Team name for logging (optional)
    public func updateFavoriteTeam(teamId: Int, teamName: String? = nil) async throws {
        try await updateFavoriteTeams(teamIds: [teamId], teamNames: teamName.map { [$0] })
    }

    /// Call this when user changes their favorite teams in your app
    public func updateFavoriteTeams(teamIds: [Int], teamNames: [String]? = nil) async throws {
        guard let deviceUuid = getDeviceUuid() else {
            throw FavoriteTeamSyncError.deviceNotRegistered
        }
        guard !teamIds.isEmpty else {
            print("No favorite teams to sync")
            return
        }

        let teamLabels = teamNames?.joined(separator: ", ")
        let label = teamLabels ?? teamIds.map(String.init).joined(separator: ", ")
        print("Syncing favorite teams to server: \(label)")

        let response = try await afconService.updateFavoriteTeams(
            deviceUuid: deviceUuid,
            favoriteTeamIds: teamIds.map(Int32.init)
        )

        if response.success {
            print("Favorite teams synced! \(response.subscriptionsUpdated) subscription(s) updated")
        } else {
            print("Failed to sync favorite teams: \(response.message)")
        }
    }

    /// Register device and get UUID (call once on first launch or when device token changes)
    public func registerDevice(
        userId: String,
        deviceToken: String,
        deviceId: String,
        appVersion: String,
        osVersion: String
    ) async throws -> String {
        print("Registering device...")

        let response = try await afconService.registerDevice(
            userId: userId,
            deviceToken: deviceToken,
            deviceId: deviceId,
            appVersion: appVersion,
            osVersion: osVersion
        )

        if response.success {
            print("Device registered! UUID: \(response.deviceUuid)")
            setDeviceUuid(response.deviceUuid)
            return response.deviceUuid
        } else {
            throw FavoriteTeamSyncError.registrationFailed(response.message)
        }
    }
}

public enum FavoriteTeamSyncError: LocalizedError {
    case deviceNotRegistered
    case registrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .deviceNotRegistered:
            return "Device not registered. Please restart the app."
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        }
    }
}
