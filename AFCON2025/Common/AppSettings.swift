//
//  AppSettings.swift
//  AFCON2025
//
//  App-wide settings and user preferences manager
//

import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private let userDefaults = UserDefaults.standard

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedFavoriteTeams = "selectedFavoriteTeams"
        static let lastLaunchVersion = "lastLaunchVersion"
    }

    // MARK: - Onboarding

    /// Check if user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }

    /// Mark onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    /// Reset onboarding (for testing purposes)
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    // MARK: - App Version

    /// Get the current app version
    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Get the last launch version
    var lastLaunchVersion: String? {
        get {
            userDefaults.string(forKey: Keys.lastLaunchVersion)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.lastLaunchVersion)
        }
    }

    /// Check if this is the first launch ever
    var isFirstLaunchEver: Bool {
        lastLaunchVersion == nil
    }

    /// Update last launch version to current version
    func updateLastLaunchVersion() {
        lastLaunchVersion = currentAppVersion
    }

    /// Check if app was updated since last launch
    var wasAppUpdated: Bool {
        guard let lastVersion = lastLaunchVersion else { return false }
        return lastVersion != currentAppVersion
    }
}
