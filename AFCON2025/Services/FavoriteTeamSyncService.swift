import Foundation
import SwiftData
import Observation
import AFCONClient

/// Service that syncs favorite team changes to the server
/// This ensures Live Activities are automatically created for your favorite team's matches
@Observable
class FavoriteTeamSyncService {
    private let afconService: AFCONServiceWrapper
    private var deviceUuid: String?

    init(afconService: AFCONServiceWrapper = .shared) {
        self.afconService = afconService
    }

    /// Store device UUID after registration
    func setDeviceUuid(_ uuid: String) {
        self.deviceUuid = uuid
        UserDefaults.standard.set(uuid, forKey: "device_uuid")
    }

    /// Get stored device UUID
    func getDeviceUuid() -> String? {
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
    func updateFavoriteTeam(teamId: Int, teamName: String? = nil) async throws {
        guard let deviceUuid = getDeviceUuid() else {
            throw FavoriteTeamSyncError.deviceNotRegistered
        }

        print("📱 Syncing favorite team to server: \(teamName ?? "Team \(teamId)")")

        let response = try await afconService.updateFavoriteTeam(
            deviceUuid: deviceUuid,
            favoriteTeamId: Int32(teamId)
        )

        if response.success {
            print("✅ Favorite team synced! \(response.subscriptionsUpdated) subscription(s) updated")
            print("   You'll now receive Live Activities for all \(teamName ?? "your team")'s matches")
        } else {
            print("❌ Failed to sync favorite team: \(response.message)")
        }
    }

    /// Register device and get UUID (call once on first launch or when device token changes)
    func registerDevice(
        userId: String,
        deviceToken: String,
        deviceId: String,
        appVersion: String,
        osVersion: String
    ) async throws -> String {
        print("📱 Registering device...")

        let response = try await afconService.registerDevice(
            userId: userId,
            deviceToken: deviceToken,
            deviceId: deviceId,
            appVersion: appVersion,
            osVersion: osVersion
        )

        if response.success {
            print("✅ Device registered! UUID: \(response.deviceUuid)")
            setDeviceUuid(response.deviceUuid)
            return response.deviceUuid
        } else {
            throw FavoriteTeamSyncError.registrationFailed(response.message)
        }
    }
}

enum FavoriteTeamSyncError: LocalizedError {
    case deviceNotRegistered
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .deviceNotRegistered:
            return "Device not registered. Please restart the app."
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        }
    }
}
