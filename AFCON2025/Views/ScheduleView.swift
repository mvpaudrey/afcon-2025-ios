import SwiftUI

struct ScheduleView: View {
    let upcomingMatches = [
        // December 21, 2025 - Opening Day
        ScheduledMatch(
            id: 1,
            date: "2025-12-21",
            time: "20:00",
            homeTeam: "Morocco",
            awayTeam: "Comoros",
            competition: "AFCON 2025 - Group A",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            ticketsAvailable: true
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
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 3,
            date: "2025-12-22",
            time: "18:00",
            homeTeam: "Egypt",
            awayTeam: "Zimbabwe",
            competition: "AFCON 2025 - Group B",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 4,
            date: "2025-12-22",
            time: "20:30",
            homeTeam: "South Africa",
            awayTeam: "Angola",
            competition: "AFCON 2025 - Group B",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
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
            city: "Fez",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 6,
            date: "2025-12-23",
            time: "15:30",
            homeTeam: "Tunisia",
            awayTeam: "Uganda",
            competition: "AFCON 2025 - Group C",
            venue: "Prince Moulay Abdellah Olympic Annex Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 7,
            date: "2025-12-23",
            time: "18:00",
            homeTeam: "Senegal",
            awayTeam: "Botswana",
            competition: "AFCON 2025 - Group D",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 8,
            date: "2025-12-23",
            time: "20:30",
            homeTeam: "DR Congo",
            awayTeam: "Benin",
            competition: "AFCON 2025 - Group D",
            venue: "Al Barid Stadium",
            city: "Rabat",
            ticketsAvailable: true
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
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 10,
            date: "2025-12-24",
            time: "15:30",
            homeTeam: "Burkina Faso",
            awayTeam: "Equatorial Guinea",
            competition: "AFCON 2025 - Group E",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 11,
            date: "2025-12-24",
            time: "18:00",
            homeTeam: "Ivory Coast",
            awayTeam: "Mozambique",
            competition: "AFCON 2025 - Group F",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 12,
            date: "2025-12-24",
            time: "20:30",
            homeTeam: "Cameroon",
            awayTeam: "Gabon",
            competition: "AFCON 2025 - Group F",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),

        // December 26, 2025 - Second Round Matches
        ScheduledMatch(
            id: 13,
            date: "2025-12-26",
            time: "13:00",
            homeTeam: "Morocco",
            awayTeam: "Mali",
            competition: "AFCON 2025 - Group A",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 14,
            date: "2025-12-26",
            time: "15:30",
            homeTeam: "Zambia",
            awayTeam: "Comoros",
            competition: "AFCON 2025 - Group A",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 15,
            date: "2025-12-26",
            time: "18:00",
            homeTeam: "Egypt",
            awayTeam: "South Africa",
            competition: "AFCON 2025 - Group B",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 16,
            date: "2025-12-26",
            time: "20:30",
            homeTeam: "Angola",
            awayTeam: "Zimbabwe",
            competition: "AFCON 2025 - Group B",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),

        // December 27, 2025
        ScheduledMatch(
            id: 17,
            date: "2025-12-27",
            time: "13:00",
            homeTeam: "Nigeria",
            awayTeam: "Tunisia",
            competition: "AFCON 2025 - Group C",
            venue: "Fez Stadium",
            city: "Fez",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 18,
            date: "2025-12-27",
            time: "15:30",
            homeTeam: "Uganda",
            awayTeam: "Tanzania",
            competition: "AFCON 2025 - Group C",
            venue: "Prince Moulay Abdellah Olympic Annex Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 19,
            date: "2025-12-27",
            time: "18:00",
            homeTeam: "Senegal",
            awayTeam: "DR Congo",
            competition: "AFCON 2025 - Group D",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 20,
            date: "2025-12-27",
            time: "20:30",
            homeTeam: "Benin",
            awayTeam: "Botswana",
            competition: "AFCON 2025 - Group D",
            venue: "Al Barid Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),

        // December 28, 2025
        ScheduledMatch(
            id: 21,
            date: "2025-12-28",
            time: "13:00",
            homeTeam: "Algeria",
            awayTeam: "Burkina Faso",
            competition: "AFCON 2025 - Group E",
            venue: "Moulay Hassan Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 22,
            date: "2025-12-28",
            time: "15:30",
            homeTeam: "Equatorial Guinea",
            awayTeam: "Sudan",
            competition: "AFCON 2025 - Group E",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 23,
            date: "2025-12-28",
            time: "18:00",
            homeTeam: "Ivory Coast",
            awayTeam: "Cameroon",
            competition: "AFCON 2025 - Group F",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 24,
            date: "2025-12-28",
            time: "20:30",
            homeTeam: "Gabon",
            awayTeam: "Mozambique",
            competition: "AFCON 2025 - Group F",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),

        // December 29, 2025 - Group A Final
        ScheduledMatch(
            id: 25,
            date: "2025-12-29",
            time: "18:30",
            homeTeam: "Zambia",
            awayTeam: "Morocco",
            competition: "AFCON 2025 - Group A",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 26,
            date: "2025-12-29",
            time: "18:30",
            homeTeam: "Comoros",
            awayTeam: "Mali",
            competition: "AFCON 2025 - Group A",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 27,
            date: "2025-12-29",
            time: "20:30",
            homeTeam: "Angola",
            awayTeam: "Egypt",
            competition: "AFCON 2025 - Group B",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 28,
            date: "2025-12-29",
            time: "20:30",
            homeTeam: "Zimbabwe",
            awayTeam: "South Africa",
            competition: "AFCON 2025 - Group B",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),

        // December 30, 2025 - Groups C & D Final
        ScheduledMatch(
            id: 29,
            date: "2025-12-30",
            time: "18:00",
            homeTeam: "Uganda",
            awayTeam: "Nigeria",
            competition: "AFCON 2025 - Group C",
            venue: "Fez Stadium",
            city: "Fez",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 30,
            date: "2025-12-30",
            time: "18:00",
            homeTeam: "Tanzania",
            awayTeam: "Tunisia",
            competition: "AFCON 2025 - Group C",
            venue: "Prince Moulay Abdellah Olympic Annex Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 31,
            date: "2025-12-30",
            time: "20:30",
            homeTeam: "Benin",
            awayTeam: "Senegal",
            competition: "AFCON 2025 - Group D",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 32,
            date: "2025-12-30",
            time: "20:30",
            homeTeam: "Botswana",
            awayTeam: "DR Congo",
            competition: "AFCON 2025 - Group D",
            venue: "Al Barid Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),

        // December 31, 2025 - Groups E & F Final
        ScheduledMatch(
            id: 33,
            date: "2025-12-31",
            time: "18:00",
            homeTeam: "Equatorial Guinea",
            awayTeam: "Algeria",
            competition: "AFCON 2025 - Group E",
            venue: "Moulay Hassan Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 34,
            date: "2025-12-31",
            time: "18:00",
            homeTeam: "Sudan",
            awayTeam: "Burkina Faso",
            competition: "AFCON 2025 - Group E",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 35,
            date: "2025-12-31",
            time: "20:00",
            homeTeam: "Mozambique",
            awayTeam: "Ivory Coast",
            competition: "AFCON 2025 - Group F",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 36,
            date: "2025-12-31",
            time: "20:00",
            homeTeam: "Gabon",
            awayTeam: "Cameroon",
            competition: "AFCON 2025 - Group F",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),

        // Round of 16 - January 3-6, 2026
        ScheduledMatch(
            id: 37,
            date: "2026-01-03",
            time: "17:00",
            homeTeam: "Winner Group A",
            awayTeam: "3rd Group C/D/E/F",
            competition: "AFCON 2025 - Round of 16",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 38,
            date: "2026-01-03",
            time: "20:00",
            homeTeam: "Winner Group B",
            awayTeam: "3rd Group A/C/D/E",
            competition: "AFCON 2025 - Round of 16",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 39,
            date: "2026-01-04",
            time: "17:00",
            homeTeam: "Winner Group C",
            awayTeam: "3rd Group A/B/E/F",
            competition: "AFCON 2025 - Round of 16",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 40,
            date: "2026-01-04",
            time: "20:00",
            homeTeam: "Winner Group D",
            awayTeam: "Runner-up Group B",
            competition: "AFCON 2025 - Round of 16",
            venue: "Al Barid Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 41,
            date: "2026-01-05",
            time: "17:00",
            homeTeam: "Winner Group E",
            awayTeam: "Runner-up Group F",
            competition: "AFCON 2025 - Round of 16",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 42,
            date: "2026-01-05",
            time: "20:00",
            homeTeam: "Winner Group F",
            awayTeam: "Runner-up Group E",
            competition: "AFCON 2025 - Round of 16",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 43,
            date: "2026-01-06",
            time: "17:00",
            homeTeam: "Runner-up Group A",
            awayTeam: "3rd Group B/C/D/F",
            competition: "AFCON 2025 - Round of 16",
            venue: "Moulay Hassan Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 44,
            date: "2026-01-06",
            time: "20:00",
            homeTeam: "Runner-up Group C",
            awayTeam: "3rd Group A/B/D/F",
            competition: "AFCON 2025 - Round of 16",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),

        // Quarter-finals - January 9-10, 2026
        ScheduledMatch(
            id: 45,
            date: "2026-01-09",
            time: "17:00",
            homeTeam: "Winner R1",
            awayTeam: "Winner R2",
            competition: "AFCON 2025 - Quarter-final",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 46,
            date: "2026-01-09",
            time: "20:00",
            homeTeam: "Winner R3",
            awayTeam: "Winner R4",
            competition: "AFCON 2025 - Quarter-final",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 47,
            date: "2026-01-10",
            time: "17:00",
            homeTeam: "Winner R5",
            awayTeam: "Winner R6",
            competition: "AFCON 2025 - Quarter-final",
            venue: "Marrakesh Stadium",
            city: "Marrakesh",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 48,
            date: "2026-01-10",
            time: "20:00",
            homeTeam: "Winner R7",
            awayTeam: "Winner R8",
            competition: "AFCON 2025 - Quarter-final",
            venue: "Adrar Stadium",
            city: "Agadir",
            ticketsAvailable: true
        ),

        // Semi-finals - January 14, 2026
        ScheduledMatch(
            id: 49,
            date: "2026-01-14",
            time: "17:00",
            homeTeam: "Winner QF1",
            awayTeam: "Winner QF2",
            competition: "AFCON 2025 - Semi-final",
            venue: "Ibn Batouta Stadium",
            city: "Tangier",
            ticketsAvailable: true
        ),
        ScheduledMatch(
            id: 50,
            date: "2026-01-14",
            time: "20:00",
            homeTeam: "Winner QF3",
            awayTeam: "Winner QF4",
            competition: "AFCON 2025 - Semi-final",
            venue: "Prince Moulay Abdellah Stadium",
            city: "Rabat",
            ticketsAvailable: true
        ),

        // Third Place Play-off - January 17, 2026
        ScheduledMatch(
            id: 51,
            date: "2026-01-17",
            time: "17:00",
            homeTeam: "Semi-final Loser 1",
            awayTeam: "Semi-final Loser 2",
            competition: "AFCON 2025 - Third Place",
            venue: "Mohammed V Stadium",
            city: "Casablanca",
            ticketsAvailable: true
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
            city: "Rabat",
            ticketsAvailable: true
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("moroccoRed"))
                    Text("Upcoming Matches")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)

                ForEach(upcomingMatches, id: \.id) { match in
                    ScheduledMatchCard(match: match)
                }
            }
            .padding()
        }
    }
}

struct ScheduledMatchCard: View {
    let match: ScheduledMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date and tickets
            HStack {
                HStack(spacing: 8) {
                    Text(formatDate(match.date))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("moroccoRed").opacity(0.1))
                        .foregroundColor(Color("moroccoRed"))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color("moroccoRed"), lineWidth: 1)
                        )

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(match.time)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Text(match.ticketsAvailable ? "Tickets Available" : "Sold Out")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(match.ticketsAvailable ? Color("moroccoGreen") : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(4)
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
                            gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoRedDark")]),
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

                // VS
                Text("VS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)

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
                            gradient: Gradient(colors: [Color("moroccoGreen"), Color("moroccoGreenDark")]),
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

                    if match.ticketsAvailable {
                        Button("Get Tickets") {
                            // Add action
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        .tint(Color("moroccoRed"))
                    }
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
}

// MARK: - Data Models
struct ScheduledMatch {
    let id: Int
    let date: String
    let time: String
    let homeTeam: String
    let awayTeam: String
    let competition: String
    let venue: String
    let city: String
    let ticketsAvailable: Bool
}

#Preview {
    ScheduleView()
}
