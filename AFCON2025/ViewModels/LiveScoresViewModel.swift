import Foundation
import SwiftUI
import AFCONClient

@Observable
class LiveScoresViewModel {
    private let service = AFCONServiceWrapper.shared

    var liveMatches: [Game] = []
    var upcomingMatches: [Game] = []
    var finishedTodayMatches: [Game] = []
    var nextDayMatches: [Game] = []
    var isLoading = false
    var errorMessage: String?

    // Computed property: group upcoming matches by date
    var upcomingMatchesByDate: [(date: Date, matches: [Game])] {
        let calendar = Calendar.current

        // Filter out tomorrow's matches if we're showing them in the dedicated "Next Day" section
        let matchesToGroup: [Game]
        if shouldShowNextDay {
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            // Exclude tomorrow's matches since they're shown separately
            matchesToGroup = upcomingMatches.filter { game in
                !calendar.isDate(game.date, inSameDayAs: tomorrow)
            }
        } else {
            matchesToGroup = upcomingMatches
        }

        let grouped = Dictionary(grouping: matchesToGroup) { game in
            calendar.startOfDay(for: game.date)
        }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, matches: $0.value.sorted { $0.date < $1.date }) }
    }

    // Determine what to display when no live matches
    var shouldShowFinishedToday: Bool {
        liveMatches.isEmpty && !finishedTodayMatches.isEmpty
    }

    var shouldShowNextDay: Bool {
        liveMatches.isEmpty && finishedTodayMatches.isEmpty && !nextDayMatches.isEmpty
    }

    // MARK: - Fetch Live Matches
    @MainActor
    func fetchLiveMatches() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all fixtures (live, finished, and upcoming)
            let allFixtures = try await service.getFixtures()
            let allGames = allFixtures.toGames()

            let calendar = Calendar.current
            let now = Date()
            let today = calendar.startOfDay(for: now)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

            // Separate into categories
            liveMatches = allGames.filter { $0.status == .live }
            upcomingMatches = allGames.filter { $0.status == .upcoming && $0.date > now }

            // Finished games today
            finishedTodayMatches = allGames.filter { game in
                game.status == .finished && calendar.isDateInToday(game.date)
            }.sorted { $0.date > $1.date } // Most recent first

            // Next day's games (if no live and no finished today)
            nextDayMatches = allGames.filter { game in
                game.status == .upcoming &&
                game.date >= tomorrow &&
                calendar.isDate(game.date, inSameDayAs: tomorrow)
            }.sorted { $0.date < $1.date }

            print("✅ Fetched \(liveMatches.count) live, \(finishedTodayMatches.count) finished today, \(nextDayMatches.count) next day, \(upcomingMatches.count) upcoming")
        } catch {
            errorMessage = "Failed to load matches: \(error.localizedDescription)"
            print("Error fetching matches: \(error)")
        }

        isLoading = false
    }

    // MARK: - Start Live Updates Stream
    func startLiveUpdates() {
        Task {
            do {
                try await service.streamLiveMatches { [weak self] update in
                    Task { @MainActor in
                        // Handle live update
                        print("Live update for fixture \(update.fixtureID): \(update.eventType)")

                        let updatedGame = update.fixture.toGame()

                        // Check if it's in live matches
                        if let index = self?.liveMatches.firstIndex(where: { $0.id == Int(update.fixtureID) }) {
                            self?.liveMatches[index] = updatedGame
                        } else if updatedGame.status == .live {
                            // New live match started - remove from upcoming if present
                            self?.upcomingMatches.removeAll { $0.id == Int(update.fixtureID) }
                            self?.liveMatches.insert(updatedGame, at: 0)
                        } else if updatedGame.status == .upcoming {
                            // Update in upcoming list
                            if let index = self?.upcomingMatches.firstIndex(where: { $0.id == Int(update.fixtureID) }) {
                                self?.upcomingMatches[index] = updatedGame
                            }
                        } else if updatedGame.status == .finished {
                            // Match finished - remove from live
                            self?.liveMatches.removeAll { $0.id == Int(update.fixtureID) }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Live updates stream error: \(error.localizedDescription)"
                }
            }
        }
    }
}
