//
//  Live Activity widget for live match scores
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveScoreActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveScoreActivityAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenLiveScoreView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        LogoImageView(path: context.state.homeTeamLogoPath, size: CGSize(width: 28, height: 28), useCircle: true)
                        Text(localizedTeamName(context.attributes.homeTeam))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        Text(localizedTeamName(context.attributes.awayTeam))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        LogoImageView(path: context.state.awayTeamLogoPath, size: CGSize(width: 28, height: 28), useCircle: true)
                    }
                    .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.center) {
                    let state = context.state
                    let status = state.status
                    let label = statusLabel(status)
                    let color = statusColor(status)

                    VStack(spacing: 8) {
                        // Score display
                        HStack(spacing: 12) {
                            Text("\(context.state.homeScore)")
                                .font(.system(size: 40, weight: .heavy))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            Text("-")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))

                            Text("\(context.state.awayScore)")
                                .font(.system(size: 40, weight: .heavy))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }

                        // Status and Time
                        HStack {
                            statusIndicator(status: status, color: color)

                            Text(label)
                                .font(.caption)
                                .foregroundColor(color)
                                .fontWeight(.semibold)
                        }

                        matchTimerView(for: state, font: .caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    let state = context.state

                    goalSummaryCompactView(
                        state: state,
                        homeTeam: context.attributes.homeTeam,
                        awayTeam: context.attributes.awayTeam
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            } compactLeading: {
                // Compact leading (left side of Dynamic Island)
                HStack(spacing: 4) {
                    LogoImageView(path: context.state.homeTeamLogoPath, size: CGSize(width: 20, height: 20), useCircle: true)
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island)
                HStack(spacing: 4) {
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    LogoImageView(path: context.state.awayTeamLogoPath, size: CGSize(width: 20, height: 20), useCircle: true)
                }
            } minimal: {
                // Minimal view (when multiple activities are running)
                Image(systemName: "soccerball")
                    .resizable()
                    .font(.system(size: 12))
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveScoreView: View {
    let context: ActivityViewContext<LiveScoreActivityAttributes>

    var body: some View {
        let state = context.state
        let status = state.status
        let label = statusLabel(status)
        let color = statusColor(status)

        VStack(spacing: 12) {
            // Competition header
            HStack {
                Text(context.attributes.competition)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    statusIndicator(status: status, color: color)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                }
            }

            // Score display - redesigned layout
            HStack(alignment: .center, spacing: 6) {
                // Home team: Flag, Name, Score
                HStack(spacing: 6) {
                    LogoImageView(path: context.state.homeTeamLogoPath, size: CGSize(width: 32, height: 32), useCircle: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedTeamName(context.attributes.homeTeam))
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 70, alignment: .leading)
                }

                Spacer()

                // Center: Scores with dash
                HStack(spacing: 8) {
                    Text("\(state.homeScore)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("-")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("\(state.awayScore)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }

                Spacer()

                // Away team: Name, Flag
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(localizedTeamName(context.attributes.awayTeam))
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 70, alignment: .trailing)

                    LogoImageView(path: context.state.awayTeamLogoPath, size: CGSize(width: 32, height: 32), useCircle: true)
                }
            }

            // Timer below scores
            if isFinishedStatus(state.status) {
                Text("FT")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            } else {
                matchTimerView(for: state, font: .caption2)
            }

            goalSummaryExpandedView(
                state: state,
                homeTeam: context.attributes.homeTeam,
                awayTeam: context.attributes.awayTeam
            )
        }
        .padding(16)
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(Color.white)
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: LiveScoreActivityAttributes(
    fixtureID: 12345,
    homeTeam: "Real Madrid",
    awayTeam: "Barcelona",
    competition: "Champions League",
    matchDate: Date()
)) {
    LiveScoreActivityWidget()
} contentStates: {
    LiveScoreActivityAttributes.ContentState(
        homeScore: 2,
        awayScore: 1,
        status: "2H",
        elapsed: 67,
        lastUpdateTime: Date(),
        firstPeriodStart: Date().addingTimeInterval(-67 * 60),
        secondPeriodStart: Date().addingTimeInterval(-(67 - 45) * 60),
        homeTeamLogoPath: nil,
        awayTeamLogoPath: nil,
        homeGoalEvents: ["12' Benzema (Ast. Modric)", "67' Benzema"],
        awayGoalEvents: ["46' Lewandowski"]
    )

    LiveScoreActivityAttributes.ContentState(
        homeScore: 2,
        awayScore: 2,
        status: "FT",
        elapsed: 90,
        lastUpdateTime: Date(),
        firstPeriodStart: Date().addingTimeInterval(-90 * 60),
        secondPeriodStart: Date().addingTimeInterval(-(90 - 45) * 60),
        homeTeamLogoPath: nil,
        awayTeamLogoPath: nil,
        homeGoalEvents: ["12' Benzema (Ast. Modric)", "67' Benzema"],
        awayGoalEvents: ["46' Lewandowski", "83' Ansu Fati (Ast. Pedri)"]
    )
}

// MARK: - Helpers

@ViewBuilder
private func matchTimerView(for state: LiveScoreActivityAttributes.ContentState, font: Font) -> some View {
    TimelineView(.periodic(from: .now, by: 1)) { timeline in
        let displayStatus = state.status.uppercased()

        if isFinishedStatus(displayStatus) {
            Text("Full Time")
                .font(font)
                .fontWeight(.semibold)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if let seconds = elapsedSeconds(for: state, at: timeline.date) {
            Text(formatClock(seconds))
                .font(font)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
        } else if state.elapsed >= 0 {
            Text("\(state.elapsed)'")
                .font(font)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Text("--:--")
                .font(font)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

@ViewBuilder
private func goalSummaryCompactView(
    state: LiveScoreActivityAttributes.ContentState,
    homeTeam: String,
    awayTeam: String
) -> some View {
    let homeLast = state.homeGoalEvents.last.map(sanitizedGoalText)
    let awayLast = state.awayGoalEvents.last.map(sanitizedGoalText)

    if homeLast == nil && awayLast == nil {
        EmptyView()
    } else {
        VStack(spacing: 4) {

            HStack(alignment: .top) {
                if let homeLast {
                    Text(homeLast)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let awayLast {
                    Text(awayLast)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

@ViewBuilder
private func goalSummaryExpandedView(
    state: LiveScoreActivityAttributes.ContentState,
    homeTeam: String,
    awayTeam: String
) -> some View {
    let homeEvents = state.homeGoalEvents.map(sanitizedGoalText)
    let awayEvents = state.awayGoalEvents.map(sanitizedGoalText)
    let maxCount = max(homeEvents.count, awayEvents.count)

    if maxCount == 0 {
        EmptyView()
    } else {
        VStack(alignment: .leading, spacing: 6) {
            /*HStack {
                Text(homeTeam)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(awayTeam)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }*/

            ForEach(0..<maxCount, id: \.self) { index in
                HStack(alignment: .top) {
                    Text(homeEvents.count > index ? homeEvents[index] : "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(awayEvents.count > index ? awayEvents[index] : "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

private func teamAbbreviation(_ name: String) -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "" }

    let parts = trimmed.split(separator: " ")
    if parts.count == 1 {
        return String(parts[0].prefix(3)).uppercased()
    }

    return parts.prefix(2).map { String($0.prefix(1)).uppercased() }.joined()
}

private func sanitizedGoalText(_ text: String) -> String {
    guard let assistRange = text.range(of: "(Ast.") else {
        return text
    }

    var result = text
    var lowerBound = assistRange.lowerBound
    if lowerBound > result.startIndex {
        let before = result.index(before: lowerBound)
        if result[before].isWhitespace {
            lowerBound = before
        }
    }

    if let end = result[assistRange.lowerBound...].firstIndex(of: ")") {
        result.removeSubrange(lowerBound...end)
    } else {
        result.removeSubrange(lowerBound..<result.endIndex)
    }

    while result.contains("  ") {
        result = result.replacingOccurrences(of: "  ", with: " ")
    }

    return result.trimmingCharacters(in: .whitespaces)
}

private func isFinishedStatus(_ status: String) -> Bool {
    let finished: Set<String> = ["FT", "AET", "PEN", "AWD", "WO", "ABD", "CANC", "SUSP"]
    return finished.contains(status.uppercased())
}

private func elapsedSeconds(for state: LiveScoreActivityAttributes.ContentState, at date: Date) -> Int? {
    let status = state.status.uppercased()
    let baseSeconds = max(Int(state.elapsed) * 60, 0)

    if status == "1H", let start = state.firstPeriodStart {
        return max(Int(date.timeIntervalSince(start)), 0)
    }

    if status == "2H" {
        if let second = state.secondPeriodStart {
            return max(Int(date.timeIntervalSince(second)), 0) + 45 * 60
        } else if let first = state.firstPeriodStart {
            return max(Int(date.timeIntervalSince(first)), 0)
        }
    }

    if status == "ET", let second = state.secondPeriodStart {
        return max(Int(date.timeIntervalSince(second)), 0) + 90 * 60
    }

    guard isLiveStatus(status) else {
        return baseSeconds
    }

    let secondsSinceUpdate = max(Int(date.timeIntervalSince(state.lastUpdateTime)), 0)
    return baseSeconds + secondsSinceUpdate
}

private func formatClock(_ seconds: Int) -> String {
    let total = max(seconds, 0)
    let minutes = total / 60
    let remainder = total % 60
    return String(format: "%d:%02d", minutes, remainder)
}

private func statusLabel(_ status: String) -> String {
    switch status.uppercased() {
    case "1H": return "1st Half"
    case "HT": return "Half Time"
    case "2H": return "2nd Half"
    case "ET": return "Extra Time"
    case "BT": return "Break Time"
    case "P": return "Penalty In Progress"
    case "FT": return "Full Time"
    case "AET": return "After Extra Time"
    case "PEN": return "Penalty Shootout"
    case "AWD": return "Awarded"
    case "WO": return "Walkover"
    case "ABD": return "Abandoned"
    case "CANC": return "Cancelled"
    case "SUSP": return "Suspended"
    case "NS": return "Not Started"
    default: return "Live"
    }
}

private func statusColor(_ status: String) -> Color {
    let upper = status.uppercased()
    if isFinishedStatus(status) {
        return .green
    }
    switch upper {
    case "HT", "BT":
        return .orange
    case "NS", "TBD":
        return .secondary
    default:
        return .green
    }
}

private func statusSymbol(_ status: String) -> String? {
    switch status.uppercased() {
    case "HT", "BT":
        return "pause.circle.fill"
    case "FT", "AET", "PEN":
        return "checkmark.circle.fill"
    case "NS", "TBD":
        return "clock.fill"
    default:
        return nil
    }
}

private func isLiveStatus(_ status: String) -> Bool {
    let live: Set<String> = ["1H", "2H", "ET", "BT", "P", "LIVE", "INP", "IN_PLAY", "INPLAY", "IN PROGRESS"]
    return live.contains(status.uppercased())
}

@ViewBuilder
private func statusIndicator(status: String, color: Color) -> some View {
    if let symbol = statusSymbol(status) {
        Image(systemName: symbol)
            .font(.caption)
            .foregroundColor(color)
    } else if isLiveStatus(status) {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }
}
