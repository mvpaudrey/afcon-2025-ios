import Foundation
import ActivityKit
import UIKit

/// Helper to diagnose Live Activity and Dynamic Island issues
struct LiveActivityDiagnostics {

    /// Check if Live Activities are supported on this device
    static var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Check if device has Dynamic Island hardware
    static var hasDynamicIsland: Bool {
        // Dynamic Island is available on iPhone 14 Pro and later
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion

        // Check iOS version (needs iOS 16.1+)
        guard let majorVersion = Double(systemVersion.components(separatedBy: ".").first ?? "0"),
              majorVersion >= 16.1 else {
            return false
        }

        // Dynamic Island is only on iPhone, not iPad
        guard deviceModel.contains("iPhone") else {
            return false
        }

        // Note: This is a heuristic - actual device detection requires
        // checking screen dimensions or using private APIs
        return true
    }

    /// Get diagnostic information as a formatted string
    static func getDiagnosticInfo() -> String {
        var info: [String] = []

        info.append("📱 Device Information")
        info.append("---")
        info.append("Model: \(UIDevice.current.model)")
        info.append("System: iOS \(UIDevice.current.systemVersion)")
        info.append("")

        info.append("🔴 Live Activities")
        info.append("---")
        info.append("Supported: \(isSupported ? "✅ Yes" : "❌ No")")

        let authInfo = ActivityAuthorizationInfo()
        info.append("Enabled: \(authInfo.areActivitiesEnabled ? "✅ Yes" : "❌ No")")
        info.append("Frequent Pushes: \(authInfo.frequentPushesEnabled ? "✅ Yes" : "❌ No")")
        info.append("")

        info.append("🏝️ Dynamic Island")
        info.append("---")
        info.append("Hardware: \(hasDynamicIsland ? "✅ Likely supported" : "⚠️ May not be available")")
        info.append("")

        info.append("📊 Current Activities")
        info.append("---")
        let allActivities = ActivityKit.Activity<LiveScoreActivityAttributes>.activities
        let activeCount = allActivities.count
        info.append("Active: \(activeCount)")
        for activity in allActivities {
            info.append("  • Fixture \(activity.attributes.fixtureID): \(activity.attributes.homeTeam) vs \(activity.attributes.awayTeam)")
        }

        if activeCount == 0 {
            info.append("  No active Live Activities")
        }

        return info.joined(separator: "\n")
    }

    /// Print diagnostic information to console
    static func printDiagnostics() {
        print("\n" + String(repeating: "=", count: 50))
        print("LIVE ACTIVITY DIAGNOSTICS")
        print(String(repeating: "=", count: 50))
        print(getDiagnosticInfo())
        print(String(repeating: "=", count: 50) + "\n")
    }
}

