import Foundation
import SwiftUI
import SwiftData
import AFCONClient

@Observable
class GroupsViewModel {
    var groups: [Group] = []
    var thirdPlaceRanking: Group?
    var isLoading = false
    var errorMessage: String?

    private var modelContext: ModelContext?
    private let service = AFCONServiceWrapper.shared

    // Group compositions for AFCON 2025
    private let groupCompositions: [String: [Int]] = [
        "A": [31, 1500, 1507, 1524],        // Morocco, Mali, Zambia, Comoros
        "B": [32, 1531, 1529, 1522],        // Egypt, South Africa, Angola, Zimbabwe
        "C": [19, 28, 1519, 1489],          // Nigeria, Tunisia, Uganda, Tanzania
        "D": [13, 1508, 1516, 1520],        // Senegal, DR Congo, Benin, Botswana
        "E": [1532, 1502, 1521, 1510],      // Algeria, Burkina Faso, Equatorial Guinea, Sudan
        "F": [1501, 1530, 1503, 1512]       // Ivory Coast, Cameroon, Gabon, Mozambique
    ]

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @MainActor
    func loadStandings() async {
        guard let modelContext = modelContext else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Try to fetch from API first for official standings including third-place ranking
            do {
                let apiResponse = try await service.getStandings(leagueId: 6, season: 2025)

                var calculatedGroups: [Group] = []

                for standingGroup in apiResponse.groups {
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

                    let group = Group(name: standingGroup.groupName, teams: teams)

                    // Check if this is the third-place ranking
                    if standingGroup.groupName.lowercased().contains("third") ||
                       standingGroup.groupName.lowercased().contains("troisième") ||
                       standingGroup.groupName.lowercased().contains("3rd") {
                        thirdPlaceRanking = group
                    } else {
                        calculatedGroups.append(group)
                    }
                }

                groups = sortGroups(calculatedGroups)
            } catch {
                print("⚠️ API fetch failed, falling back to local calculation: \(error)")

                // Fallback to local calculation
                let descriptor = FetchDescriptor<FixtureModel>()
                let allFixtures = try modelContext.fetch(descriptor)

                // Calculate standings for each group
                var calculatedGroups: [Group] = []

                for (groupName, teamIds) in groupCompositions.sorted(by: { $0.key < $1.key }) {
                // Filter fixtures for this group (both teams must be in the group)
                // Also check round if available to exclude knockout stage rematches
                let groupFixtures = allFixtures.filter { fixture in
                    let teamsInGroup = teamIds.contains(fixture.homeTeamId) && teamIds.contains(fixture.awayTeamId)

                    // If round is available, ensure it's a group stage match
                    if let round = fixture.round, !round.isEmpty {
                        // Group stage rounds typically contain "Group" or are like "1st Round", "Group Stage", etc.
                        let isGroupStage = round.lowercased().contains("group") ||
                                          round.lowercased().contains("1st round")
                        return teamsInGroup && isGroupStage
                    }

                    // If no round info, fall back to team-based filtering
                    return teamsInGroup
                }

                let teams = calculateGroupStandings(teamIds: teamIds, fixtures: groupFixtures)

                    let group = Group(
                        name: "Group \(groupName) - AFCON 2025",
                        teams: teams.map { team in
                            Team(
                                name: team.name,
                                teamId: team.teamId,
                                played: team.played,
                                won: team.won,
                                drawn: team.drawn,
                                lost: team.lost,
                                gf: team.gf,
                                ga: team.ga,
                                points: team.points,
                                position: team.position,
                                groupName: "Group \(groupName)"
                            )
                        }
                    )
                    calculatedGroups.append(group)
                }

                groups = sortGroups(calculatedGroups)
            }
        } catch {
            errorMessage = "Failed to load standings: \(error.localizedDescription)"
            print("❌ Error loading standings: \(error)")
        }

        isLoading = false
    }

    /// Get the best third-placed teams from the ranking
    func getBestThirds(count: Int = 4) -> [Team] {
        guard let ranking = thirdPlaceRanking else { return [] }
        return Array(ranking.teams.prefix(count))
    }

    /// Get third-placed team by their rank (1-indexed)
    func getThirdByRank(_ rank: Int) -> Team? {
        guard let ranking = thirdPlaceRanking, rank >= 1, rank <= ranking.teams.count else { return nil }
        return ranking.teams[rank - 1]
    }

    private func calculateGroupStandings(teamIds: [Int], fixtures: [FixtureModel]) -> [Team] {
        var teamStats: [Int: TeamStats] = [:]

        // Initialize all teams
        for teamId in teamIds {
            teamStats[teamId] = TeamStats(teamId: teamId, teamName: "")
        }

        // First pass: Extract team names from ALL fixtures (including upcoming)
        for fixture in fixtures {
            let homeId = fixture.homeTeamId
            let awayId = fixture.awayTeamId

            // Update team names from any fixture (finished or upcoming)
            if teamStats[homeId]?.teamName.isEmpty ?? true {
                teamStats[homeId]?.teamName = fixture.homeTeamName
            }
            if teamStats[awayId]?.teamName.isEmpty ?? true {
                teamStats[awayId]?.teamName = fixture.awayTeamName
            }
        }

        // Second pass: Process all finished fixtures for stats
        for fixture in fixtures where fixture.statusShort == "FT" || fixture.statusShort == "AET" || fixture.statusShort == "PEN" {
            let homeId = fixture.homeTeamId
            let awayId = fixture.awayTeamId
            let homeGoals = fixture.homeGoals
            let awayGoals = fixture.awayGoals

            // Update stats
            teamStats[homeId]?.played += 1
            teamStats[awayId]?.played += 1

            teamStats[homeId]?.gf += homeGoals
            teamStats[homeId]?.ga += awayGoals
            teamStats[awayId]?.gf += awayGoals
            teamStats[awayId]?.ga += homeGoals

            if homeGoals > awayGoals {
                // Home win
                teamStats[homeId]?.won += 1
                teamStats[homeId]?.points += 3
                teamStats[awayId]?.lost += 1
            } else if homeGoals < awayGoals {
                // Away win
                teamStats[awayId]?.won += 1
                teamStats[awayId]?.points += 3
                teamStats[homeId]?.lost += 1
            } else {
                // Draw
                teamStats[homeId]?.drawn += 1
                teamStats[homeId]?.points += 1
                teamStats[awayId]?.drawn += 1
                teamStats[awayId]?.points += 1
            }
        }

        // Sort teams by points, then GD, then GF
        let sortedStats = teamStats.values.sorted { team1, team2 in
            if team1.points != team2.points {
                return team1.points > team2.points
            }
            let gd1 = team1.gf - team1.ga
            let gd2 = team2.gf - team2.ga
            if gd1 != gd2 {
                return gd1 > gd2
            }
            return team1.gf > team2.gf
        }

        // Convert to Team objects with positions
        return sortedStats.enumerated().map { index, stats in
            Team(
                name: stats.teamName.isEmpty ? "Team \(stats.teamId)" : stats.teamName,
                teamId: stats.teamId,
                played: stats.played,
                won: stats.won,
                drawn: stats.drawn,
                lost: stats.lost,
                gf: stats.gf,
                ga: stats.ga,
                points: stats.points,
                position: index + 1,
                groupName: nil
            )
        }
    }

    private func sortGroups(_ groups: [Group]) -> [Group] {
        let order = ["A", "B", "C", "D", "E", "F"]
        return groups.sorted { left, right in
            let leftKey = groupSortKey(for: left.name, order: order)
            let rightKey = groupSortKey(for: right.name, order: order)
            if leftKey != rightKey {
                return leftKey < rightKey
            }
            return left.name < right.name
        }
    }

    private func groupSortKey(for name: String, order: [String]) -> Int {
        let lowercased = name.lowercased()
        if lowercased.contains("third") || lowercased.contains("troisième") || lowercased.contains("3rd") {
            return 999
        }

        if let letter = extractGroupLetter(from: name),
           let index = order.firstIndex(of: letter) {
            return index
        }

        return 998
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
}

// Helper struct for calculations
private struct TeamStats {
    let teamId: Int
    var teamName: String
    var played: Int = 0
    var won: Int = 0
    var drawn: Int = 0
    var lost: Int = 0
    var gf: Int = 0
    var ga: Int = 0
    var points: Int = 0
}

// MARK: - Data Models
struct Group {
    let name: String
    let teams: [Team]
}

struct Team {
    let name: String
    let teamId: Int
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let gf: Int
    let ga: Int
    let points: Int
    let position: Int
    let groupName: String?
}
