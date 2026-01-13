//
//  NotificationService.swift
//  AFCON2025
//
//  Notification service for managing local and push notifications
//

import Combine
import Foundation
import UserNotifications
import SwiftUI

@MainActor
class AppNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        self.notificationCenter.delegate = self
        Task { [weak self] in
            await self?.checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Management

    /// Request notification permissions from the user
    func requestAuthorization() async throws -> Bool {
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
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Register for push notifications
    private func registerForPushNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Local Notifications

    /// Schedule a notification for an upcoming match
    func scheduleMatchReminder(
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
    func notifyScoreUpdate(
        fixtureId: Int,
        homeTeam: String,
        awayTeam: String,
        homeScore: Int,
        awayScore: Int,
        event: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "⚽️ GOAL!"
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
    func notifyMatchResult(
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
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all match reminders for a specific fixture
    func cancelMatchReminders(fixtureId: Int) {
        let identifier = "match_reminder_\(fixtureId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Clear all notifications
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.setBadgeCount(0, withCompletionHandler: nil)
    }

    /// Clear app badge count
    func clearBadge() async {
        notificationCenter.setBadgeCount(0, withCompletionHandler: nil)
        print("🔔 Badge cleared")
    }

    // MARK: - Push Notification Token

    /// Store device token for push notifications
    func setDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        print("📱 Device Token: \(tokenString)")

        // TODO: Send token to your backend server
        // sendTokenToServer(tokenString)
    }

    /// Handle push notification registration failure
    func handleRegistrationError(_ error: Error) {
        print("❌ Push notification registration failed: \(error.localizedDescription)")
    }

    // MARK: - Notification Categories

    /// Setup notification categories and actions
    func setupNotificationCategories() {
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
}

// MARK: - UNUserNotificationCenterDelegate

extension AppNotificationService {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
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
