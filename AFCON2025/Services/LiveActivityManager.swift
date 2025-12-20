import Foundation
import ActivityKit
import Observation

/// Manager for creating and updating Live Activities for match scores
@Observable
class LiveActivityManager {
    // MARK: - Properties

    /// Currently active Live Activities (keyed by fixture ID)
    private(set) var activeActivities: [Int32: ActivityKit.Activity<LiveScoreActivityAttributes>] = [:]

    /// Whether Live Activities are supported on this device
    var isSupported: Bool {
        ActivityKit.ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Singleton

    static let shared = LiveActivityManager()

    private init() {}

    // MARK: - Public Methods

    /// Start a Live Activity for a match
    /// - Parameters:
    ///   - fixtureID: The fixture ID
    ///   - homeTeam: Home team name
    ///   - awayTeam: Away team name
    ///   - competition: Competition name
    ///   - initialState: Initial match state
    /// - Returns: True if activity was started successfully
    @discardableResult
    func startActivity(
        fixtureID: Int32,
        homeTeam: String,
        awayTeam: String,
        competition: String,
        initialState: LiveScoreActivityAttributes.ContentState
    ) -> Bool {
        // Check if activity already exists
        if activeActivities[fixtureID] != nil {
            print("⚠️ Live Activity already exists for fixture \(fixtureID)")
            return false
        }

        // Check if supported
        guard isSupported else {
            print("❌ Live Activities not supported on this device")
            return false
        }

        do {
            let attributes = LiveScoreActivityAttributes(
                fixtureID: fixtureID,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                competition: competition,
                matchDate: Date()
            )

            let activity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            activeActivities[fixtureID] = activity

            print("✅ Started Live Activity for \(homeTeam) vs \(awayTeam)")
            print("   Activity ID: \(activity.id)")

            return true
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
            return false
        }
    }

    /// Update an existing Live Activity
    /// - Parameters:
    ///   - fixtureID: The fixture ID
    ///   - newState: New match state
    func updateActivity(fixtureID: Int32, newState: LiveScoreActivityAttributes.ContentState) async {
        guard let activity = activeActivities[fixtureID] else {
            print("⚠️ No active Live Activity found for fixture \(fixtureID)")
            return
        }

        await activity.update(.init(state: newState, staleDate: nil))
        print("✅ Updated Live Activity for fixture \(fixtureID)")
        print("   Score: \(newState.homeScore) - \(newState.awayScore)")
        print("   Status: \(newState.status), Elapsed: \(newState.elapsed)'")
        if let homeLast = newState.homeGoalEvents.last {
            print("   Home goal: \(homeLast)")
        }
        if let awayLast = newState.awayGoalEvents.last {
            print("   Away goal: \(awayLast)")
        }
    }

    /// End a Live Activity
    /// - Parameters:
    ///   - fixtureID: The fixture ID
    ///   - finalState: Final match state (optional, uses current if nil)
    ///   - dismissalPolicy: When to dismiss the activity
    func endActivity(
        fixtureID: Int32,
        finalState: LiveScoreActivityAttributes.ContentState? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .default
    ) async {
        guard let activity = activeActivities[fixtureID] else {
            print("⚠️ No active Live Activity found for fixture \(fixtureID)")
            return
        }

        if let finalState {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: dismissalPolicy)
        } else {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
        }

        activeActivities.removeValue(forKey: fixtureID)

        print("✅ Ended Live Activity for fixture \(fixtureID)")
    }

    /// End all active Live Activities
    func endAllActivities() async {
        let fixtureIDs = Array(activeActivities.keys)

        for fixtureID in fixtureIDs {
            await endActivity(fixtureID: fixtureID)
        }

        print("✅ Ended all Live Activities (\(fixtureIDs.count) total)")
    }

    /// Check if a Live Activity is active for a fixture
    /// - Parameter fixtureID: The fixture ID
    /// - Returns: True if activity is active
    func isActivityActive(for fixtureID: Int32) -> Bool {
        return activeActivities[fixtureID] != nil
    }

    /// Get the current activity state for a fixture
    /// - Parameter fixtureID: The fixture ID
    /// - Returns: The current activity state, or nil if not active
    func getCurrentState(for fixtureID: Int32) -> LiveScoreActivityAttributes.ContentState? {
        guard let activity = activeActivities[fixtureID] else {
            return nil
        }
        return activity.content.state
    }
}

// MARK: - Helper Extensions

extension LiveActivityManager {
    /// Create event description from match event
    func eventDescription(from event: String, player: String, team: String) -> String {
        switch event.lowercased() {
        case "goal":
            return "⚽ Goal by \(player)"
        case "card", "yellow card":
            return "🟨 Yellow card - \(player)"
        case "red card":
            return "🟥 Red card - \(player)"
        case "substitution":
            return "🔄 Substitution - \(team)"
        case "var":
            return "📹 VAR Review"
        case "missed penalty", "penalty":
            return "❌ Penalty missed by \(player)"
        default:
            return "\(event) - \(player)"
        }
    }
}

