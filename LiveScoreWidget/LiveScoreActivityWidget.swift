//
//  Live Activity widget for live match scores
//

import ActivityKit
import WidgetKit
import SwiftUI
import TournamentKit

struct LiveScoreActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveScoreActivityAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenLiveScoreView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    LogoImageView(path: context.state.homeTeamLogoPath, size: CGSize(width: 32, height: 32), useCircle: true)
                        .padding(.leading, 8)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    LogoImageView(path: context.state.awayTeamLogoPath, size: CGSize(width: 32, height: 32), useCircle: true)
                        .padding(.trailing, 8)
                }

                DynamicIslandExpandedRegion(.center) {
                    let state = context.state
                    let status = state.status
                    let label = statusLabel(status)
                    let color = statusColor(status)

                    VStack(spacing: 6) {
                        // Team names with scores - horizontally aligned
                        HStack(spacing: 8) {
                            // Home team name
                            Text(displayTeamName(context.attributes.homeTeam))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: 65, alignment: .trailing)

                            // Home score
                            Text("\(context.state.homeScore)")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            // Dash separator
                            Text("-")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))

                            // Away score
                            Text("\(context.state.awayScore)")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            // Away team name
                            Text(displayTeamName(context.attributes.awayTeam))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: 65, alignment: .leading)
                        }

                        // Status and Time
                        HStack(spacing: 6) {
                            statusIndicator(status: status, color: color)

                            Text(label)
                                .font(.caption2)
                                .foregroundColor(color)
                                .fontWeight(.semibold)

                            matchTimerView(for: state, font: .caption2, fullWidth: false)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 8)
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
        let teamNameWidth: CGFloat = 80

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
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: teamNameWidth, alignment: .leading)
                }

                Spacer()

                // Center: Scores with dash
                HStack(spacing: 6) {
                    Text("\(state.homeScore)")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: Color.black.opacity(0.6), radius: 2, x: 0, y: 1)

                    Text("-")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white.opacity(0.65))

                    Text("\(state.awayScore)")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: Color.black.opacity(0.6), radius: 2, x: 0, y: 1)
                }

                Spacer()

                // Away team: Name, Flag
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(localizedTeamName(context.attributes.awayTeam))
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: teamNameWidth, alignment: .trailing)

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
private func matchTimerView(
    for state: LiveScoreActivityAttributes.ContentState,
    font: Font,
    fullWidth: Bool = true
) -> some View {
    let displayStatus = state.status.uppercased()

    if isFinishedStatus(displayStatus) {
        Text("Full Time")
            .font(font)
            .fontWeight(.semibold)
            .foregroundColor(.green)
            .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .center)
    } else if displayStatus == "HT" || displayStatus == "BT" {
        Text(displayStatus == "HT" ? "45'" : "90'")
            .font(font)
            .monospacedDigit()
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .center)
    } else if displayStatus == "P" || displayStatus == "PEN" {
        EmptyView()
    } else if isLiveStatus(displayStatus) {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let total = max(Int(state.elapsed) * 60 + Int(ctx.date.timeIntervalSince(state.lastUpdateTime)), 0)
            let mins = total / 60
            let secs = total % 60
            Text(String(format: "%d:%02d", mins, secs))
                .font(font)
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .center)
        }
    } else {
        Text("\(state.elapsed)'")
            .font(font)
            .monospacedDigit()
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: fullWidth ? .infinity : nil, alignment: .center)
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

private func displayTeamName(_ name: String) -> String {
    let localized = localizedTeamName(name)
    return localized.count > 10 ? teamAbbreviation(localized) : localized
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
