import SwiftUI

public struct ScheduleView: View {
    @Environment(\.tournamentConfig) private var config

    public init() {}

    public let upcomingMatches = [
        // December 21, 2025 - Opening Day
        ScheduledMatch(
            id: 1,
            date: "2025-12-21",
            time: "20:00",
            homeTeam: "Morocco",
            awayTeam: "Comoros",
            competition: "AFCON 2025 - Group A",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat"
        ),

        // December 22, 2025
        ScheduledMatch(
            id: 2,
            date: "2025-12-22",
            time: "15:30",
            homeTeam: "Mali",
            awayTeam: "Zambia",
            competition: "AFCON 2025 - Group A",
            venue: "Mohammed V Stadium",
            city: "Casablanca"
        ),
        ScheduledMatch(
            id: 3,
            date: "2025-12-22",
            time: "18:00",
            homeTeam: "Egypt",
            awayTeam: "Zimbabwe",
            competition: "AFCON 2025 - Group B",
            venue: "Adrar Stadium",
            city: "Agadir"
        ),
        ScheduledMatch(
            id: 4,
            date: "2025-12-22",
            time: "20:30",
            homeTeam: "South Africa",
            awayTeam: "Angola",
            competition: "AFCON 2025 - Group B",
            venue: "Marrakesh Stadium",
            city: "Marrakesh"
        ),

        // December 23, 2025
        ScheduledMatch(
            id: 5,
            date: "2025-12-23",
            time: "13:00",
            homeTeam: "Nigeria",
            awayTeam: "Tanzania",
            competition: "AFCON 2025 - Group C",
            venue: "Fez Stadium",
            city: "Fez"
        ),
        ScheduledMatch(
            id: 6,
            date: "2025-12-23",
            time: "15:30",
            homeTeam: "Tunisia",
            awayTeam: "Uganda",
            competition: "AFCON 2025 - Group C",
            venue: "Prince Moulay Abdellah Olympic Annex Stadium",
            city: "Rabat"
        ),
        ScheduledMatch(
            id: 7,
            date: "2025-12-23",
            time: "18:00",
            homeTeam: "Senegal",
            awayTeam: "Botswana",
            competition: "AFCON 2025 - Group D",
            venue: "Ibn Batouta Stadium",
            city: "Tangier"
        ),
        ScheduledMatch(
            id: 8,
            date: "2025-12-23",
            time: "20:30",
            homeTeam: "DR Congo",
            awayTeam: "Benin",
            competition: "AFCON 2025 - Group D",
            venue: "Al Barid Stadium",
            city: "Rabat"
        ),

        // December 24, 2025
        ScheduledMatch(
            id: 9,
            date: "2025-12-24",
            time: "13:00",
            homeTeam: "Algeria",
            awayTeam: "Sudan",
            competition: "AFCON 2025 - Group E",
            venue: "Moulay Hassan Stadium",
            city: "Rabat"
        ),
        ScheduledMatch(
            id: 10,
            date: "2025-12-24",
            time: "15:30",
            homeTeam: "Burkina Faso",
            awayTeam: "Equatorial Guinea",
            competition: "AFCON 2025 - Group E",
            venue: "Mohammed V Stadium",
            city: "Casablanca"
        ),
        ScheduledMatch(
            id: 11,
            date: "2025-12-24",
            time: "18:00",
            homeTeam: "Ivory Coast",
            awayTeam: "Mozambique",
            competition: "AFCON 2025 - Group F",
            venue: "Marrakesh Stadium",
            city: "Marrakesh"
        ),
        ScheduledMatch(
            id: 12,
            date: "2025-12-24",
            time: "20:30",
            homeTeam: "Cameroon",
            awayTeam: "Gabon",
            competition: "AFCON 2025 - Group F",
            venue: "Adrar Stadium",
            city: "Agadir"
        ),

        // Final - January 18, 2026
        ScheduledMatch(
            id: 52,
            date: "2026-01-18",
            time: "20:00",
            homeTeam: "Semi-final Winner 1",
            awayTeam: "Semi-final Winner 2",
            competition: "AFCON 2025 - FINAL",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat"
        )
    ]

    private var now: Date {
        Date()
    }

    private var sortedMatches: (upcoming: [ScheduledMatch], past: [ScheduledMatch]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        var upcoming: [ScheduledMatch] = []
        var past: [ScheduledMatch] = []

        for match in upcomingMatches {
            let dateTimeString = "\(match.date) \(match.time)"
            if let matchDate = formatter.date(from: dateTimeString) {
                if matchDate > now {
                    upcoming.append(match)
                } else {
                    past.append(match)
                }
            } else {
                // Fallback if parsing fails
                upcoming.append(match)
            }
        }

        return (upcoming, past)
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Upcoming Matches Section
                if !sortedMatches.upcoming.isEmpty {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(config.accentColorName))
                        Text(LocalizedStringKey("Upcoming Matches"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)

                    ForEach(sortedMatches.upcoming, id: \.id) { match in
                        ScheduledMatchCard(match: match, isPast: false)
                    }
                }

                // Past Matches Section
                if !sortedMatches.past.isEmpty {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.secondary)
                        Text(LocalizedStringKey("Past Matches"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, sortedMatches.upcoming.isEmpty ? 0 : 24)

                    ForEach(sortedMatches.past.reversed(), id: \.id) { match in
                        ScheduledMatchCard(match: match, isPast: true)
                    }
                }
            }
            .padding()
        }
    }
}

public struct ScheduledMatchCard: View {
    public let match: ScheduledMatch
    public let isPast: Bool

    @Environment(\.tournamentConfig) private var config

    public init(match: ScheduledMatch, isPast: Bool) {
        self.match = match
        self.isPast = isPast
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date and tickets
            HStack {
                HStack(spacing: 8) {
                    Text(formatDate(match.date))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isPast ? Color.secondary.opacity(0.1) : Color(config.accentColorName).opacity(0.1))
                        .foregroundColor(isPast ? .secondary : Color(config.accentColorName))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isPast ? Color.secondary : Color(config.accentColorName), lineWidth: 1)
                        )

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(match.time)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

            }

            // Competition
            Text(match.competition)
                .font(.caption)
                .foregroundColor(.secondary)

            // Teams
            HStack {
                // Home team
                HStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(config.accentColorName), Color(config.accentColorName).opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(match.homeTeam.prefix(1)))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.homeTeam)
                            .fontWeight(.medium)
                        Text("Home")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Score or VS
                if let homeScore = match.homeScore, let awayScore = match.awayScore {
                    // Show score for past matches
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text("\(homeScore)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(home: homeScore, away: awayScore))

                            Text("-")
                                .font(.title2)
                                .foregroundColor(.secondary)

                            Text("\(awayScore)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(scoreColor(home: awayScore, away: homeScore))
                        }

                        // Show penalty score if available
                        if let homePens = match.homePenaltyScore, let awayPens = match.awayPenaltyScore {
                            Text("Pens: \(homePens)-\(awayPens)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(penaltyColor(home: homePens, away: awayPens))
                        }
                    }
                } else {
                    // Show VS for upcoming matches
                    Text("VS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Away team
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(match.awayTeam)
                            .fontWeight(.medium)
                        Text("Away")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(config.secondaryColorName), Color(config.secondaryColorName).opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(match.awayTeam.prefix(1)))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }
            }

            // Venue and buttons
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text("\(match.venue) • \(match.city)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Button("View Details") {
                        // Add action
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "E, MMM d"
        return displayFormatter.string(from: date)
    }

    /// Get color for regular time score (grey for draw, green for win, red for loss)
    private func scoreColor(home: Int, away: Int) -> Color {
        if home == away {
            return .gray  // Draw
        } else if home > away {
            return Color(config.secondaryColorName)  // Win
        } else {
            return Color(config.accentColorName)  // Loss
        }
    }

    /// Get color for penalty score (green for win, red for loss)
    private func penaltyColor(home: Int, away: Int) -> Color {
        if home > away {
            return Color(config.secondaryColorName)  // Winner
        } else if home < away {
            return Color(config.accentColorName)  // Loser
        } else {
            return .gray  // Shouldn't happen in penalties, but handle draw
        }
    }
}

// MARK: - Data Models
public struct ScheduledMatch {
    public let id: Int
    public let date: String
    public let time: String
    public let homeTeam: String
    public let awayTeam: String
    public let competition: String
    public let venue: String
    public let city: String
    public var homeScore: Int?
    public var awayScore: Int?
    public var homePenaltyScore: Int?
    public var awayPenaltyScore: Int?

    public init(
        id: Int,
        date: String,
        time: String,
        homeTeam: String,
        awayTeam: String,
        competition: String,
        venue: String,
        city: String,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        homePenaltyScore: Int? = nil,
        awayPenaltyScore: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.time = time
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.competition = competition
        self.venue = venue
        self.city = city
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.homePenaltyScore = homePenaltyScore
        self.awayPenaltyScore = awayPenaltyScore
    }
}
