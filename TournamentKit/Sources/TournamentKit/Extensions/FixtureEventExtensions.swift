import Foundation
import AFCONClient

// MARK: - Fixture Event Display Extensions
public extension Afcon_FixtureEvent {
    /// Stable identifier for UI collections
    var eventKey: String {
        let elapsed = time.elapsed
        let extra = time.extra
        let teamId = team.id
        let playerId = player.id
        let assistId = assist.id
        return "\(type)|\(detail)|\(elapsed)|\(extra)|\(teamId)|\(playerId)|\(assistId)"
    }

    /// Get a human-readable description of the event
    var displayDescription: String {
        let eventType = self.type.lowercased()
        let elapsed = self.time.elapsed
        let extra = self.time.extra
        let minute = elapsed > 0 ? (extra > 0 ? "\(elapsed)'+\(extra)" : "\(elapsed)'") : ""

        switch eventType {
        case "goal":
            let scorer = self.player.name
            let detail = self.detail.lowercased()
            let isPenalty = detail.contains("penalty")
            let isOwnGoal = detail.contains("own")

            if self.hasAssist && !self.assist.name.isEmpty && !isPenalty && !isOwnGoal {
                return "\(minute) ⚽️ Goal by \(scorer) (Assist: \(self.assist.name))"
            } else {
                return "\(minute) ⚽️ Goal by \(scorer)"
            }

        case "card":
            let player = self.player.name
            let cardType = self.detail.lowercased()
            if cardType.contains("yellow") {
                return "\(minute) 🟨 Yellow card - \(player)"
            } else if cardType.contains("red") {
                return "\(minute) 🟥 Red card - \(player)"
            } else {
                return "\(minute) Card - \(player)"
            }

        case "subst":
            // For substitutions:
            // - player = person LEAVING the field (substituted out)
            // - assist = person ENTERING the field (substituted in)
            let playerOut = self.player.name
            let playerIn = self.assist.name
            return "\(minute) 🔄 Substitution: \(playerIn) in for \(playerOut)"

        case "var":
            return "\(minute) 📹 VAR: \(self.detail)"

        default:
            return "\(minute) \(self.type): \(self.player.name)"
        }
    }

    /// Get emoji icon for the event type
    var eventIcon: String {
        let eventType = self.type.lowercased()
        let detail = self.detail.lowercased()

        switch eventType {
        case "goal":
            if detail.contains("penalty") {
                return "⚽️🥅" // Penalty goal
            } else if detail.contains("own") {
                return "⚽️❌" // Own goal
            } else {
                return "⚽️"
            }

        case "card":
            if detail.contains("yellow") {
                return "🟨"
            } else if detail.contains("red") || detail.contains("second yellow") {
                return "🟥"
            } else {
                return "📄"
            }

        case "subst":
            return "🔄"

        case "var":
            return "📹"

        default:
            return "ℹ️"
        }
    }

    /// Get the main player involved (for most events, this is the player field)
    var mainPlayer: String {
        return self.player.name
    }

    /// Get the secondary player (for goals with assists, or substitution ins)
    var secondaryPlayer: String? {
        let eventType = self.type.lowercased()

        if eventType == "subst" {
            // For substitutions, the "assist" is actually the player coming in
            return self.hasAssist && !self.assist.name.isEmpty ? self.assist.name : nil
        } else if eventType == "goal" {
            // For goals, the assist is the actual assist
            return self.hasAssist && !self.assist.name.isEmpty ? self.assist.name : nil
        }

        return nil
    }

    /// Format the event for a compact display (e.g., in a list)
    var compactDisplay: String {
        let minute = time.extra > 0 ? "\(time.elapsed)'+\(time.extra)" : "\(time.elapsed)'"
        return "\(eventIcon) \(minute) - \(mainPlayer)"
    }

    /// Format the event for a detailed display
    var detailedDisplay: String {
        displayDescription
    }

    /// Check if this is a substitution event
    var isSubstitution: Bool {
        self.type.lowercased() == "subst"
    }

    /// Check if this is a goal event
    var isGoal: Bool {
        self.type.lowercased() == "goal"
    }

    /// Check if this is a card event
    var isCard: Bool {
        self.type.lowercased() == "card"
    }

    /// Check if this is a VAR event
    var isVAR: Bool {
        self.type.lowercased() == "var"
    }
}

// MARK: - Substitution Helper
public struct SubstitutionInfo {
    public let playerOut: String  // Player leaving the field
    public let playerIn: String   // Player entering the field
    public let minute: Int
    public let extra: Int
    public let team: String

    public var display: String {
        let timeStr = extra > 0 ? "\(minute)'+\(extra)" : "\(minute)'"
        return "\(timeStr) 🔄 \(playerIn) ▶️ \(playerOut)"
    }
}

public extension Afcon_FixtureEvent {
    /// Get substitution details if this is a substitution event
    var substitutionInfo: SubstitutionInfo? {
        guard isSubstitution else { return nil }

        return SubstitutionInfo(
            playerOut: self.player.name,
            playerIn: self.assist.name,
            minute: Int(self.time.elapsed),
            extra: Int(self.time.extra),
            team: self.team.name
        )
    }
}

// MARK: - Goal Helper
public struct GoalInfo {
    public let scorer: String
    public let assist: String?
    public let minute: Int
    public let extra: Int
    public let team: String
    public let detail: String  // "Normal Goal", "Penalty", "Own Goal", etc.

    public var display: String {
        let timeStr = extra > 0 ? "\(minute)'+\(extra)" : "\(minute)'"
        var text = "\(timeStr) ⚽️ \(scorer)"
        if let assist = assist,
           !detail.lowercased().contains("penalty"),
           !detail.lowercased().contains("own") {
            text += " (Assist: \(assist))"
        }
        if detail.lowercased().contains("penalty") {
            text += " [Penalty]"
        } else if detail.lowercased().contains("own") {
            text += " [Own Goal]"
        }
        return text
    }
}

public extension Afcon_FixtureEvent {
    /// Get goal details if this is a goal event
    var goalInfo: GoalInfo? {
        guard isGoal else { return nil }

        return GoalInfo(
            scorer: self.player.name,
            assist: self.hasAssist && !self.assist.name.isEmpty ? self.assist.name : nil,
            minute: Int(self.time.elapsed),
            extra: Int(self.time.extra),
            team: self.team.name,
            detail: self.detail
        )
    }
}
