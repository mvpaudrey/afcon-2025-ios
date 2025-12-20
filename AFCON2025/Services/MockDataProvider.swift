//
//  Provides mock live match data for local server simulation
//

import Foundation
import AFCONClient

/// Generates mock live match data for testing
class MockDataProvider {
    static let shared = MockDataProvider()

    private init() {}

    // MARK: - Mock Matches

    /// Generate mock live matches for a given league
    func generateMockMatches(leagueID: Int32, season: Int32) -> [MockMatch] {
        switch leagueID {
        case 2: // Champions League
            return [
                MockMatch(
                    fixtureID: 1001,
                    homeTeam: "Real Madrid",
                    awayTeam: "Bayern Munich",
                    homeScore: 2,
                    awayScore: 1,
                    status: "2H",
                    elapsed: 67,
                    events: [
                        MockEvent(minute: 23, type: "Goal", team: "Real Madrid", player: "Vinícius Jr", detail: "Normal Goal"),
                        MockEvent(minute: 45, type: "Goal", team: "Bayern Munich", player: "Kane", detail: "Penalty"),
                        MockEvent(minute: 58, type: "Goal", team: "Real Madrid", player: "Bellingham", detail: "Normal Goal"),
                        MockEvent(minute: 62, type: "Card", team: "Bayern Munich", player: "Kimmich", detail: "Yellow Card")
                    ]
                ),
                MockMatch(
                    fixtureID: 1002,
                    homeTeam: "Manchester City",
                    awayTeam: "PSG",
                    homeScore: 1,
                    awayScore: 1,
                    status: "HT",
                    elapsed: 45,
                    events: [
                        MockEvent(minute: 12, type: "Goal", team: "PSG", player: "Mbappé", detail: "Normal Goal"),
                        MockEvent(minute: 38, type: "Goal", team: "Manchester City", player: "Haaland", detail: "Normal Goal")
                    ]
                )
            ]

        case 6: // AFCON
            return [
                MockMatch(
                    fixtureID: 2001,
                    homeTeam: "Morocco",
                    awayTeam: "Egypt",
                    homeScore: 0,
                    awayScore: 0,
                    status: "1H",
                    elapsed: 28,
                    events: [
                        MockEvent(minute: 15, type: "Card", team: "Egypt", player: "Salah", detail: "Yellow Card"),
                        MockEvent(minute: 22, type: "subst", team: "Morocco", playerOut: "Ziyech", playerIn: "Boufal", detail: "Substitution")
                    ]
                )
            ]

        default:
            return []
        }
    }

    /// Convert mock match to protobuf LiveMatchUpdate
    func createLiveMatchUpdate(from mock: MockMatch) -> Afcon_LiveMatchUpdate {
        var update = Afcon_LiveMatchUpdate()
        update.fixtureID = mock.fixtureID
        update.eventType = "time_update"

        // Status
        var status = Afcon_FixtureStatus()
        status.long = statusLongName(mock.status)
        status.short = mock.status
        status.elapsed = mock.elapsed
        update.status = status

        // Fixture info
        var fixture = Afcon_Fixture()
        fixture.id = mock.fixtureID

        var teams = Afcon_FixtureTeams()
        var homeTeam = Afcon_FixtureTeam()
        homeTeam.name = mock.homeTeam
        teams.home = homeTeam

        var awayTeam = Afcon_FixtureTeam()
        awayTeam.name = mock.awayTeam
        teams.away = awayTeam
        fixture.teams = teams

        var goals = Afcon_FixtureGoals()
        goals.home = mock.homeScore
        goals.away = mock.awayScore
        fixture.goals = goals

        update.fixture = fixture

        // Recent events
        update.recentEvents = mock.events.map { createFixtureEvent(from: $0) }

        return update
    }

    private func createFixtureEvent(from event: MockEvent) -> Afcon_FixtureEvent {
        var fixtureEvent = Afcon_FixtureEvent()

        var time = Afcon_EventTime()
        time.elapsed = event.minute
        time.extra = 0
        fixtureEvent.time = time

        fixtureEvent.type = event.type
        fixtureEvent.detail = event.detail

        var team = Afcon_EventTeam()
        team.name = event.team
        fixtureEvent.team = team

        if let playerOut = event.playerOut {
            var player = Afcon_EventPlayer()
            player.name = playerOut
            fixtureEvent.player = player

            if let playerIn = event.playerIn {
                var assist = Afcon_EventPlayer()
                assist.name = playerIn
                fixtureEvent.assist = assist
            }
        } else {
            var player = Afcon_EventPlayer()
            player.name = event.player ?? ""
            fixtureEvent.player = player
        }

        return fixtureEvent
    }

    private func statusLongName(_ short: String) -> String {
        switch short {
        case "1H": return "First Half"
        case "HT": return "Halftime"
        case "2H": return "Second Half"
        case "ET": return "Extra Time"
        case "P": return "Penalty Shootout"
        case "FT": return "Match Finished"
        default: return "Live"
        }
    }

    /// Simulate a goal event
    func createGoalEvent(fixtureID: Int32, team: String, player: String, minute: Int32) -> Afcon_LiveMatchUpdate {
        var update = Afcon_LiveMatchUpdate()
        update.fixtureID = fixtureID
        update.eventType = "goal"

        var event = Afcon_FixtureEvent()
        event.type = "Goal"
        event.detail = "Normal Goal"

        var time = Afcon_EventTime()
        time.elapsed = minute
        event.time = time

        var playerInfo = Afcon_EventPlayer()
        playerInfo.name = player
        event.player = playerInfo

        var teamInfo = Afcon_EventTeam()
        teamInfo.name = team
        event.team = teamInfo

        update.recentEvents = [event]

        return update
    }
}

// MARK: - Mock Data Structures

struct MockMatch {
    let fixtureID: Int32
    let homeTeam: String
    let awayTeam: String
    var homeScore: Int32
    var awayScore: Int32
    var status: String  // 1H, HT, 2H, ET, P, FT
    var elapsed: Int32
    var events: [MockEvent]
}

struct MockEvent {
    let minute: Int32
    let type: String  // Goal, Card, subst, var
    let team: String
    var player: String?
    var playerOut: String?  // For substitutions
    var playerIn: String?   // For substitutions
    let detail: String

    init(minute: Int32, type: String, team: String, player: String? = nil, playerOut: String? = nil, playerIn: String? = nil, detail: String) {
        self.minute = minute
        self.type = type
        self.team = team
        self.player = player
        self.playerOut = playerOut
        self.playerIn = playerIn
        self.detail = detail
    }
}
