import Foundation
import SwiftUI
import SwiftData
import AFCONClient

@Observable
class BracketViewModel {
    var isLoading = false
    var errorMessage: String?
    var bracketMatches: BracketMatches?

    private let service = AFCONServiceWrapper.shared
    private var standings: [String: [Team]] = [:]
    private var thirdPlaceTeams: [Team] = []
    private var teamIdToGroup: [Int: String] = [:]
    private var modelContext: ModelContext?
    // CAF third-place scenario table keyed by qualified group set.
    // Values follow CAF order: R3 (1A opponent), R5 (1B), R6 (1C), R1 (1D).
    private let thirdPlaceScenarioTable: [String: [String]] = [
        "ABCD": ["C", "D", "A", "B"],
        "ABCE": ["C", "A", "B", "E"],
        "ABCF": ["C", "A", "B", "F"],
        "ABDE": ["D", "A", "B", "E"],
        "ABDF": ["D", "A", "B", "F"],
        "ABEF": ["E", "A", "B", "F"],
        "ACDE": ["C", "D", "A", "E"],
        "ACDF": ["C", "D", "A", "F"],
        "ACEF": ["C", "A", "F", "E"],
        "ADEF": ["D", "A", "F", "E"],
        "BCDE": ["C", "D", "B", "E"],
        "BCDF": ["C", "D", "B", "F"],
        "BCEF": ["E", "C", "B", "F"],
        "BDEF": ["E", "D", "B", "F"],
        "CDEF": ["C", "D", "F", "E"]
    ]

    @MainActor
    func loadBracketData() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await service.getStandings(leagueId: 6, season: 2025)

            var groupStandings: [String: [Team]] = [:]

            for standingGroup in response.groups {
                let teams = standingGroup.standings.map { standing in
                    Team(
                        name: standing.team.name,
                        teamId: Int(standing.team.id),
                        played: Int(standing.all.played),
                        won: Int(standing.all.win),
                        drawn: Int(standing.all.draw),
                        lost: Int(standing.all.lose),
                        gf: Int(standing.all.goals.for),
                        ga: Int(standing.all.goals.against),
                        points: Int(standing.points),
                        position: Int(standing.rank),
                        groupName: standing.group
                    )
                }

                // Check if this is the third-place ranking
                if standingGroup.groupName.lowercased().contains("third") ||
                   standingGroup.groupName.lowercased().contains("troisième") ||
                   standingGroup.groupName.lowercased().contains("3rd") {
                    thirdPlaceTeams = teams
                } else {
                    // Extract group letter from name (e.g., "Group A" -> "A")
                    if let groupLetter = extractGroupLetter(from: standingGroup.groupName) {
                        groupStandings[groupLetter] = teams
                    }
                }
            }

            standings = groupStandings
            teamIdToGroup = groupStandings.reduce(into: [:]) { result, entry in
                let (groupLetter, teams) = entry
                for team in teams {
                    result[team.teamId] = groupLetter
                }
            }

            // Generate bracket matches after loading standings
            var matches = BracketMatches(
                roundOf16: getRoundOf16Matches(),
                quarterFinals: BracketData.allMatches.quarterFinals,
                semiFinals: BracketData.allMatches.semiFinals,
                final: BracketData.allMatches.final,
                thirdPlace: BracketData.allMatches.thirdPlace
            )

            if let modelContext = modelContext {
                matches = applyFixtures(to: matches, modelContext: modelContext)
            }

            bracketMatches = matches
        } catch {
            errorMessage = "Failed to load bracket data: \(error.localizedDescription)"
            print("❌ Error loading bracket data: \(error)")
        }

        isLoading = false
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @MainActor
    func syncKnockoutFixturesForPastDates() async {
        guard let modelContext = modelContext else { return }

        let dataManager = FixtureDataManager(modelContext: modelContext)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let bracketDates = Set(
            BracketData.allMatches.roundOf16.map(\.date)
                + BracketData.allMatches.quarterFinals.map(\.date)
                + BracketData.allMatches.semiFinals.map(\.date)
                + [BracketData.allMatches.thirdPlace.date, BracketData.allMatches.final.date]
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 3600)

        for dateString in bracketDates.sorted() {
            guard let date = formatter.date(from: dateString) else { continue }
            if date <= today {
                await dataManager.syncFixturesForDate(date)
            }
        }
    }

    @MainActor
    func refreshBracketFromFixtures() {
        guard let modelContext = modelContext,
              let currentMatches = bracketMatches else {
            return
        }
        bracketMatches = applyFixtures(to: currentMatches, modelContext: modelContext)
    }

    /// Get team by position in group (1 = winner, 2 = runner-up, 3 = third)
    func getTeam(group: String, position: Int) -> String {
        guard let groupTeams = standings[group], position >= 1, position <= groupTeams.count else {
            return fallbackTeamLabel(group: group, position: position)
        }
        return groupTeams[position - 1].name
    }

    /// Get third-placed team by their rank in the overall third-place ranking
    func getThirdByRank(_ rank: Int) -> String {
        guard rank >= 1, rank <= thirdPlaceTeams.count else {
            return "TBD"
        }
        return thirdPlaceTeams[rank - 1].name
    }

    /// Determine Round of 16 matchups based on actual standings
    func getRoundOf16Matches() -> [BracketMatch] {
        let scheduleById = Dictionary(uniqueKeysWithValues: BracketData.allMatches.roundOf16.map { ($0.id, $0) })
        let qualifiedGroups = Set(qualifiedThirdPlaceGroups())
        let thirdPlaceAssignments = resolveThirdPlaceAssignments(qualifiedGroups: qualifiedGroups)

        func schedule(_ id: Int) -> BracketMatch {
            scheduleById[id] ?? BracketMatch(
                id: id,
                date: "",
                time: "",
                team1: "",
                team2: "",
                team1Id: nil,
                team2Id: nil,
                venue: "",
                score1: nil,
                score2: nil
            )
        }

        let teamD1 = teamInfo(group: "D", position: 1)
        let teamA2 = teamInfo(group: "A", position: 2)
        let teamC2 = teamInfo(group: "C", position: 2)
        let teamA1 = teamInfo(group: "A", position: 1)
        let teamB2 = teamInfo(group: "B", position: 2)
        let teamF2 = teamInfo(group: "F", position: 2)
        let teamB1 = teamInfo(group: "B", position: 1)
        let teamC1 = teamInfo(group: "C", position: 1)
        let teamE1 = teamInfo(group: "E", position: 1)
        let teamD2 = teamInfo(group: "D", position: 2)
        let teamF1 = teamInfo(group: "F", position: 1)
        let teamE2 = teamInfo(group: "E", position: 2)

        let r1Third = thirdPlaceTeam(forGroup: thirdPlaceAssignments["D"])
        let r3Third = thirdPlaceTeam(forGroup: thirdPlaceAssignments["A"])
        let r5Third = thirdPlaceTeam(forGroup: thirdPlaceAssignments["B"])
        let r6Third = thirdPlaceTeam(forGroup: thirdPlaceAssignments["C"])

        let r1 = BracketMatch(
            id: schedule(37).id,
            date: schedule(37).date,
            time: schedule(37).time,
            team1: teamD1.name,
            team2: r1Third?.name ?? "3B/E/F",
            team1Id: teamD1.id,
            team2Id: r1Third?.teamId,
            venue: schedule(37).venue,
            score1: nil,
            score2: nil
        )

        let r2 = BracketMatch(
            id: schedule(38).id,
            date: schedule(38).date,
            time: schedule(38).time,
            team1: teamA2.name,
            team2: teamC2.name,
            team1Id: teamA2.id,
            team2Id: teamC2.id,
            venue: schedule(38).venue,
            score1: nil,
            score2: nil
        )

        let r3 = BracketMatch(
            id: schedule(39).id,
            date: schedule(39).date,
            time: schedule(39).time,
            team1: teamA1.name,
            team2: r3Third?.name ?? "3C/D/E",
            team1Id: teamA1.id,
            team2Id: r3Third?.teamId,
            venue: schedule(39).venue,
            score1: nil,
            score2: nil
        )

        let r4 = BracketMatch(
            id: schedule(40).id,
            date: schedule(40).date,
            time: schedule(40).time,
            team1: teamB2.name,
            team2: teamF2.name,
            team1Id: teamB2.id,
            team2Id: teamF2.id,
            venue: schedule(40).venue,
            score1: nil,
            score2: nil
        )

        let r5 = BracketMatch(
            id: schedule(41).id,
            date: schedule(41).date,
            time: schedule(41).time,
            team1: teamB1.name,
            team2: r5Third?.name ?? "3A/C/D",
            team1Id: teamB1.id,
            team2Id: r5Third?.teamId,
            venue: schedule(41).venue,
            score1: nil,
            score2: nil
        )

        let r6 = BracketMatch(
            id: schedule(42).id,
            date: schedule(42).date,
            time: schedule(42).time,
            team1: teamC1.name,
            team2: r6Third?.name ?? "3A/B/F",
            team1Id: teamC1.id,
            team2Id: r6Third?.teamId,
            venue: schedule(42).venue,
            score1: nil,
            score2: nil
        )

        let r7 = BracketMatch(
            id: schedule(43).id,
            date: schedule(43).date,
            time: schedule(43).time,
            team1: teamE1.name,
            team2: teamD2.name,
            team1Id: teamE1.id,
            team2Id: teamD2.id,
            venue: schedule(43).venue,
            score1: nil,
            score2: nil
        )

        let r8 = BracketMatch(
            id: schedule(44).id,
            date: schedule(44).date,
            time: schedule(44).time,
            team1: teamF1.name,
            team2: teamE2.name,
            team1Id: teamF1.id,
            team2Id: teamE2.id,
            venue: schedule(44).venue,
            score1: nil,
            score2: nil
        )

        // Order matches to match CAF bracket layout (QF3: R7 vs R6, QF4: R5 vs R8).
        return [r1, r2, r3, r4, r6, r7, r5, r8]
    }

    private func fallbackTeamLabel(group: String, position: Int) -> String {
        switch position {
        case 1:
            return "1\(group)"
        case 2:
            return "2\(group)"
        case 3:
            return "3\(group)"
        default:
            return "TBD"
        }
    }

    private func teamInfo(group: String, position: Int) -> (name: String, id: Int?) {
        guard let groupTeams = standings[group], position >= 1, position <= groupTeams.count else {
            return (fallbackTeamLabel(group: group, position: position), nil)
        }
        let team = groupTeams[position - 1]
        return (team.name, team.teamId)
    }

    private func qualifiedThirdPlaceGroups() -> [String] {
        let topFour = thirdPlaceTeams.prefix(4)
        return topFour.compactMap { team in
            return groupLetter(forThirdPlaceTeam: team)
        }
    }

    private func thirdPlaceTeam(forGroup targetGroupLetter: String?) -> Team? {
        guard let targetGroupLetter else { return nil }
        for team in thirdPlaceTeams {
            guard let letter = groupLetter(forThirdPlaceTeam: team) else { continue }
            if letter == targetGroupLetter {
                return team
            }
        }
        return nil
    }

    private func resolveThirdPlaceAssignments(qualifiedGroups: Set<String>) -> [String: String] {
        let key = qualifiedGroups.sorted().joined()
        guard let scenario = thirdPlaceScenarioTable[key] else {
            return [:]
        }

        // CAF order: R3 (1A), R5 (1B), R6 (1C), R1 (1D)
        return [
            "A": scenario[0],
            "B": scenario[1],
            "C": scenario[2],
            "D": scenario[3]
        ]
    }

    private func groupLetter(forThirdPlaceTeam team: Team) -> String? {
        if let groupName = team.groupName,
           let letter = extractGroupLetter(from: groupName) {
            return letter
        }

        if let letter = teamIdToGroup[team.teamId] {
            return letter
        }

        return nil
    }

    private func extractGroupLetter(from name: String) -> String? {
        let pattern = "(?:group|groupe)\\s*([A-F])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        guard let match = regex.firstMatch(in: name, options: [], range: range),
              match.numberOfRanges > 1,
              let letterRange = Range(match.range(at: 1), in: name) else {
            return nil
        }

        return String(name[letterRange]).uppercased()
    }

    private func applyFixtures(to matches: BracketMatches, modelContext: ModelContext) -> BracketMatches {
        let descriptor = FetchDescriptor<FixtureModel>()
        let fixtures = (try? modelContext.fetch(descriptor)) ?? []
        let knockoutFixtures = fixtures.filter { fixture in
            let day = Calendar.current.component(.month, from: fixture.date)
            return day == 1
        }

        return BracketMatches(
            roundOf16: applyFixtures(knockoutFixtures, to: matches.roundOf16),
            quarterFinals: applyFixtures(knockoutFixtures, to: matches.quarterFinals),
            semiFinals: applyFixtures(knockoutFixtures, to: matches.semiFinals),
            final: applyFixture(knockoutFixtures, to: matches.final),
            thirdPlace: applyFixture(knockoutFixtures, to: matches.thirdPlace)
        )
    }

    private func applyFixtures(_ fixtures: [FixtureModel], to matches: [BracketMatch]) -> [BracketMatch] {
        matches.map { match in
            guard let fixture = matchFixture(for: match, fixtures: fixtures) else {
                return match
            }
            return matchFromFixture(fixture, fallback: match)
        }
    }

    private func applyFixture(_ fixtures: [FixtureModel], to match: BracketMatch) -> BracketMatch {
        guard let fixture = matchFixture(for: match, fixtures: fixtures) else {
            return match
        }
        return matchFromFixture(fixture, fallback: match)
    }

    private func matchFixture(for match: BracketMatch, fixtures: [FixtureModel]) -> FixtureModel? {
        guard let scheduled = scheduledDateTime(for: match) else {
            return nil
        }

        let candidates = fixtures
            .map { (fixture: $0, timeDiff: abs($0.date.timeIntervalSince(scheduled))) }
            .filter { $0.timeDiff <= 90 * 60 }
            .sorted { $0.timeDiff < $1.timeDiff }

        guard !candidates.isEmpty else { return nil }

        let matchVenue = match.venue.lowercased()
        if !matchVenue.isEmpty {
            if let venueMatch = candidates.first(where: { candidate in
                let fixtureVenue = candidate.fixture.venueName.lowercased()
                guard !fixtureVenue.isEmpty else { return true }
                return matchVenue.contains(fixtureVenue) || fixtureVenue.contains(matchVenue)
            }) {
                return venueMatch.fixture
            }
        }

        return candidates.first?.fixture
    }

    private func matchFromFixture(_ fixture: FixtureModel, fallback: BracketMatch) -> BracketMatch {
        // For finished games, use fulltime scores; for live games, use current scores
        let score1: Int?
        let score2: Int?

        if fixture.isUpcoming {
            score1 = nil
            score2 = nil
        } else {
            // Use current goals for both live and finished games
            score1 = fixture.homeGoals
            score2 = fixture.awayGoals
        }

        return BracketMatch(
            id: fallback.id,
            date: formatFixtureDate(fixture.date),
            time: formatFixtureTime(fixture.date),
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

    private func scheduledDateTime(for match: BracketMatch) -> Date? {
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
        components.timeZone = TimeZone(secondsFromGMT: 3600)

        return Calendar(identifier: .gregorian).date(from: components)
    }

    private func formatFixtureDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 3600)
        return formatter.string(from: date)
    }

    private func formatFixtureTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 3600)
        return formatter.string(from: date)
    }
}
