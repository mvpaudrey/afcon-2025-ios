import SwiftUI
import SwiftData
import TournamentKit

// MARK: - Match Card

private struct FWCMatchCardView: View {
    let match: FWCBracketMatch
    let isFinal: Bool

    init(match: FWCBracketMatch, isFinal: Bool = false) {
        self.match = match
        self.isFinal = isFinal
    }

    var body: some View {
        VStack(spacing: 0) {
            teamRow(name: match.team1, teamId: match.team1Id,
                    score: match.score1, opponentScore: match.score2,
                    penalty: match.penalty1, opponentPenalty: match.penalty2)
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            teamRow(name: match.team2, teamId: match.team2Id,
                    score: match.score2, opponentScore: match.score1,
                    penalty: match.penalty2, opponentPenalty: match.penalty1)
        }
        .background(
            isFinal
                ? LinearGradient(
                    colors: [Color("fifaBlue").opacity(0.08), Color("fifaGold").opacity(0.08)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color(.systemBackground)],
                                 startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFinal ? Color("fifaGold") : Color.gray.opacity(0.3),
                        lineWidth: isFinal ? 2 : 1)
        )
    }

    @ViewBuilder
    private func teamRow(name: String, teamId: Int?, score: Int?, opponentScore: Int?,
                         penalty: Int?, opponentPenalty: Int?) -> some View {
        HStack {
            if let id = teamId, let asset = TeamFlagMapper.flagAssetName(for: id) {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
            } else {
                Circle()
                    .fill(Color("fifaBlue").opacity(0.25))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                    )
            }
            Text(localizedTeamName(name))
                .font(.caption).fontWeight(.medium)
                .lineLimit(1).truncationMode(.tail)
            Spacer()
            if let score {
                HStack(spacing: 2) {
                    Text("\(score)")
                        .foregroundColor(score > (opponentScore ?? -1)
                                         ? Color("fifaBlue") : .secondary)
                    if let pen = penalty {
                        Text("(\(pen))")
                            .foregroundColor(pen > (opponentPenalty ?? -1)
                                             ? Color("fifaBlue") : Color("fifaGold"))
                    }
                }
                .font(.footnote).fontWeight(.bold)
            } else {
                Text("-").font(.footnote).foregroundColor(.gray.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Stage Label

private struct FWCStageLabel: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color("fifaBlue"))
            .padding(.vertical, 6)
    }
}

// MARK: - Bracket Content

private struct FWCBracketContentView: View {

    let matches: FWCBracketMatches
    @Binding var selectedRound: FWCBracketRound

    @State private var scrollRequestId = UUID()

    // Layout constants
    let cardWidth: CGFloat  = 160
    let cardHeight: CGFloat = 70
    let r32Left: CGFloat    = 20
    let r16Left: CGFloat    = 300
    let qfLeft: CGFloat     = 580
    let sfLeft: CGFloat     = 860
    let finalLeft: CGFloat  = 1140

    // Y centres calculés (top + cardHeight/2)
    var r32YCenters: [CGFloat] {
        [60, 190, 320, 450, 580, 710, 840, 970,
         1100, 1230, 1360, 1490, 1620, 1750, 1880, 2010]
            .map { $0 + cardHeight / 2 }
    }
    var r16YCenters: [CGFloat] {
        (0..<8).map { (i: Int) -> CGFloat in (r32YCenters[i * 2] + r32YCenters[i * 2 + 1]) / 2 }
    }
    var qfYCenters: [CGFloat] {
        (0..<4).map { (i: Int) -> CGFloat in (r16YCenters[i * 2] + r16YCenters[i * 2 + 1]) / 2 }
    }
    var sfYCenters: [CGFloat] {
        (0..<2).map { (i: Int) -> CGFloat in (qfYCenters[i * 2] + qfYCenters[i * 2 + 1]) / 2 }
    }
    var finalYCenter: CGFloat     { (sfYCenters[0] + sfYCenters[1]) / 2 }
    var thirdPlaceYCenter: CGFloat { finalYCenter + 150 }

    var body: some View {
        VStack(spacing: 0) {

            // Round picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(FWCBracketRound.allCases, id: \.self) { round in
                        Button {
                            selectedRound = round
                        } label: {
                            Text(LocalizedStringKey(round.localizedKey))
                                .font(.system(size: 14,
                                              weight: selectedRound == round ? .bold : .medium))
                                .foregroundColor(selectedRound == round
                                                 ? Color("fifaBlue") : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedRound == round
                                              ? Color("fifaBlue").opacity(0.1) : Color.clear)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))

            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {

                        // Connector lines — drawing inline (Canvas est @escaping,
                        // les propriétés du struct sont capturées par valeur)
                        Canvas { context, _ in
                            let lw: CGFloat = 2
                            let co: CGFloat = 17  // offset vers le séparateur de la carte

                            // R32 → R16
                            let r32EndX   = r32Left + cardWidth
                            let midR32R16 = (r32EndX + r16Left) / 2
                            for i in 0..<8 {
                                let y1   = r32YCenters[i * 2]     + co
                                let y2   = r32YCenters[i * 2 + 1] + co
                                let yR16 = r16YCenters[i]          + co
                                var p = Path()
                                p.move(to: CGPoint(x: r32EndX,   y: y1))
                                p.addLine(to: CGPoint(x: midR32R16, y: y1))
                                p.addLine(to: CGPoint(x: midR32R16, y: yR16))
                                p.move(to: CGPoint(x: r32EndX,   y: y2))
                                p.addLine(to: CGPoint(x: midR32R16, y: y2))
                                p.addLine(to: CGPoint(x: midR32R16, y: yR16))
                                p.move(to: CGPoint(x: midR32R16, y: yR16))
                                p.addLine(to: CGPoint(x: r16Left,   y: yR16))
                                context.stroke(p, with: .color(Color("fifaBlue").opacity(0.4)),
                                               lineWidth: lw)
                            }

                            // R16 → QF
                            let r16EndX  = r16Left + cardWidth
                            let midR16QF = (r16EndX + qfLeft) / 2
                            for i in 0..<4 {
                                let y1  = r16YCenters[i * 2]     + co
                                let y2  = r16YCenters[i * 2 + 1] + co
                                let yQF = qfYCenters[i]           + co
                                var p = Path()
                                p.move(to: CGPoint(x: r16EndX,  y: y1))
                                p.addLine(to: CGPoint(x: midR16QF, y: y1))
                                p.addLine(to: CGPoint(x: midR16QF, y: yQF))
                                p.move(to: CGPoint(x: r16EndX,  y: y2))
                                p.addLine(to: CGPoint(x: midR16QF, y: y2))
                                p.addLine(to: CGPoint(x: midR16QF, y: yQF))
                                p.move(to: CGPoint(x: midR16QF, y: yQF))
                                p.addLine(to: CGPoint(x: qfLeft,   y: yQF))
                                context.stroke(p, with: .color(Color("fifaBlue").opacity(0.4)),
                                               lineWidth: lw)
                            }

                            // QF → SF
                            let qfEndX  = qfLeft + cardWidth
                            let midQFSF = (qfEndX + sfLeft) / 2
                            for i in 0..<2 {
                                let y1  = qfYCenters[i * 2]     + co
                                let y2  = qfYCenters[i * 2 + 1] + co
                                let ySF = sfYCenters[i]           + co
                                var p = Path()
                                p.move(to: CGPoint(x: qfEndX,  y: y1))
                                p.addLine(to: CGPoint(x: midQFSF, y: y1))
                                p.addLine(to: CGPoint(x: midQFSF, y: ySF))
                                p.move(to: CGPoint(x: qfEndX,  y: y2))
                                p.addLine(to: CGPoint(x: midQFSF, y: y2))
                                p.addLine(to: CGPoint(x: midQFSF, y: ySF))
                                p.move(to: CGPoint(x: midQFSF, y: ySF))
                                p.addLine(to: CGPoint(x: sfLeft,  y: ySF))
                                context.stroke(p, with: .color(Color("fifaBlue").opacity(0.5)),
                                               lineWidth: lw)
                            }

                            // SF → Finale
                            let sfEndX   = sfLeft + cardWidth
                            let midSFFin = (sfEndX + finalLeft) / 2
                            let sf1Y = sfYCenters[0]  + co
                            let sf2Y = sfYCenters[1]  + co
                            let finY = finalYCenter    + co
                            var fp = Path()
                            fp.move(to: CGPoint(x: sfEndX,   y: sf1Y))
                            fp.addLine(to: CGPoint(x: midSFFin, y: sf1Y))
                            fp.addLine(to: CGPoint(x: midSFFin, y: finY))
                            fp.move(to: CGPoint(x: sfEndX,   y: sf2Y))
                            fp.addLine(to: CGPoint(x: midSFFin, y: sf2Y))
                            fp.addLine(to: CGPoint(x: midSFFin, y: finY))
                            fp.move(to: CGPoint(x: midSFFin, y: finY))
                            fp.addLine(to: CGPoint(x: finalLeft, y: finY))
                            context.stroke(fp, with: .color(Color("fifaBlue").opacity(0.7)),
                                           lineWidth: 3)

                            // SF → 3e Place (tirets dorés)
                            let tpY   = thirdPlaceYCenter + co
                            let midTP = midSFFin - 30
                            var tp = Path()
                            tp.move(to: CGPoint(x: sfEndX, y: sf1Y))
                            tp.addLine(to: CGPoint(x: midTP,  y: sf1Y))
                            tp.addLine(to: CGPoint(x: midTP,  y: tpY))
                            tp.move(to: CGPoint(x: sfEndX, y: sf2Y))
                            tp.addLine(to: CGPoint(x: midTP,  y: sf2Y))
                            tp.addLine(to: CGPoint(x: midTP,  y: tpY))
                            tp.move(to: CGPoint(x: midTP,  y: tpY))
                            tp.addLine(to: CGPoint(x: finalLeft, y: tpY))
                            context.stroke(tp,
                                           with: .color(Color("fifaGold").opacity(0.5)),
                                           style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                        .frame(width: 1380, height: 2200)
                        .offset(y: 40)

                        // R32 — 16 cartes
                        ForEach(Array(matches.roundOf32.enumerated()), id: \.element.id) { i, m in
                            cardColumn(match: m, x: r32Left, y: r32YCenters[i])
                                .id(i == 0 ? "r32" : "r32_\(m.id)")
                        }
                        FWCStageLabel(title: LocalizedStringKey(FWCBracketRound.roundOf32.localizedKey))
                            .position(x: r32Left + cardWidth / 2, y: 15)

                        // R16 — 8 cartes
                        ForEach(Array(matches.roundOf16.enumerated()), id: \.element.id) { i, m in
                            cardColumn(match: m, x: r16Left, y: r16YCenters[i])
                                .id(i == 0 ? "r16" : "r16_\(m.id)")
                        }
                        FWCStageLabel(title: LocalizedStringKey(FWCBracketRound.roundOf16.localizedKey))
                            .position(x: r16Left + cardWidth / 2, y: 15)

                        // QF — 4 cartes
                        ForEach(Array(matches.quarterFinals.enumerated()), id: \.element.id) { i, m in
                            cardColumn(match: m, x: qfLeft, y: qfYCenters[i])
                                .id(i == 0 ? "quarterfinals" : "qf_\(m.id)")
                        }
                        FWCStageLabel(title: LocalizedStringKey(FWCBracketRound.quarterFinals.localizedKey))
                            .position(x: qfLeft + cardWidth / 2, y: 15)

                        // SF — 2 cartes
                        ForEach(Array(matches.semiFinals.enumerated()), id: \.element.id) { i, m in
                            cardColumn(match: m, x: sfLeft, y: sfYCenters[i])
                                .id(i == 0 ? "semifinals" : "sf_\(m.id)")
                        }
                        FWCStageLabel(title: LocalizedStringKey(FWCBracketRound.semiFinals.localizedKey))
                            .position(x: sfLeft + cardWidth / 2, y: 15)

                        // Finale
                        cardColumn(match: matches.final, x: finalLeft,
                                   y: finalYCenter, isFinal: true)
                            .id("final_anchor")
                        FWCStageLabel(title: LocalizedStringKey(FWCBracketRound.final.localizedKey))
                            .position(x: finalLeft + cardWidth / 2, y: 15)

                        // 3e Place
                        cardColumn(match: matches.thirdPlace, x: finalLeft,
                                   y: thirdPlaceYCenter)
                            .id("third_place_anchor")
                    }
                    .frame(width: 1380, height: 2200)
                    .padding(20)
                }
                .environment(\.layoutDirection, .leftToRight)
                .background(
                    LinearGradient(
                        colors: [Color("fifaBlue").opacity(0.05),
                                 Color("fifaGold").opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .onAppear { scheduleScroll(to: selectedRound, proxy: proxy) }
                .onChange(of: selectedRound) { _, round in
                    scheduleScroll(to: round, proxy: proxy)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func cardColumn(match: FWCBracketMatch, x: CGFloat, y: CGFloat,
                             isFinal: Bool = false) -> some View {
        VStack(spacing: 4) {
            VStack(spacing: 2) {
                if !match.date.isEmpty {
                    HStack(spacing: 4) {
                        Text(formatDate(match.date))
                            .font(.caption2).fontWeight(.medium)
                            .foregroundColor(Color("fifaBlue"))
                        Text(match.time)
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Text(match.venue)
                        .font(.caption2).foregroundColor(Color("fifaGold")).lineLimit(1)
                }
            }
            FWCMatchCardView(match: match, isFinal: isFinal)
                .frame(width: cardWidth, height: cardHeight)
        }
        .position(x: x + cardWidth / 2, y: 40 + y)
    }

    private func scheduleScroll(to round: FWCBracketRound, proxy: ScrollViewProxy) {
        let id = UUID()
        scrollRequestId = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard scrollRequestId == id else { return }
            withAnimation(.easeInOut(duration: 0.8)) {
                let anchor: UnitPoint = round == .final ? .center : .topLeading
                proxy.scrollTo(targetScrollID(for: round), anchor: anchor)
            }
        }
    }

    /// Returns the scroll ID of the first unplayed match in the round, falling back to the
    /// round's first match if all are already finished.
    private func targetScrollID(for round: FWCBracketRound) -> String {
        switch round {
        case .roundOf32:
            return activeID(in: matches.roundOf32, firstAnchor: "r32",           prefix: "r32_")
        case .roundOf16:
            return activeID(in: matches.roundOf16, firstAnchor: "r16",           prefix: "r16_")
        case .quarterFinals:
            return activeID(in: matches.quarterFinals, firstAnchor: "quarterfinals", prefix: "qf_")
        case .semiFinals:
            return activeID(in: matches.semiFinals, firstAnchor: "semifinals",    prefix: "sf_")
        case .final:
            return "final_anchor"
        }
    }

    /// First match with no score (upcoming). Falls back to the first match of the list.
    private func activeID(in list: [FWCBracketMatch], firstAnchor: String, prefix: String) -> String {
        guard let first = list.first else { return firstAnchor }
        guard let target = list.first(where: { $0.score1 == nil && !$0.date.isEmpty }) else {
            return firstAnchor
        }
        return target.id == first.id ? firstAnchor : "\(prefix)\(target.id)"
    }

    private func formatDate(_ dateString: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateString) else { return dateString }
        let d = DateFormatter()
        d.dateFormat = "MMM d"
        return d.string(from: date)
    }
}

// MARK: - Main View

public struct FWCBracketView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FWCBracketViewModel.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            if let matches = viewModel.bracketMatches {
                FWCBracketContentView(
                    matches: matches,
                    selectedRound: $viewModel.selectedRound
                )
            } else {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if !viewModel.hasInitializedSelectedRound {
                viewModel.selectedRound = viewModel.determineCurrentRound()
                viewModel.hasInitializedSelectedRound = true
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadBracketData()
            await viewModel.syncKnockoutFixturesForPastDates()
        }
    }
}

#Preview {
    FWCBracketView()
}
