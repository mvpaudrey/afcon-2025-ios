import SwiftUI
import AFCONClient
import SwiftData

struct QuickStatsBarLive: View {
    let liveScoresViewModel: LiveScoresViewModel

    @Environment(\.tabBarMinimized) private var _isMinimized: Bool

    private var isMinimized: Bool { _isMinimized }

    // Computed properties from LiveScoresViewModel
    private var liveMatch: Game? {
        liveScoresViewModel.liveMatches.first
    }

    private var nextMatch: Game? {
        liveScoresViewModel.upcomingTodayMatches.first
    }

    private var isLoading: Bool {
        liveScoresViewModel.isLoading
    }

    var body: some View {
        ZStack {
            // Background gradient that extends edge-to-edge
            LinearGradient(
                gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoGreen")]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea(edges: .horizontal)

            // Content
            HStack(spacing: isMinimized ? 8 : 12) {
                // Current live match or latest result
                if let liveMatch = liveMatch {
                    liveMatchView(liveMatch, isMinimized: isMinimized)
                } else if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        if !isMinimized {
                            Text(LocalizedStringKey("Loading..."))
                                .font(.caption)
                                .opacity(0.7)
                        }
                    }
                } else {
                    // Show next match if no live match
                    if let nextMatch = nextMatch {
                        upcomingMatchView(nextMatch, isMinimized: isMinimized)
                    } else {
                        if !isMinimized {
                            HStack(spacing: 4) {
                                Text(LocalizedStringKey("No matches scheduled"))
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                        }
                    }
                }

                Spacer()

                if !isMinimized {
                    let statusText = liveMatch != nil ?
                        (liveMatch?.statusShort.uppercased() == "HT" ? "match.status.halftime" : "quickstats.live") :
                        nil
                    if let statusText = statusText {
                        Text(LocalizedStringKey(statusText))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .opacity(0.8)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, isMinimized ? 8 : 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func liveMatchView(_ liveMatch: Game, isMinimized: Bool) -> some View {
        let isHalftime = liveMatch.statusShort.uppercased() == "HT"

        HStack(spacing: 6) {
            // Halftime icon
            if isHalftime {
                Image(systemName: "pause.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            // Home team
            if let homeFlag = TeamFlagMapper.flagAssetName(for: liveMatch.homeTeamId) {
                Image(homeFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            Text("\(liveMatch.homeScore)-\(liveMatch.awayScore)")
                .fontWeight(.bold)

            // Away team
            if let awayFlag = TeamFlagMapper.flagAssetName(for: liveMatch.awayTeamId) {
                Image(awayFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            Text(isHalftime ? "" : stripExtraTime(liveMatch.minute))
                .fontWeight(isHalftime ? .semibold : .medium)
                .foregroundColor(isHalftime ? .orange : .white)
                .opacity(isHalftime ? 1.0 : 0.9)
        }
        .font(.subheadline)
    }

    @ViewBuilder
    private func upcomingMatchView(_ nextMatch: Game, isMinimized: Bool) -> some View {
        let timeUntilMatch = nextMatch.date.timeIntervalSince(Date())
        let showCountdown = timeUntilMatch > 0 && timeUntilMatch < 3600 && Calendar.current.isDateInToday(nextMatch.date)

        HStack(spacing: 6) {
            // Home team
            if let homeFlag = TeamFlagMapper.flagAssetName(for: nextMatch.homeTeamId) {
                Image(homeFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            Text(LocalizedStringKey("vs"))
                .fontWeight(.medium)
                .opacity(0.8)

            // Away team
            if let awayFlag = TeamFlagMapper.flagAssetName(for: nextMatch.awayTeamId) {
                Image(awayFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }

            if !isMinimized {
                Text("•")
                    .opacity(0.5)

                // Use SwiftUI countdown timer for matches less than 1 hour away
                if showCountdown {
                    Text(nextMatch.date, style: .timer)
                        .fontWeight(.medium)
                        .opacity(0.9)
                        .monospacedDigit()
                } else {
                    Text(formatMatchDate(nextMatch.date))
                        .fontWeight(.medium)
                        .opacity(0.9)
                }
            }
        }
        .font(.subheadline)
    }

    private func formatMatchDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        // Check if today - just show time (SwiftUI timer handles countdown)
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        // Check if tomorrow
        if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm"
            let tomorrow = NSLocalizedString("Tomorrow", comment: "")
            return "\(tomorrow), \(formatter.string(from: date))"
        }

        // Otherwise, show full date
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    private func stripExtraTime(_ minute: String) -> String {
        // Remove extra time (e.g., "45'+3" -> "45'", "90'+2" -> "90'")
        if let plusIndex = minute.firstIndex(of: "+") {
            return String(minute[..<plusIndex]) + "'"
        }
        return minute
    }
}
