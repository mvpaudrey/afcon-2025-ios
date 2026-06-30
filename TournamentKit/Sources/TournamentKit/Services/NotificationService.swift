//
//  NotificationService.swift
//  TournamentKit
//
//  Notification service for managing local and push notifications
//

import Combine
import Foundation
import UserNotifications
import SwiftUI

@MainActor
public class AppNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = AppNotificationService()

    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var deviceToken: String?

    private let notificationCenter = UNUserNotificationCenter.current()
    private let syncService = FavoriteTeamSyncService()

    private override init() {
        super.init()
        self.notificationCenter.delegate = self
        Task { [weak self] in
            await self?.checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Management

    /// Request notification permissions from the user
    public func requestAuthorization() async throws -> Bool {
        await checkAuthorizationStatus()
        guard authorizationStatus == .notDetermined else {
            return authorizationStatus == .authorized
        }
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await notificationCenter.requestAuthorization(options: options)

        await checkAuthorizationStatus()

        if granted {
            await registerForPushNotifications()
        }

        return granted
    }

    /// Check current authorization status
    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Register for push notifications
    private func registerForPushNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Local Notifications

    /// Schedule a notification for an upcoming match
    public func scheduleMatchReminder(
        fixtureId: Int,
        homeTeam: String,
        awayTeam: String,
        matchDate: Date,
        minutesBefore: Int = 30
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Match Starting Soon"
        content.body = "\(homeTeam) vs \(awayTeam) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MATCH_REMINDER"
        content.userInfo = [
            "fixtureId": fixtureId,
            "type": "match_reminder"
        ]

        let triggerDate = matchDate.addingTimeInterval(-Double(minutesBefore * 60))
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = "match_reminder_\(fixtureId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    /// Schedule notification for a goal or score update
    public func notifyScoreUpdate(
        fixtureId: Int,
        homeTeam: String,
        awayTeam: String,
        homeScore: Int,
        awayScore: Int,
        event: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "GOAL!"
        content.body = "\(event)\n\(homeTeam) \(homeScore) - \(awayScore) \(awayTeam)"
        content.sound = .default
        content.categoryIdentifier = "SCORE_UPDATE"
        content.userInfo = [
            "fixtureId": fixtureId,
            "type": "score_update"
        ]

        let identifier = "score_update_\(fixtureId)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)
    }

    /// Schedule notification for match result
    public func notifyMatchResult(
        fixtureId: Int,
        homeTeam: String,
        awayTeam: String,
        homeScore: Int,
        awayScore: Int
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Match Finished"
        content.body = "\(homeTeam) \(homeScore) - \(awayScore) \(awayTeam)"
        content.sound = .default
        content.categoryIdentifier = "MATCH_RESULT"
        content.userInfo = [
            "fixtureId": fixtureId,
            "type": "match_result"
        ]

        let identifier = "match_result_\(fixtureId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await notificationCenter.add(request)
    }

    /// Cancel a specific notification
    public func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all match reminders for a specific fixture
    public func cancelMatchReminders(fixtureId: Int) {
        let identifier = "match_reminder_\(fixtureId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get all pending notifications
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Clear all notifications
    public func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.setBadgeCount(0, withCompletionHandler: nil)
    }

    /// Clear app badge count
    public func clearBadge() async {
        notificationCenter.setBadgeCount(0, withCompletionHandler: nil)
        print("Badge cleared")
    }

    // MARK: - Push Notification Token

    /// Store device token for push notifications
    public func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        print("Device Token: \(tokenString)")

        let previousToken = AppSettings.shared.lastDeviceToken
        AppSettings.shared.lastDeviceToken = tokenString

        Task { [weak self] in
            await self?.registerDeviceAndSyncFavorites(
                deviceToken: tokenString,
                previousToken: previousToken
            )
        }
    }

    /// Handle push notification registration failure
    public func handleRegistrationError(_ error: Error) {
        print("Push notification registration failed: \(error.localizedDescription)")
    }

    // MARK: - Notification Categories

    /// Setup notification categories and actions
    public func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_MATCH",
            title: "View Match",
            options: .foreground
        )

        let muteAction = UNNotificationAction(
            identifier: "MUTE_MATCH",
            title: "Mute Updates",
            options: []
        )

        let matchReminderCategory = UNNotificationCategory(
            identifier: "MATCH_REMINDER",
            actions: [viewAction, muteAction],
            intentIdentifiers: [],
            options: []
        )

        let scoreUpdateCategory = UNNotificationCategory(
            identifier: "SCORE_UPDATE",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        let matchResultCategory = UNNotificationCategory(
            identifier: "MATCH_RESULT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            matchReminderCategory,
            scoreUpdateCategory,
            matchResultCategory
        ])
    }

    public func syncIfPossibleOnLaunch() async {
        await checkAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
        guard !AppSettings.shared.selectedFavoriteTeamIds.isEmpty else { return }
        guard let token = deviceToken ?? AppSettings.shared.lastDeviceToken else {
            await registerForPushNotifications()
            return
        }

        deviceToken = token
        await registerDeviceAndSyncFavorites(
            deviceToken: token,
            previousToken: AppSettings.shared.lastDeviceToken
        )
    }

    private func registerDeviceAndSyncFavorites(
        deviceToken: String,
        previousToken: String?
    ) async {
        let needsRegistration = previousToken != deviceToken || syncService.getDeviceUuid() == nil
        if needsRegistration {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let appVersion = AppSettings.shared.currentAppVersion
            let osVersion = UIDevice.current.systemVersion

            do {
                _ = try await syncService.registerDevice(
                    userId: "user-\(deviceId)",
                    deviceToken: deviceToken,
                    deviceId: deviceId,
                    appVersion: appVersion,
                    osVersion: osVersion
                )
            } catch {
                print("Failed to register device: \(error)")
                return
            }
        }

        await syncStoredFavoriteTeams()
    }

    private func syncStoredFavoriteTeams() async {
        let teamIds = AppSettings.shared.selectedFavoriteTeamIds
        guard !teamIds.isEmpty else { return }

        do {
            try await syncService.updateFavoriteTeams(teamIds: teamIds)
        } catch {
            print("Failed to sync favorite teams: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppNotificationService {
    /// Handle notification when app is in foreground
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Clear badge when notification is tapped
        Task { @MainActor in
            await self.clearBadge()
        }

        switch response.actionIdentifier {
        case "VIEW_MATCH":
            if let fixtureId = userInfo["fixtureId"] as? Int {
                Task { @MainActor in
                    self.handleViewMatch(fixtureId: fixtureId)
                }
            }
        case "MUTE_MATCH":
            if let fixtureId = userInfo["fixtureId"] as? Int {
                Task {
                    await AppNotificationService.shared.cancelMatchReminders(fixtureId: fixtureId)
                }
            }
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            if let fixtureId = userInfo["fixtureId"] as? Int {
                Task { @MainActor in
                    self.handleViewMatch(fixtureId: fixtureId)
                }
            }
        default:
            break
        }

        completionHandler()
    }

    /// Navigate to match detail screen
    private func handleViewMatch(fixtureId: Int) {
        // TODO: Navigate to match detail view
        // Post notification to open specific match
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenMatchDetail"),
            object: nil,
            userInfo: ["fixtureId": fixtureId]
        )
    }
}
