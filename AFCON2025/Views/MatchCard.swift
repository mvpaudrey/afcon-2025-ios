import SwiftUI
import AFCONClient
import ActivityKit

struct MatchCard: View {
    let match: Game
    var events: [Afcon_FixtureEvent] = []
    var showsCompetition: Bool = true

    private var statusText: String {
        let statusUpper = match.statusShort.uppercased()

        if statusUpper == "HT" {
            return NSLocalizedString("match.status.halftime", value: "HALFTIME", comment: "Halftime status")
        }

        if statusUpper == "BT" {
            return NSLocalizedString("match.status.breaktime", value: "BREAK TIME", comment: "Break time status")
        }

        switch match.status {
        case .live:
            return match.minute
        case .upcoming:
            return formatMatchTime(match.date)
        case .finished:
            return NSLocalizedString("match.status.finished", value: "FINISHED", comment: "Finished status")
        }
    }

    private func formatMatchTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func scoreColor(for score: Int, opponentScore: Int) -> Color {
        if score > opponentScore {
            return Color("moroccoGreen")
        }
        if score < opponentScore {
            return Color("moroccoRed")
        }
        return Color(.systemGray)
    }

    var body: some View {
        let statusUpper = match.statusShort.uppercased()
        let isBreak = statusUpper == "HT" || statusUpper == "BT"
        let isLive = match.status == .live && !isBreak

        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    if isLive {
                        Image(systemName: "clock")
                            .font(.caption2)
                    } else if isBreak {
                        Image(systemName: "pause.circle.fill")
                            .font(.caption2)
                    } else if match.status == .upcoming {
                        Image(systemName: "clock")
                            .font(.caption2)
                    }
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isBreak ? Color.orange : (isLive ? Color("moroccoRed") : Color(.systemGray5))
                )
                .foregroundColor(
                    (isLive || isBreak) ? .white : .secondary
                )
                .cornerRadius(12)
                
                Spacer()
                
                if showsCompetition {
                    Text(match.competition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                // Home Team
                HStack(spacing: 12) {
                    if let flagAsset = match.homeTeamFlagAsset {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("moroccoRed"), Color("moroccoRedDark")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Text(String(match.homeTeam.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }

                    Text(localizedTeamName(match.homeTeam))
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Score
                if match.status == .upcoming && match.homeScore == 0 && match.awayScore == 0 {
                    Text(LocalizedStringKey("VS"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 4) {
                        HStack(spacing: 16) {
                            Text("\(match.homeScore)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(for: match.homeScore, opponentScore: match.awayScore))

                            Text("-")
                                .foregroundColor(.secondary)

                            Text("\(match.awayScore)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(for: match.awayScore, opponentScore: match.homeScore))
                        }

                        // Show penalty score if available
                        if let homePens = match.homePenaltyScore, let awayPens = match.awayPenaltyScore {
                            Text("Pens: \(homePens)-\(awayPens)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(homePens > awayPens ? Color("moroccoGreen") : (awayPens > homePens ? Color("moroccoRed") : .secondary))
                                .monospacedDigit()
                        }
                    }
                }
                
                Spacer()
                
                // Away Team
                HStack(spacing: 12) {
                    Text(localizedTeamName(match.awayTeam))
                        .fontWeight(.medium)
                        .lineLimit(2)

                    if let flagAsset = match.awayTeamFlagAsset {
                        Image(flagAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color("moroccoGreen"), Color("moroccoGreenDark")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Text(String(match.awayTeam.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            Text(match.venue)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Events Section (goals, cards, etc.)
            if !events.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Match Events")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Prepare a concrete array to avoid Slice/ReversedCollection type issues in ForEach
                    let reversedEventsArray: [Afcon_FixtureEvent] = Array(events.reversed())
                    let maxEvents = match.status == .live ? reversedEventsArray.count : min(reversedEventsArray.count, 5)
                    let displayEvents: [Afcon_FixtureEvent] = Array(reversedEventsArray.prefix(maxEvents))
                    ForEach(displayEvents, id: \.eventKey) { event in
                        MatchEventRow(
                            event: event,
                            isHomeEvent: event.team.name == match.homeTeam
                        )
                    }

                    if match.status != .live && events.count > 5 {
                        Text("+\(events.count - 5) more events")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
}

// MARK: - Match Event Row
    struct MatchEventRow: View {
        let event: Afcon_FixtureEvent
        let isHomeEvent: Bool
        
        var body: some View {
            HStack(spacing: 0) {
                if isHomeEvent {
                    eventBubble
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    eventBubble
                }
            }
            .frame(maxWidth: .infinity, alignment: isHomeEvent ? .leading : .trailing)
        }
        
        private var eventBubble: some View {
            HStack(spacing: 8) {
                if isHomeEvent {
                    timeBadge

                    Image(systemName: eventIconForType(event.type, detail: event.detail))
                        .font(.caption)
                        .foregroundColor(eventColorForType(event.type, detail: event.detail))
                        .frame(width: 20)

                    descriptionStack
                } else {
                    descriptionStack

                    Image(systemName: eventIconForType(event.type, detail: event.detail))
                        .font(.caption)
                        .foregroundColor(eventColorForType(event.type, detail: event.detail))
                        .frame(width: 20)

                    timeBadge
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        
        private var timeBadge: some View {
            Text("\(event.time.elapsed)'\(event.time.extra > 0 ? "+\(event.time.extra)" : "")")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(timeBackgroundColor)
                .cornerRadius(4)
                .frame(width: 45, alignment: .center)
        }
        
        private var descriptionStack: some View {
            VStack(alignment: isHomeEvent ? .leading : .trailing, spacing: 2) {
                Text(eventDescriptionText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(isHomeEvent ? .leading : .trailing)
                
                let eventType = event.type.lowercased()
                
                if !event.player.name.isEmpty {
                    if eventType == "subst" {
                        Text("Out: \(event.player.name)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(isHomeEvent ? .leading : .trailing)
                    } else {
                        Text(event.player.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(isHomeEvent ? .leading : .trailing)
                    }
                }
                
                if !event.assist.name.isEmpty {
                    if eventType == "subst" {
                        Text("In: \(event.assist.name)")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                            .multilineTextAlignment(isHomeEvent ? .leading : .trailing)
                    } else if eventType == "goal" &&
                                !event.detail.lowercased().contains("penalty") &&
                                !event.detail.lowercased().contains("own") {
                        Text("Assist: \(event.assist.name)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(isHomeEvent ? .leading : .trailing)
                    }
                }
            }
        }
        
        private var timeBackgroundColor: Color {
            let type = event.type.lowercased()
            let detail = event.detail.lowercased()
            
            if detail.contains("missed penalty") || detail.contains("penalty missed") {
                return .orange
            } else if type == "goal" {
                return .green
            } else if detail.contains("red") {
                return .red
            } else if detail.contains("yellow") {
                return .yellow
            } else if type == "subst" {
                return .blue
            } else if type == "var" {
                return .purple
            }
            return .gray
        }
        
        private var eventDescriptionText: String {
            let type = event.type.lowercased()
            let detail = event.detail
            
            if type == "goal" {
                if detail.lowercased().contains("own") {
                    return "Own Goal"
                } else if detail.lowercased().contains("penalty") {
                    return "Penalty Goal ⚽"
                } else {
                    return "Goal"
                }
            } else if detail.lowercased().contains("missed penalty") || detail.lowercased().contains("penalty missed") {
                return "Penalty Missed ✗"
            } else if type == "card" {
                return detail
            } else if type == "subst" {
                return "Substitution"
            } else if type == "var" {
                return "VAR - \(detail)"
            }
            return detail.isEmpty ? type.capitalized : detail
        }
        
        private func eventIconForType(_ type: String, detail: String) -> String {
            let lowerType = type.lowercased()
            let lowerDetail = detail.lowercased()
            
            if lowerDetail.contains("missed penalty") || lowerDetail.contains("penalty missed") {
                return "xmark.circle.fill"
            } else if lowerType == "goal" {
                return "soccerball.circle.fill"
            } else if lowerDetail.contains("red") {
                return "xmark.square.fill"
            } else if lowerDetail.contains("yellow") {
                return "square.fill"
            } else if lowerType == "subst" {
                return "arrow.left.arrow.right.circle.fill"
            } else if lowerType == "var" {
                return "video.circle.fill"
            }
            return "circle.fill"
        }
        
        private func eventColorForType(_ type: String, detail: String) -> Color {
            let lowerType = type.lowercased()
            let lowerDetail = detail.lowercased()
            
            if lowerDetail.contains("missed penalty") || lowerDetail.contains("penalty missed") {
                return .red
            } else if lowerType == "goal" {
                return .green
            } else if lowerDetail.contains("red") {
                return .red
            } else if lowerDetail.contains("yellow") {
                return .yellow
            } else if lowerType == "subst" {
                return .blue
            } else if lowerType == "var" {
                return .purple
            }
            return .gray
        }
    }
}

// MARK: - Previews
#Preview("Penalty Shootout Match") {
    let penaltyMatch = Game(
        id: 1,
        homeTeam: "Morocco",
        awayTeam: "Egypt",
        homeTeamId: 31,
        awayTeamId: 32,
        homeScore: 1,
        awayScore: 1,
        homePenaltyScore: 3,
        awayPenaltyScore: 2,
        status: .live,
        minute: "Penalties",
        competition: "AFCON 2025 - Quarter Final",
        venue: "Stade Prince Moulay Abdallah, Rabat",
        date: Date(),
        statusShort: "P"
    )

    ScrollView {
        VStack(spacing: 16) {
            MatchCard(match: penaltyMatch, events: [])
        }
        .padding()
    }
}

#Preview("Regular Live Match") {
    let liveMatch = Game(
        id: 2,
        homeTeam: "Senegal",
        awayTeam: "Nigeria",
        homeTeamId: 13,
        awayTeamId: 19,
        homeScore: 2,
        awayScore: 1,
        homePenaltyScore: nil,
        awayPenaltyScore: nil,
        status: .live,
        minute: "67'",
        competition: "AFCON 2025 - Semi Final",
        venue: "Stade de Marrakech, Marrakech",
        date: Date(),
        statusShort: "2H"
    )

    ScrollView {
        VStack(spacing: 16) {
            MatchCard(match: liveMatch, events: [])
        }
        .padding()
    }
}
