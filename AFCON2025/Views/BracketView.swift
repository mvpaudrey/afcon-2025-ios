import SwiftUI
import SwiftData

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
                    teamBadge(
                        teamName: match.team1,
                        teamId: match.team1Id,
                        gradient: badgeGradient(for: 1)
                    )

                    Text(match.team1)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    if let score1 = match.score1 {
                        Text("\(score1)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(for: score1, opponentScore: match.score2))
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
                    teamBadge(
                        teamName: match.team2,
                        teamId: match.team2Id,
                        gradient: badgeGradient(for: 2)
                    )

                    Text(match.team2)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()

                    if let score2 = match.score2 {
                        Text("\(score2)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(for: score2, opponentScore: match.score1))
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

    private func badgeGradient(for teamIndex: Int) -> [Color] {
        if let winner = winnerIndex {
            if teamIndex == winner {
                return [Color("moroccoGreen"), Color("moroccoGreenDark")]
            }
            return [Color("moroccoRed"), Color("moroccoRedDark")]
        }

        if teamIndex == 1 {
            return [Color("moroccoRed"), Color("moroccoRedDark")]
        }

        return [Color("moroccoGreen"), Color("moroccoGreenDark")]
    }

    private func scoreColor(for score: Int, opponentScore: Int?) -> Color {
        guard let opponentScore else { return .secondary }

        if score > opponentScore {
            return Color("moroccoGreen")
        }
        if score < opponentScore {
            return Color("moroccoRed")
        }
        return .secondary
    }

    private var winnerIndex: Int? {
        guard let score1 = match.score1, let score2 = match.score2, score1 != score2 else {
            return nil
        }
        return score1 > score2 ? 1 : 2
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }

    @ViewBuilder
    private func teamBadge(teamName: String, teamId: Int?, gradient: [Color]) -> some View {
        if let teamId, let flagAsset = TeamFlagMapper.flagAssetName(for: teamId) {
            Image(flagAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
        } else {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: gradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 20, height: 20)
                .overlay(
                    Text(String(teamName.prefix(1)))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
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
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BracketViewModel()
    @State private var selectedRound: BracketRound = .roundOf16
    @State private var scrollOffset: CGFloat = 0
    @Query(sort: \FixtureModel.date) private var fixtures: [FixtureModel]

    init() {
        _selectedRound = State(initialValue: determineCurrentRound())
    }

    private func determineCurrentRound() -> BracketRound {
        let today = Date()
        let calendar = Calendar.current

        // Round of 16 dates: January 3-6, 2026
        let r16Start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 3))!
        let r16End = calendar.date(from: DateComponents(year: 2026, month: 1, day: 6))!

        // Quarter Finals dates: January 9-10, 2026
        let qfStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 9))!
        let qfEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!

        // Semi Finals date: January 14, 2026
        let sfStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 14))!
        let sfEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 14))!

        // Final date: January 18, 2026
        let finalDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 18))!

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
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let bracketMatches = viewModel.bracketMatches {
                BracketContentView(
                    bracketMatches: bracketMatches,
                    selectedRound: $selectedRound,
                    determineCurrentRound: determineCurrentRound
                )
            } else {
                // Fallback to static data if API fails
                BracketContentView(
                    bracketMatches: BracketData.allMatches,
                    selectedRound: $selectedRound,
                    determineCurrentRound: determineCurrentRound
                )
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadBracketData()
            await viewModel.syncKnockoutFixturesForPastDates()
            viewModel.refreshBracketFromFixtures()
        }
        .onChange(of: fixtures) { _, _ in
            viewModel.refreshBracketFromFixtures()
        }
    }
}

// MARK: - Bracket Content View
private struct BracketContentView: View {
    let bracketMatches: BracketMatches
    @Binding var selectedRound: BracketRound
    let determineCurrentRound: () -> BracketRound

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
                                    Text(formatMatchDate(match))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(formatMatchTime(match))
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
                                    Text(formatMatchDate(match))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(formatMatchTime(match))
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
                                    Text(formatMatchDate(match))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("moroccoRed"))
                                    Text(formatMatchTime(match))
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
                                Text(formatMatchDate(bracketMatches.final))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("moroccoRed"))
                                Text(formatMatchTime(bracketMatches.final))
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
                                Text(formatMatchDate(bracketMatches.thirdPlace))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("moroccoRed"))
                                Text(formatMatchTime(bracketMatches.thirdPlace))
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

    private let tournamentTimeZone = TimeZone(secondsFromGMT: 3600) ?? .current

    private func matchDateTime(_ match: BracketMatch) -> Date? {
        let dateParts = match.date.split(separator: "-").map { String($0) }
        let timeParts = match.time.split(separator: ":").map { String($0) }
        guard dateParts.count == 3, timeParts.count == 2,
              let year = Int(dateParts[0]),
              let month = Int(dateParts[1]),
              let day = Int(dateParts[2]),
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = tournamentTimeZone

        return Calendar(identifier: .gregorian).date(from: components)
    }

    private func formatMatchDate(_ match: BracketMatch) -> String {
        guard let date = matchDateTime(match) else { return match.date }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        displayFormatter.timeZone = .current
        return displayFormatter.string(from: date)
    }

    private func formatMatchTime(_ match: BracketMatch) -> String {
        guard let date = matchDateTime(match) else { return match.time }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        displayFormatter.timeZone = .current
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
    let team1Id: Int?
    let team2Id: Int?
    let venue: String
    let score1: Int?
    let score2: Int?
    var penalty1: Int? = nil
    var penalty2: Int? = nil
}

struct BracketData {
    static let allMatches = BracketMatches(
        roundOf16: [
            // 37: 3 January - Tangier, 17:00
            BracketMatch(id: 37, date: "2026-01-03", time: "17:00", team1: "1D", team2: "3B/E/F", team1Id: nil, team2Id: nil, venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // 38: 3 January - Casablanca, 20:00
            BracketMatch(id: 38, date: "2026-01-03", time: "20:00", team1: "2A", team2: "2C", team1Id: nil, team2Id: nil, venue: "Mohammed V Stadium, Casablanca", score1: nil, score2: nil),
            // 39: 4 January - Rabat, 17:00
            BracketMatch(id: 39, date: "2026-01-04", time: "17:00", team1: "1A", team2: "3C/D/E", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
            // 40: 4 January - Rabat, 20:00
            BracketMatch(id: 40, date: "2026-01-04", time: "20:00", team1: "2B", team2: "2F", team1Id: nil, team2Id: nil, venue: "Al Barid Stadium, Rabat", score1: nil, score2: nil),
            // 42: 5 January - Fez, 20:00
            BracketMatch(id: 42, date: "2026-01-05", time: "20:00", team1: "1C", team2: "3A/B/F", team1Id: nil, team2Id: nil, venue: "Fez Stadium, Fez", score1: nil, score2: nil),
            // 43: 6 January - Rabat, 17:00
            BracketMatch(id: 43, date: "2026-01-06", time: "17:00", team1: "1E", team2: "2D", team1Id: nil, team2Id: nil, venue: "Moulay Hassan Stadium, Rabat", score1: nil, score2: nil),
            // 41: 5 January - Agadir, 17:00
            BracketMatch(id: 41, date: "2026-01-05", time: "17:00", team1: "1B", team2: "3A/C/D", team1Id: nil, team2Id: nil, venue: "Adrar Stadium, Agadir", score1: nil, score2: nil),
            // 44: 6 January - Marrakesh, 20:00
            BracketMatch(id: 44, date: "2026-01-06", time: "20:00", team1: "1F", team2: "2E", team1Id: nil, team2Id: nil, venue: "Marrakesh Stadium, Marrakesh", score1: nil, score2: nil)
        ],
        quarterFinals: [
            // 45: 9 January - Tangier, 17:00
            BracketMatch(id: 45, date: "2026-01-09", time: "17:00", team1: "W38", team2: "W37", team1Id: nil, team2Id: nil, venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // 46: 9 January - Rabat, 20:00
            BracketMatch(id: 46, date: "2026-01-09", time: "20:00", team1: "W40", team2: "W39", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
            // 47: 10 January - Marrakesh, 17:00
            BracketMatch(id: 47, date: "2026-01-10", time: "17:00", team1: "W43", team2: "W42", team1Id: nil, team2Id: nil, venue: "Marrakesh Stadium, Marrakesh", score1: nil, score2: nil),
            // 48: 10 January - Agadir, 20:00
            BracketMatch(id: 48, date: "2026-01-10", time: "20:00", team1: "W41", team2: "W44", team1Id: nil, team2Id: nil, venue: "Adrar Stadium, Agadir", score1: nil, score2: nil)
        ],
        semiFinals: [
            // 49: 14 January - Tangier, 18:00
            BracketMatch(id: 49, date: "2026-01-14", time: "18:00", team1: "W45", team2: "W48", team1Id: nil, team2Id: nil, venue: "Ibn Batouta Stadium, Tangier", score1: nil, score2: nil),
            // 50: 14 January - Rabat, 21:00
            BracketMatch(id: 50, date: "2026-01-14", time: "21:00", team1: "W46", team2: "W47", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil)
        ],
        // Final: 18 January - Rabat, 20:00
        final: BracketMatch(id: 52, date: "2026-01-18", time: "20:00", team1: "W49", team2: "W50", team1Id: nil, team2Id: nil, venue: "Prince Moulay Abdellah Stadium, Rabat", score1: nil, score2: nil),
        // Third Place: 17 January - Casablanca, 17:00
        thirdPlace: BracketMatch(id: 51, date: "2026-01-17", time: "17:00", team1: "L49", team2: "L50", team1Id: nil, team2Id: nil, venue: "Mohammed V Stadium, Casablanca", score1: nil, score2: nil)
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
