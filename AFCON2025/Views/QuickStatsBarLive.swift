import SwiftUI
import AFCONClient
import SwiftData

struct QuickStatsBarLive: View {
    let liveScoresViewModel: LiveScoresViewModel

    @Environment(\.tabBarMinimized) private var _isMinimized: Bool

    private var isMinimized: Bool { _isMinimized }

    // Computed properties from LiveScoresViewModel
    private var liveMatches: [Game] {
        let allLive = liveScoresViewModel.liveMatches
        guard !allLive.isEmpty else { return [] }

        // Find the earliest kickoff time among live matches
        let earliestKickoff = allLive.map { $0.date }.min() ?? Date()

        // Get all matches that started at the same time (within 5 minutes)
        let simultaneousMatches = allLive.filter { match in
            abs(match.date.timeIntervalSince(earliestKickoff)) <= 300 // 5 minutes
        }

        return sortMatchesByPriority(simultaneousMatches)
    }

    private var liveMatch: Game? {
        liveMatches.first
    }

    private var secondLiveMatch: Game? {
        liveMatches.count > 1 ? liveMatches[1] : nil
    }

    private var upcomingMatches: [Game] {
        let allUpcoming = liveScoresViewModel.upcomingTodayMatches
        guard !allUpcoming.isEmpty else { return [] }

        // Find the earliest kickoff time
        let earliestKickoff = allUpcoming.map { $0.date }.min() ?? Date()

        // Get all matches that kick off at the same time (within 5 minutes)
        let simultaneousMatches = allUpcoming.filter { match in
            abs(match.date.timeIntervalSince(earliestKickoff)) <= 300 // 5 minutes
        }

        return sortMatchesByPriority(simultaneousMatches)
    }

    private var nextMatch: Game? {
        upcomingMatches.first
    }

    private var secondUpcomingMatch: Game? {
        upcomingMatches.count > 1 ? upcomingMatches[1] : nil
    }

    private func sortMatchesByPriority(_ matches: [Game]) -> [Game] {
        let favorites = matches.filter { liveScoresViewModel.isFavoriteTeamMatch($0) }
        let nonFavorites = matches.filter { !liveScoresViewModel.isFavoriteTeamMatch($0) }

        // Sort favorites alphabetically by home team name
        let sortedFavorites = favorites.sorted { match1, match2 in
            localizedTeamName(match1.homeTeam).localizedStandardCompare(localizedTeamName(match2.homeTeam)) == .orderedAscending
        }

        // Sort non-favorites alphabetically by home team name
        let sortedNonFavorites = nonFavorites.sorted { match1, match2 in
            localizedTeamName(match1.homeTeam).localizedStandardCompare(localizedTeamName(match2.homeTeam)) == .orderedAscending
        }

        // Combine: favorites first, then non-favorites, take first 2
        return Array((sortedFavorites + sortedNonFavorites).prefix(2))
    }

    private var isLoading: Bool {
        liveScoresViewModel.isLoading
    }

    private var showTwoLiveMatches: Bool {
        liveMatches.count >= 2
    }

    private var showTwoUpcomingMatches: Bool {
        liveMatches.isEmpty && upcomingMatches.count >= 2
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
                // Show two live matches side by side when available
                if showTwoLiveMatches {
                    if let match1 = liveMatch {
                        liveMatchView(match1, isMinimized: isMinimized, compact: true)
                    }

                    if let match2 = secondLiveMatch {
                        Text("•")
                            .font(.caption)
                            .opacity(0.5)

                        liveMatchView(match2, isMinimized: isMinimized, compact: true)
                    }
                } else if showTwoUpcomingMatches {
                    // Show two upcoming matches side by side when no live matches
                    if let match1 = nextMatch, let match2 = secondUpcomingMatch {
                        // Home team 1
                        if let homeFlag1 = TeamFlagMapper.flagAssetName(for: match1.homeTeamId) {
                            Image(homeFlag1)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }

                        Text(LocalizedStringKey("vs"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .opacity(0.8)

                        // Away team 1
                        if let awayFlag1 = TeamFlagMapper.flagAssetName(for: match1.awayTeamId) {
                            Image(awayFlag1)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }

                        Text("•")
                            .font(.subheadline)
                            .opacity(0.5)
                            .padding(.horizontal, 4)

                        // Home team 2
                        if let homeFlag2 = TeamFlagMapper.flagAssetName(for: match2.homeTeamId) {
                            Image(homeFlag2)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }

                        Text(LocalizedStringKey("vs"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .opacity(0.8)

                        // Away team 2
                        if let awayFlag2 = TeamFlagMapper.flagAssetName(for: match2.awayTeamId) {
                            Image(awayFlag2)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    // Show kickoff time on the right
                    if !isMinimized, let kickoffTime = nextMatch?.date {
                        let timeUntilMatch = kickoffTime.timeIntervalSince(Date())
                        let showCountdown = timeUntilMatch > 0 && timeUntilMatch < 3600 && Calendar.current.isDateInToday(kickoffTime)

                        if showCountdown {
                            Text(kickoffTime, style: .timer)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .opacity(0.9)
                                .monospacedDigit()
                        } else {
                            Text(formatMatchDate(kickoffTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .opacity(0.9)
                        }
                    }
                } else {
                    // Single match or no matches
                    if let liveMatch = liveMatch {
                        liveMatchView(liveMatch, isMinimized: isMinimized, compact: false)
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
                        // Show single next match if no live match
                        if let nextMatch = nextMatch {
                            upcomingMatchView(nextMatch, isMinimized: isMinimized, compact: false)
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

                    // Only show status text when showing single match
                    if !isMinimized && !showTwoLiveMatches && !showTwoUpcomingMatches {
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
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, isMinimized ? 8 : 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func liveMatchView(_ liveMatch: Game, isMinimized: Bool, compact: Bool) -> some View {
        let isHalftime = liveMatch.statusShort.uppercased() == "HT"
        let flagSize: CGFloat = compact ? 16 : 20
        let fontSize: Font = compact ? .caption : .subheadline

        HStack(spacing: compact ? 4 : 6) {
            // Halftime icon
            if isHalftime && !compact {
                Image(systemName: "pause.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            // Home team
            if let homeFlag = TeamFlagMapper.flagAssetName(for: liveMatch.homeTeamId) {
                Image(homeFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: flagSize, height: flagSize)
                    .clipShape(Circle())
            }

            Text("\(liveMatch.homeScore)-\(liveMatch.awayScore)")
                .fontWeight(.bold)

            // Away team
            if let awayFlag = TeamFlagMapper.flagAssetName(for: liveMatch.awayTeamId) {
                Image(awayFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: flagSize, height: flagSize)
                    .clipShape(Circle())
            }

            if !compact {
                Text(isHalftime ? "" : stripExtraTime(liveMatch.minute))
                    .fontWeight(isHalftime ? .semibold : .medium)
                    .foregroundColor(isHalftime ? .orange : .white)
                    .opacity(isHalftime ? 1.0 : 0.9)
            }
        }
        .font(fontSize)
    }

    @ViewBuilder
    private func upcomingMatchView(_ nextMatch: Game, isMinimized: Bool, compact: Bool) -> some View {
        let timeUntilMatch = nextMatch.date.timeIntervalSince(Date())
        let showCountdown = timeUntilMatch > 0 && timeUntilMatch < 3600 && Calendar.current.isDateInToday(nextMatch.date)
        let flagSize: CGFloat = compact ? 16 : 20
        let fontSize: Font = compact ? .caption : .subheadline

        HStack(spacing: compact ? 4 : 6) {
            // Home team
            if let homeFlag = TeamFlagMapper.flagAssetName(for: nextMatch.homeTeamId) {
                Image(homeFlag)
                    .resizable()
                    .scaledToFill()
                    .frame(width: flagSize, height: flagSize)
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
                    .frame(width: flagSize, height: flagSize)
                    .clipShape(Circle())
            }

            if !isMinimized && !compact {
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
        .font(fontSize)
    }

    private func formatMatchDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current

        // Check if today - just show time (SwiftUI timer handles countdown)
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }

        // Check if tomorrow
        if Calendar.current.isDateInTomorrow(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let tomorrow = NSLocalizedString("Tomorrow", comment: "")
            return "\(tomorrow), \(formatter.string(from: date))"
        }

        // Otherwise, show full date
        formatter.dateStyle = .short
        formatter.timeStyle = .short
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
