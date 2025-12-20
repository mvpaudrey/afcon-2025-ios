import SwiftUI

// MARK: - Match Card View
struct MatchCardView: View {
    let match: BracketMatch
    let isFinal: Bool

    init(match: BracketMatch, isFinal: Bool = false) {
        self.match = match
        self.isFinal = isFinal
    }

    var body: some View {
        VStack(spacing: 0) {
            // Match Content
            VStack(spacing: 0) {
                // Team 1
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color("moroccoRed"), Color("moroccoRedDark")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(match.team1.prefix(1)))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )

                    Text(match.team1)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    if let score1 = match.score1 {
                        Text("\(score1)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(score1 > (match.score2 ?? 0) ? Color("moroccoGreen") : .secondary)
                    } else {
                        Text("-")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // Team 2
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color("moroccoGreen"), Color("moroccoGreenDark")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(String(match.team2.prefix(1)))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )

                    Text(match.team2)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    if let score2 = match.score2 {
                        Text("\(score2)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(score2 > (match.score1 ?? 0) ? Color("moroccoGreen") : .secondary)
                    } else {
                        Text("-")
                            .font(.footnote)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .background(
                isFinal ?
                    LinearGradient(colors: [Color("moroccoRed").opacity(0.1), Color("moroccoGreen").opacity(0.1)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isFinal ? Color("moroccoRed") : Color.gray.opacity(0.3),
                    lineWidth: isFinal ? 2 : 1
                )
        )
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }
}

// MARK: - Stage Label
struct StageLabel: View {
    let title: String

    var body: some View {
        Text(LocalizedStringKey(title))
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color("moroccoRed"))
            .padding(.vertical, 6)
    }
}


// MARK: - Round Selection
enum BracketRound: String, CaseIterable {
    case roundOf16 = "Round of 16"
    case quarterFinals = "Quarter Finals"
    case semiFinals = "Semi Finals"
    case final = "Final"

    var localizedKey: LocalizedStringKey {
        LocalizedStringKey(self.rawValue)
    }
}

// MARK: - Main Bracket View
struct BracketView: View {
    let bracketMatches = BracketData.allMatches
    @State private var selectedRound: BracketRound = .roundOf16
    @State private var scrollOffset: CGFloat = 0

    init() {
        _selectedRound = State(initialValue: determineCurrentRound())
    }

    private func determineCurrentRound() -> BracketRound {
        let today = Date()
        let calendar = Calendar.current

        // Round of 16 dates: January 3-6, 2026
        let r16Start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 3))!
        let r16End = calendar.date(from: DateComponents(year: 2026, month: 1, day: 6))!

        // Quarter Finals dates: January 11-12, 2026
        let qfStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 11))!
        let qfEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 12))!

        // Semi Finals dates: January 15-16, 2026
        let sfStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let sfEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 16))!

        // Final date: January 19, 2026
        let finalDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 19))!

        if today >= r16Start && today <= r16End {
            return .roundOf16
        } else if today >= qfStart && today <= qfEnd {
            return .quarterFinals
        } else if today >= sfStart && today <= sfEnd {
            return .semiFinals
        } else if today >= finalDate {
            return .final
        } else if today > r16End && today < qfStart {
            return .quarterFinals
        } else if today > qfEnd && today < sfStart {
            return .semiFinals
        } else if today > sfEnd && today < finalDate {
            return .final
        } else {
            return .roundOf16 // Default to Round of 16 if before tournament
        }
    }

    // Shared constants for positioning
    let cardWidth: CGFloat = 160
    let cardHeight: CGFloat = 70
    let r16Left: CGFloat = 20
    let qfLeft: CGFloat = 300
    let sfLeft: CGFloat = 620
    let finalLeft: CGFloat = 920

    // Calculate all Y positions
    var r16YCenters: [CGFloat] {
        [60, 190, 320, 450, 580, 710, 840, 970].map { $0 + cardHeight / 2 }
    }

    var qfYCenters: [CGFloat] {
        [
            (r16YCenters[0] + r16YCenters[1]) / 2,
            (r16YCenters[2] + r16YCenters[3]) / 2,
            (r16YCenters[4] + r16YCenters[5]) / 2,
            (r16YCenters[6] + r16YCenters[7]) / 2
        ]
    }

    var sfYCenters: [CGFloat] {
        [300, 500].map { $0 + cardHeight / 2 }
    }

    var finalYCenter: CGFloat {
        400 + cardHeight / 2
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // Round Selection Header
                    HStack(spacing: 20) {
                        ForEach(BracketRound.allCases, id: \.self) { round in
                            Button(action: {
                                selectedRound = round
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    switch round {
                                    case .roundOf16:
                                        proxy.scrollTo("round16", anchor: .center)
                                    case .quarterFinals:
                                        proxy.scrollTo("quarterfinals", anchor: .center)
                                    case .semiFinals:
                                        proxy.scrollTo("semifinals", anchor: .center)
                                    case .final:
                                        proxy.scrollTo("final", anchor: .center)
                                    }
                                }
                            }) {
                                Text(round.localizedKey)
                                    .font(.system(size: 14, weight: selectedRound == round ? .bold : .medium))
                                    .foregroundColor(selectedRound == round ? Color("moroccoRed") : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedRound == round ? Color("moroccoRed").opacity(0.1) : Color.clear)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color("moroccoRed"))

                        Text(LocalizedStringKey("AFCON 2025"))
                            .font(.system(size: 38, weight: .bold))

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color("moroccoRed"))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13))
                        Text(LocalizedStringKey("Africa Cup of Nations - Morocco"))
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.secondary)

                    Text(LocalizedStringKey("21 December 2025 - 18 January 2026"))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)

                // Bracket
                ZStack(alignment: .topLeading) {
                    // Stage labels positioned directly above their cards
                    VStack {
                        HStack(spacing: 0) {
                            StageLabel(title: "Round of 16")
                                .frame(width: cardWidth)
                                .position(x: r16Left + cardWidth / 2, y: 15)
                                .id("round16")

                            StageLabel(title: "Quarter Finals")
                                .frame(width: cardWidth)
                                .position(x: qfLeft + cardWidth / 2, y: 15)
                                .id("quarterfinals")

                            StageLabel(title: "Semi Finals")
                                .frame(width: cardWidth)
                                .position(x: sfLeft + cardWidth / 2, y: 15)
                                .id("semifinals")

                            StageLabel(title: "Final")
                                .frame(width: cardWidth)
                                .position(x: finalLeft + cardWidth / 2, y: 15)
                                .id("final")
                        }
                        .frame(width: 1300, height: 30)
                    }

                    // Connector lines
                    Canvas { context, size in
                        let lineWidth: CGFloat = 2
                        let cardCenterOffset: CGFloat = 17 // Offset to align with card divider

                        // Round of 16 to Quarter Finals
                        for i in 0..<4 {
                            let y1 = r16YCenters[i * 2] + cardCenterOffset
                            let y2 = r16YCenters[i * 2 + 1] + cardCenterOffset
                            let qfY = qfYCenters[i] + cardCenterOffset
                            let x1 = r16Left + cardWidth
                            let midX = (r16Left + cardWidth + qfLeft) / 2
                            let x2 = qfLeft

                            var path = Path()
                            path.move(to: CGPoint(x: x1, y: y1))
                            path.addLine(to: CGPoint(x: midX, y: y1))
                            path.addLine(to: CGPoint(x: midX, y: qfY))

                            path.move(to: CGPoint(x: x1, y: y2))
                            path.addLine(to: CGPoint(x: midX, y: y2))
                            path.addLine(to: CGPoint(x: midX, y: qfY))

                            path.move(to: CGPoint(x: midX, y: qfY))
                            path.addLine(to: CGPoint(x: x2, y: qfY))

                            context.stroke(path, with: .color(Color("moroccoRed").opacity(0.4)), lineWidth: lineWidth)
                        }

                        // Quarter Finals to Semi Finals
                        for i in 0..<2 {
                            let y1 = qfYCenters[i * 2] + cardCenterOffset
                            let y2 = qfYCenters[i * 2 + 1] + cardCenterOffset
                            let sfY = sfYCenters[i] + cardCenterOffset
                            let x1 = qfLeft + cardWidth
                            let midX = (qfLeft + cardWidth + sfLeft) / 2
                            let x2 = sfLeft

                            var path = Path()
                            path.move(to: CGPoint(x: x1, y: y1))
                            path.addLine(to: CGPoint(x: midX, y: y1))
                            path.addLine(to: CGPoint(x: midX, y: sfY))

                            path.move(to: CGPoint(x: x1, y: y2))
                            path.addLine(to: CGPoint(x: midX, y: y2))
                            path.addLine(to: CGPoint(x: midX, y: sfY))

                            path.move(to: CGPoint(x: midX, y: sfY))
                            path.addLine(to: CGPoint(x: x2, y: sfY))

                            context.stroke(path, with: .color(Color("moroccoRed").opacity(0.4)), lineWidth: lineWidth)
                        }

                        // Semi Finals to Final
                        let sf1Y = sfYCenters[0] + cardCenterOffset
                        let sf2Y = sfYCenters[1] + cardCenterOffset
                        let sfEndX = sfLeft + cardWidth
                        let finalMidX = (sfEndX + finalLeft) / 2

                        var finalPath = Path()
                        finalPath.move(to: CGPoint(x: sfEndX, y: sf1Y))
                        finalPath.addLine(to: CGPoint(x: finalMidX, y: sf1Y))
                        finalPath.addLine(to: CGPoint(x: finalMidX, y: finalYCenter + cardCenterOffset))

                        finalPath.move(to: CGPoint(x: sfEndX, y: sf2Y))
                        finalPath.addLine(to: CGPoint(x: finalMidX, y: sf2Y))
                        finalPath.addLine(to: CGPoint(x: finalMidX, y: finalYCenter + cardCenterOffset))

                        finalPath.move(to: CGPoint(x: finalMidX, y: finalYCenter + cardCenterOffset))
                        finalPath.addLine(to: CGPoint(x: finalLeft, y: finalYCenter + cardCenterOffset))

                        context.stroke(finalPath, with: .color(Color("moroccoRed").opacity(0.6)), lineWidth: 3)

                        // Semi Finals to Third Place
                        let thirdPlaceY = finalYCenter + 150 + cardCenterOffset
                        let thirdPlaceMidX = finalMidX - 30
                        var thirdPath = Path()

                        thirdPath.move(to: CGPoint(x: sfEndX, y: sf1Y))
                        thirdPath.addLine(to: CGPoint(x: thirdPlaceMidX, y: sf1Y))
                        thirdPath.addLine(to: CGPoint(x: thirdPlaceMidX, y: thirdPlaceY))

                        thirdPath.move(to: CGPoint(x: sfEndX, y: sf2Y))
                        thirdPath.addLine(to: CGPoint(x: thirdPlaceMidX, y: sf2Y))
                        thirdPath.addLine(to: CGPoint(x: thirdPlaceMidX, y: thirdPlaceY))

                        thirdPath.move(to: CGPoint(x: thirdPlaceMidX, y: thirdPlaceY))
                        thirdPath.addLine(to: CGPoint(x: finalLeft, y: thirdPlaceY))

                        context.stroke(thirdPath, with: .color(Color("moroccoGreen").opacity(0.4)), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                    .frame(width: 1300, height: 1300)
                    .offset(y: 40)

                    // Round of 16 matches with date/venue/time info above
                    ForEach(Array(bracketMatches.roundOf16.enumerated()), id: \.element.id) { index, match in
                        VStack(spacing: 4) {
                            // Date, Time and Venue above card
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(formatMatchDate(match.date))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(match.time)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                Text(extractVenueCity(match.venue))
                                    .font(.caption2)
                                    .foregroundColor(Color("moroccoGreen"))
                                    .lineLimit(1)
                            }

                            // Match Card
                            MatchCardView(match: match)
                                .frame(width: cardWidth, height: cardHeight)
                        }
                        .position(x: r16Left + cardWidth / 2, y: 40 + r16YCenters[index])
                    }

                    // Quarter Finals matches with date/venue/time info above
                    ForEach(Array(bracketMatches.quarterFinals.enumerated()), id: \.element.id) { index, match in
                        VStack(spacing: 4) {
                            // Date, Time and Venue above card
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(formatMatchDate(match.date))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(match.time)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                Text(extractVenueCity(match.venue))
                                    .font(.caption2)
                                    .foregroundColor(Color("moroccoGreen"))
                                    .lineLimit(1)
                            }

                            // Match Card
                            MatchCardView(match: match)
                                .frame(width: cardWidth, height: cardHeight)
                        }
                        .position(x: qfLeft + cardWidth / 2, y: 40 + qfYCenters[index])
                    }

                    // Semi Finals matches with date/venue/time info above
                    ForEach(Array(bracketMatches.semiFinals.enumerated()), id: \.element.id) { index, match in
                        VStack(spacing: 4) {
                            // Date, Time and Venue above card
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(formatMatchDate(match.date))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(match.time)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                Text(extractVenueCity(match.venue))
                                    .font(.caption2)
                                    .foregroundColor(Color("moroccoGreen"))
                                    .lineLimit(1)
                            }

                            // Match Card
                            MatchCardView(match: match)
                                .frame(width: cardWidth, height: cardHeight)
                        }
                        .position(x: sfLeft + cardWidth / 2, y: 40 + sfYCenters[index])
                    }

                    // Final with date/venue/time info above
                    VStack(spacing: 4) {
                        // Date, Time and Venue above card
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Text(formatMatchDate(bracketMatches.final.date))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("moroccoRed"))
                                Text(bracketMatches.final.time)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Text(extractVenueCity(bracketMatches.final.venue))
                                .font(.caption2)
                                .foregroundColor(Color("moroccoGreen"))
                                .lineLimit(1)
                        }

                        // Match Card
                        MatchCardView(match: bracketMatches.final, isFinal: true)
                            .frame(width: cardWidth, height: cardHeight)
                    }
                    .position(x: finalLeft + cardWidth / 2, y: 40 + finalYCenter)

                    // Third Place with date/venue/time info above
                    VStack(spacing: 4) {
                        // Date, Time and Venue above card
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Text(formatMatchDate(bracketMatches.thirdPlace.date))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("moroccoRed"))
                                Text(bracketMatches.thirdPlace.time)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Text(extractVenueCity(bracketMatches.thirdPlace.venue))
                                .font(.caption2)
                                .foregroundColor(Color("moroccoGreen"))
                                .lineLimit(1)
                        }

                        // Match Card
                        MatchCardView(match: bracketMatches.thirdPlace)
                            .frame(width: cardWidth, height: cardHeight)
                    }
                    .position(x: finalLeft + cardWidth / 2, y: 40 + finalYCenter + 150)
                }
                .frame(width: 1300, height: 1300)
                .padding(20)

            }
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [
                    Color("moroccoGreen").opacity(0.08),
                    Color("moroccoRed").opacity(0.08)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    switch selectedRound {
                    case .roundOf16:
                        proxy.scrollTo("round16", anchor: .center)
                    case .quarterFinals:
                        proxy.scrollTo("quarterfinals", anchor: .center)
                    case .semiFinals:
                        proxy.scrollTo("semifinals", anchor: .center)
                    case .final:
                        proxy.scrollTo("final", anchor: .center)
                    }
                }
            }
                }
            }
        }
    }

    private func formatMatchDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }

    private func extractVenueCity(_ venue: String) -> String {
        let components = venue.components(separatedBy: ", ")
        return components.last ?? venue
    }

}

// MARK: - Data Models (keeping existing ones)
struct BracketMatch {
    let id: Int
    let date: String
    let time: String
    let team1: String
    let team2: String
    let venue: String
    let score1: Int?
    let score2: Int?
}

struct BracketData {
    static let allMatches = BracketMatches(
        roundOf16: [
            // R1: 3 January - Tangier, 18:00
            BracketMatch(id: 1, date: "2026-01-03", time: "18:00", team1: "Winner Group D", team2: "3rd Group B/E/F", venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // R2: 3 January - Casablanca, 20:30
            BracketMatch(id: 2, date: "2026-01-03", time: "20:30", team1: "Runner-up Group A", team2: "Runner-up Group C", venue: "Mohammed V Stadium, Casablanca", score1: nil, score2: nil),
            // R3: 4 January - Rabat, 18:00
            BracketMatch(id: 3, date: "2026-01-04", time: "18:00", team1: "Winner Group A", team2: "3rd Group C/D/E", venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
            // R4: 4 January - Rabat, 20:30
            BracketMatch(id: 4, date: "2026-01-04", time: "20:30", team1: "Runner-up Group B", team2: "Runner-up Group F", venue: "Al Barid Stadium, Rabat", score1: nil, score2: nil),
            // R5: 5 January - Agadir, 18:00
            BracketMatch(id: 5, date: "2026-01-05", time: "18:00", team1: "Winner Group B", team2: "3rd Group A/C/D", venue: "Adrar Stadium, Agadir", score1: nil, score2: nil),
            // R6: 5 January - Fez, 20:30
            BracketMatch(id: 6, date: "2026-01-05", time: "20:30", team1: "Winner Group C", team2: "3rd Group A/B/F", venue: "Fez Stadium, Fez", score1: nil, score2: nil),
            // R7: 6 January - Rabat, 18:00
            BracketMatch(id: 7, date: "2026-01-06", time: "18:00", team1: "Winner Group E", team2: "Runner-up Group D", venue: "Moulay Hassan Stadium, Rabat", score1: nil, score2: nil),
            // R8: 6 January - Marrakesh, 20:30
            BracketMatch(id: 8, date: "2026-01-06", time: "20:30", team1: "Winner Group F", team2: "Runner-up Group E", venue: "Marrakesh Stadium, Marrakesh", score1: nil, score2: nil)
        ],
        quarterFinals: [
            // QF1: 9 January - Tangier, 18:00
            BracketMatch(id: 9, date: "2026-01-09", time: "18:00", team1: "Winner R2", team2: "Winner R1", venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // QF2: 9 January - Rabat, 20:30
            BracketMatch(id: 10, date: "2026-01-09", time: "20:30", team1: "Winner R4", team2: "Winner R3", venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
            // QF3: 10 January - Marrakesh, 18:00
            BracketMatch(id: 11, date: "2026-01-10", time: "18:00", team1: "Winner R7", team2: "Winner R6", venue: "Marrakesh Stadium, Marrakesh", score1: nil, score2: nil),
            // QF4: 10 January - Agadir, 20:30
            BracketMatch(id: 12, date: "2026-01-10", time: "20:30", team1: "Winner R5", team2: "Winner R8", venue: "Adrar Stadium, Agadir", score1: nil, score2: nil)
        ],
        semiFinals: [
            // SF1: 14 January - Tangier, 18:00
            BracketMatch(id: 13, date: "2026-01-14", time: "18:00", team1: "Winner QF1", team2: "Winner QF4", venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // SF2: 14 January - Rabat, 20:30
            BracketMatch(id: 14, date: "2026-01-14", time: "20:30", team1: "Winner QF3", team2: "Winner QF2", venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil)
        ],
        // Final: 18 January - Rabat, 20:00
        final: BracketMatch(id: 15, date: "2026-01-18", time: "20:00", team1: "Winner SF1", team2: "Winner SF2", venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
        // Third Place: 17 January - Casablanca, 20:00
        thirdPlace: BracketMatch(id: 16, date: "2026-01-17", time: "20:00", team1: "Loser SF1", team2: "Loser SF2", venue: "Mohammed V Stadium, Casablanca", score1: nil, score2: nil)
    )
}

struct BracketMatches {
    let roundOf16: [BracketMatch]
    let quarterFinals: [BracketMatch]
    let semiFinals: [BracketMatch]
    let final: BracketMatch
    let thirdPlace: BracketMatch
}

#Preview {
    BracketView()
}
