import Foundation
import Observation
import SwiftData
import TournamentKit

@Observable
class FWCBracketViewModel {
    nonisolated(unsafe) static let shared = FWCBracketViewModel()

    var bracketMatches: FWCBracketMatches? = FWCBracketData.placeholderMatches
    var selectedRound: FWCBracketRound = .roundOf32
    var hasInitializedSelectedRound = false
    var isLoading = false
    var errorMessage: String?

    private var standings: [String: [TournamentKit.Team]] = [:]
    private var thirdPlaceTeams: [TournamentKit.Team] = []
    private var modelContext: ModelContext?
    private let service = TournamentServiceWrapper.shared

    init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @MainActor
    func loadBracketData() async {
        isLoading = true
        errorMessage = nil

        do {
            let parsed = try await service.getParsedStandings()
            standings = parsed.groups
            thirdPlaceTeams = parsed.thirdPlace

            var matches = FWCBracketMatches(
                roundOf32:     computeR32(),
                roundOf16:     FWCBracketData.allMatches.roundOf16,
                quarterFinals: FWCBracketData.allMatches.quarterFinals,
                semiFinals:    FWCBracketData.allMatches.semiFinals,
                final:         FWCBracketData.allMatches.final,
                thirdPlace:    FWCBracketData.allMatches.thirdPlace
            )

            if let ctx = modelContext {
                matches = applyFixtures(to: matches, modelContext: ctx)
            }

            bracketMatches = matches
        } catch {
            errorMessage = "Impossible de charger le bracket: \(error.localizedDescription)"
            print("❌ FWCBracketViewModel: \(error)")
        }

        isLoading = false
    }

    @MainActor
    func syncKnockoutFixturesForPastDates() async {
        guard let modelContext = modelContext else { return }
        let dataManager = FixtureDataManager(modelContext: modelContext)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let all = FWCBracketData.allMatches
        let allDates = Set(
            all.roundOf32.map(\.date)
            + all.roundOf16.map(\.date)
            + all.quarterFinals.map(\.date)
            + all.semiFinals.map(\.date)
            + [all.final.date, all.thirdPlace.date]
        ).filter { !$0.isEmpty }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 3600)

        for dateString in allDates.sorted() {
            guard let date = formatter.date(from: dateString), date <= today else { continue }
            await dataManager.syncFixturesForDate(date)
        }
    }

    @MainActor
    func refreshBracketFromFixtures() {
        guard let ctx = modelContext, let current = bracketMatches else { return }
        bracketMatches = applyFixtures(to: current, modelContext: ctx)
    }

    func determineCurrentRound(date: Date = Date()) -> FWCBracketRound {
        let cal = Calendar.current

        func d(_ year: Int, _ month: Int, _ day: Int) -> Date {
            cal.date(from: DateComponents(year: year, month: month, day: day))!
        }

        if date >= d(2026, 7, 19) { return .final }
        if date >= d(2026, 7, 14) { return .semiFinals }
        if date >= d(2026, 7,  9) { return .quarterFinals }
        if date >= d(2026, 7,  4) { return .roundOf16 }
        if date >= d(2026, 6, 28) { return .roundOf32 }
        return .roundOf32
    }

    // MARK: - R32 Bracket Resolution

    private func computeR32() -> [FWCBracketMatch] {
        let schedule = Dictionary(uniqueKeysWithValues: FWCBracketData.allMatches.roundOf32.map { ($0.id, $0) })

        func sched(_ id: Int) -> FWCBracketMatch {
            schedule[id] ?? FWCBracketData.placeholder(id: id)
        }

        func team(_ g: String, _ pos: Int) -> (name: String, id: Int?) {
            guard let teams = standings[g], pos >= 1, pos <= teams.count else {
                return (pos == 1 ? "1er \(g)" : "2e \(g)", nil)
            }
            let t = teams[pos - 1]
            return (t.name, t.teamId)
        }

        func third(_ groups: [String]) -> (name: String, id: Int?) {
            for t in thirdPlaceTeams {
                if let letter = groupLetterForTeam(t), groups.contains(letter) {
                    return (t.name, t.teamId)
                }
            }
            return ("3e " + groups.joined(separator: "/"), nil)
        }

        func match(_ id: Int, _ t1: (name: String, id: Int?), _ t2: (name: String, id: Int?)) -> FWCBracketMatch {
            let s = sched(id)
            return FWCBracketMatch(id: s.id, date: s.date, time: s.time,
                                   team1: t1.name, team2: t2.name,
                                   team1Id: t1.id, team2Id: t2.id,
                                   venue: s.venue, score1: nil, score2: nil)
        }

        // Ordered for canvas layout: adjacent pairs feed into the same R16 slot
        return [
            match(67, team("E", 1), third(["A","B","C","D","F"])),
            match(70, team("I", 1), third(["C","D","F","G","H"])),
            match(65, team("A", 2), team("B", 2)),
            match(68, team("F", 1), team("C", 2)),
            match(76, team("K", 2), team("L", 2)),
            match(75, team("H", 1), team("J", 2)),
            match(74, team("D", 1), third(["B","E","F","I","J"])),
            match(73, team("G", 1), third(["A","E","H","I","J"])),
            match(66, team("C", 1), team("F", 2)),
            match(69, team("E", 2), team("I", 2)),
            match(71, team("A", 1), third(["C","E","F","H","I"])),
            match(72, team("L", 1), third(["E","H","I","J","K"])),
            match(79, team("J", 1), team("H", 2)),
            match(78, team("D", 2), team("G", 2)),
            match(77, team("B", 1), third(["E","F","G","I","J"])),
            match(80, team("K", 1), third(["D","E","I","J","L"])),
        ]
    }

    private func groupLetterForTeam(_ team: TournamentKit.Team) -> String? {
        if let groupName = team.groupName {
            let pattern = "(?:group|groupe)\\s*([A-Z])"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(groupName.startIndex..<groupName.endIndex, in: groupName)
                if let m = regex.firstMatch(in: groupName, options: [], range: range),
                   m.numberOfRanges > 1,
                   let lr = Range(m.range(at: 1), in: groupName) {
                    return String(groupName[lr]).uppercased()
                }
            }
        }
        for (letter, teams) in standings where teams.contains(where: { $0.teamId == team.teamId }) {
            return letter
        }
        return nil
    }

    // MARK: - Fixture Application

    private func applyFixtures(to matches: FWCBracketMatches, modelContext: ModelContext) -> FWCBracketMatches {
        let descriptor = FetchDescriptor<FixtureModel>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        let knockout = all.filter { f in
            let cal = Calendar.current
            let month = cal.component(.month, from: f.date)
            let year  = cal.component(.year,  from: f.date)
            guard year == 2026 else { return false }
            if month == 7 { return true }
            if month == 6 { return cal.component(.day, from: f.date) >= 28 }
            return false
        }

        return FWCBracketMatches(
            roundOf32:     knockout.isEmpty ? matches.roundOf32     : applyFixtures(knockout, to: matches.roundOf32),
            roundOf16:     knockout.isEmpty ? matches.roundOf16     : applyFixtures(knockout, to: matches.roundOf16),
            quarterFinals: knockout.isEmpty ? matches.quarterFinals : applyFixtures(knockout, to: matches.quarterFinals),
            semiFinals:    knockout.isEmpty ? matches.semiFinals    : applyFixtures(knockout, to: matches.semiFinals),
            final:         knockout.isEmpty ? matches.final         : applyFixture(knockout, to: matches.final),
            thirdPlace:    knockout.isEmpty ? matches.thirdPlace    : applyFixture(knockout, to: matches.thirdPlace)
        )
    }

    private func applyFixtures(_ fixtures: [FixtureModel], to matches: [FWCBracketMatch]) -> [FWCBracketMatch] {
        matches.map { applyFixture(fixtures, to: $0) }
    }

    private func applyFixture(_ fixtures: [FixtureModel], to match: FWCBracketMatch) -> FWCBracketMatch {
        guard let fixture = findFixture(for: match, in: fixtures) else { return match }
        return matchFromFixture(fixture, fallback: match)
    }

    private func findFixture(for match: FWCBracketMatch, in fixtures: [FixtureModel]) -> FixtureModel? {
        // Prefer team-ID match when both teams are resolved (most reliable)
        if let t1 = match.team1Id, let t2 = match.team2Id {
            if let byTeams = fixtures.first(where: {
                ($0.homeTeamId == t1 && $0.awayTeamId == t2) ||
                ($0.homeTeamId == t2 && $0.awayTeamId == t1)
            }) { return byTeams }
        }
        // Fallback: time-based match within 90 minutes
        guard let scheduled = scheduledDateTime(for: match) else { return nil }
        return fixtures
            .filter { abs($0.date.timeIntervalSince(scheduled)) <= 90 * 60 }
            .min(by: { abs($0.date.timeIntervalSince(scheduled)) < abs($1.date.timeIntervalSince(scheduled)) })
    }

    private func matchFromFixture(_ fixture: FixtureModel, fallback: FWCBracketMatch) -> FWCBracketMatch {
        let score1: Int? = fixture.isUpcoming ? nil : fixture.homeGoals
        let score2: Int? = fixture.isUpcoming ? nil : fixture.awayGoals
        return FWCBracketMatch(
            id: fallback.id,
            date: formatDate(fixture.date),
            time: formatTime(fixture.date),
            team1: fixture.homeTeamName,
            team2: fixture.awayTeamName,
            team1Id: fixture.homeTeamId,
            team2Id: fixture.awayTeamId,
            venue: fixture.fullVenue,
            score1: score1,
            score2: score2,
            penalty1: fixture.penaltyHome > 0 ? fixture.penaltyHome : nil,
            penalty2: fixture.penaltyAway > 0 ? fixture.penaltyAway : nil
        )
    }

    private func scheduledDateTime(for match: FWCBracketMatch) -> Date? {
        let dp = match.date.split(separator: "-").compactMap { Int($0) }
        let tp = match.time.split(separator: ":").compactMap { Int($0) }
        guard dp.count == 3, tp.count == 2 else { return nil }
        var c = DateComponents()
        c.year = dp[0]; c.month = dp[1]; c.day = dp[2]
        c.hour = tp[0]; c.minute = tp[1]
        c.timeZone = TimeZone(secondsFromGMT: 3600)
        return Calendar(identifier: .gregorian).date(from: c)
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 3600)
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(secondsFromGMT: 3600)
        return f
    }()

    private func formatDate(_ date: Date) -> String { Self.dateFmt.string(from: date) }
    private func formatTime(_ date: Date) -> String { Self.timeFmt.string(from: date) }
}
