import Foundation
import SwiftUI
import SwiftData
import AFCONClient
import WidgetKit
import ActivityKit

@Observable
@MainActor
class LiveScoresViewModel {
    private let service = AFCONServiceWrapper.shared
    private var dataManager: FixtureDataManager?
    private let modelContext: ModelContext?

    var liveMatches: [Game] = []
    var upcomingMatches: [Game] = []
    var finishedMatches: [Game] = []
    var fixtureEvents: [Int: [Afcon_FixtureEvent]] = [:]
    var isLoading = false
    var errorMessage: String?

    // Use global stream service
    private let streamService = LiveMatchStreamService.shared

    // Track if streaming is active
    var isStreaming: Bool {
        streamService.isStreaming
    }

    // Countdown timer for next update
    var secondsUntilNextUpdate: Int = 0
    private var updateTimer: Timer?

    // Favorite team IDs loaded from SwiftData
    private var favoriteTeamIds: Set<Int> = []

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if let context = modelContext {
            self.dataManager = FixtureDataManager(modelContext: context)
            loadFavoriteTeams()
        }

        // Setup stream callback to receive updates
        setupStreamCallback()
    }

    // MARK: - Setup Stream Callback
    private func setupStreamCallback() {
        streamService.onMatchUpdate = { [weak self] update in
            Task { @MainActor in
                await self?.handleLiveUpdate(update)
            }
        }

        // Setup callback to check for live matches
        streamService.onMatchStatusCheck = { [weak self] in
            guard let self = self, let dataManager = self.dataManager else {
                return false
            }

            do {
                // Check SwiftData for live matches
                let allFixtures = try dataManager.getAllFixtures()
                let liveCount = allFixtures.filter { $0.statusShort == "LIVE" || $0.statusShort == "1H" || $0.statusShort == "2H" || $0.statusShort == "HT" || $0.statusShort == "ET" || $0.statusShort == "P" }.count

                print("🔔 Checking for live matches: \(liveCount) found")
                return liveCount > 0
            } catch {
                print("❌ Failed to check for live matches: \(error)")
                return false
            }
        }
    }

    // MARK: - Update Timer
    @MainActor
    func startUpdateTimer() {
        stopUpdateTimer()

        // Start countdown from 15 seconds
        secondsUntilNextUpdate = 15

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                if self.secondsUntilNextUpdate > 0 {
                    self.secondsUntilNextUpdate -= 1
                } else {
                    // Timer reached 0 - refresh data
                    await self.fetchLiveMatches()
                }
            }
        }
    }

    @MainActor
    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    deinit {
        // Avoid capturing self in a Task; deinit runs on a specific thread and we only need to invalidate the timer.
        MainActor.assumeIsolated { stopUpdateTimer() }
    }

    // MARK: - Load Favorite Teams
    private func loadFavoriteTeams() {
        guard let modelContext = modelContext else { return }

        do {
            let descriptor = FetchDescriptor<FavoriteTeam>()
            let favorites = try modelContext.fetch(descriptor)
            favoriteTeamIds = Set(favorites.map { $0.teamId })
            print("✅ Loaded \(favoriteTeamIds.count) favorite teams: \(favoriteTeamIds)")
        } catch {
            print("❌ Failed to load favorite teams: \(error)")
        }
    }

    // Check if a game involves a favorite team
    func isFavoriteTeamMatch(_ game: Game) -> Bool {
        favoriteTeamIds.contains(game.homeTeamId) || favoriteTeamIds.contains(game.awayTeamId)
    }

    // Computed property: today's upcoming matches (not yet started)
    var upcomingTodayMatches: [Game] {
        let calendar = Calendar.current
        return upcomingMatches.filter { game in
            calendar.isDateInToday(game.date)
        }.sorted { $0.date < $1.date }
    }

    // Determine if we should show today's upcoming matches
    var shouldShowUpcomingToday: Bool {
        !upcomingTodayMatches.isEmpty
    }

    // Check if we have any games today (live, finished, or upcoming)
    var hasGamesToday: Bool {
        !liveMatches.isEmpty || !finishedMatches.isEmpty || !upcomingTodayMatches.isEmpty
    }

    // MARK: - Fetch Live Matches
    @MainActor
    func fetchLiveMatches() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let dataManager = dataManager else {
                throw NSError(domain: "LiveScoresViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No SwiftData context available"])
            }

            // Fetch fixtures from SwiftData
            // Note: AFCONHomeView handles initial fixture loading, so we just read from SwiftData here
            var allFixtures = try dataManager.getAllFixtures()
            let now = Date()

            let allGamesSnapshot = allFixtures.map { $0.toGame() }
            let hasLiveSnapshot = allGamesSnapshot.contains { $0.status == .live }
            let nextUpcoming = allGamesSnapshot
                .filter { $0.status == .upcoming && $0.date > now }
                .sorted { $0.date < $1.date }
                .first

            if !hasLiveSnapshot,
               let nextUpcoming,
               nextUpcoming.date.timeIntervalSince(now) > 120 {
                streamService.updateLiveMatchesStatus(hasLiveMatches: false)
                stopUpdateTimer()
                secondsUntilNextUpdate = 0
                isLoading = false
                return
            }

            // If there are fixtures, sync live fixtures to get latest updates
            if !allFixtures.isEmpty {
                await dataManager.syncLiveFixtures()
                // Refresh fixtures after live sync
                allFixtures = try dataManager.getAllFixtures()
            }

            let allGames = allFixtures.map { $0.toGame() }
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)

            // Separate into categories
            // Live matches sorted by kickoff time (earliest first)
            liveMatches = allGames.filter { $0.status == .live }
                .sorted { $0.date < $1.date }

            upcomingMatches = allGames.filter { $0.status == .upcoming && $0.date > now }

            // Filter finished matches from today only, sorted by most recent first
            finishedMatches = allGames.filter { game in
                guard game.status == .finished else { return false }
                let gameDay = calendar.startOfDay(for: game.date)
                return calendar.isDate(gameDay, inSameDayAs: today)
            }.sorted { $0.date > $1.date }

            print("✅ Loaded \(liveMatches.count) live, \(finishedMatches.count) finished today, \(upcomingTodayMatches.count) upcoming today from SwiftData")

            // Load events from SwiftData
            await loadEventsFromSwiftData()

            // Update widgets and auto-start Live Activity for favorite teams
            for match in liveMatches {
                updateWidgetAndLiveActivity(for: match)

                // Auto-start Live Activity for favorite team matches
                if isFavoriteTeamMatch(match) && !LiveActivityManager.shared.isActivityActive(for: Int32(match.id)) {
                    print("🌟 Auto-starting Live Activity for favorite team match: \(match.homeTeam) vs \(match.awayTeam)")
                    let state = createLiveActivityState(from: match, events: fixtureEvents[match.id] ?? [])
                    _ = LiveActivityManager.shared.startActivity(
                        fixtureID: Int32(match.id),
                        homeTeam: match.homeTeam,
                        awayTeam: match.awayTeam,
                        competition: match.competition,
                        initialState: state
                    )
                }
            }

            // Save upcoming matches for today to widget store
            for match in upcomingTodayMatches {
                let snapshot = createWidgetSnapshot(from: match, events: fixtureEvents[match.id] ?? [])
                HomeWidgetSnapshotStore.shared.save(snapshot)
            }

            // Save finished matches for today to widget store
            for match in finishedMatches {
                let snapshot = createWidgetSnapshot(from: match, events: fixtureEvents[match.id] ?? [])
                HomeWidgetSnapshotStore.shared.save(snapshot)
            }

            // Reload all widgets after saving snapshots
            WidgetCenter.shared.reloadAllTimelines()

            // Start or update streaming based on live matches
            streamService.updateLiveMatchesStatus(hasLiveMatches: !liveMatches.isEmpty)

            if liveMatches.isEmpty {
                stopUpdateTimer()
                secondsUntilNextUpdate = 0
            } else {
                startUpdateTimer()
            }
        } catch {
            errorMessage = "Failed to load matches: \(error.localizedDescription)"
            print("Error fetching matches: \(error)")
        }

        isLoading = false
    }

    // MARK: - Load Events from SwiftData
    private func loadEventsFromSwiftData() async {
        guard let dataManager = dataManager else { return }

        let matchesNeedingEvents = liveMatches.isEmpty ? [] : (liveMatches + finishedMatches + upcomingMatches)

        for match in matchesNeedingEvents {
            do {
                let events = try dataManager.getAfconEvents(for: match.id)
                if !events.isEmpty {
                    fixtureEvents[match.id] = events
                }
            } catch {
                print("❌ Failed to load events from SwiftData for fixture \(match.id): \(error)")
            }
        }

        // Fetch and store events from API only for live sessions
        if !liveMatches.isEmpty {
            await syncEventsForActiveMatches()
        }
    }

    // MARK: - Sync Events for Active Matches
    private func syncEventsForActiveMatches() async {
        guard let dataManager = dataManager else { return }

        // Sync events for live matches and finished matches from today
        let matchesToSync = liveMatches + finishedMatches

        for match in matchesToSync {
            do {
                // Fetch latest events from API
                let apiEvents = try await service.getFixtureEvents(fixtureId: Int32(match.id))

                // Store in SwiftData
                await dataManager.storeEvents(apiEvents, for: match.id)

                // Update local cache
                fixtureEvents[match.id] = apiEvents
            } catch {
                print("❌ Failed to sync events for fixture \(match.id): \(error)")
            }
        }
    }

    // MARK: - Start Live Updates Stream
    func startLiveUpdates() {
        // Delegate to global stream service
        streamService.startStreaming(hasLiveMatches: !liveMatches.isEmpty)
    }

    // MARK: - Stop Live Updates Stream
    func stopLiveUpdates() {
        // Don't stop the global stream when view disappears
        // It will stop automatically when there are no more live matches
        print("ℹ️ View disappeared but keeping stream active for other views")
    }

    // MARK: - Handle Live Update
    @MainActor
    private func handleLiveUpdate(_ update: Afcon_LiveMatchUpdate) async {
        print("📡 Live update for fixture \(update.fixtureID): \(update.eventType)")

        let updatedGame = update.fixture.toGame()
        let fixtureId = Int(update.fixtureID)

        // Update fixture in SwiftData
        if let dataManager = dataManager {
            Task {
                do {
                    let fixtures = try dataManager.getAllFixtures()
                    if let existingFixture = fixtures.first(where: { $0.id == fixtureId }) {
                        dataManager.updateFixtureModel(existingFixture, with: update.fixture)
                    }
                } catch {
                    print("❌ Failed to update fixture \(fixtureId) in SwiftData: \(error)")
                }
            }
        }

        // Check if it's in live matches
        if let index = liveMatches.firstIndex(where: { $0.id == fixtureId }) {
            liveMatches[index] = updatedGame

            // Update events for this live match
            await fetchEventsForSingleMatch(fixtureId: fixtureId)
        } else if updatedGame.status == .live {
            // New live match started - remove from upcoming if present
            upcomingMatches.removeAll { $0.id == fixtureId }

            // Only add if not already in live matches
            if !liveMatches.contains(where: { $0.id == fixtureId }) {
                liveMatches.append(updatedGame)
                // Re-sort live matches by kickoff time
                liveMatches.sort { $0.date < $1.date }

                // Update stream status
                streamService.updateLiveMatchesStatus(hasLiveMatches: !liveMatches.isEmpty)
            }

            // Fetch events for newly live match
            await fetchEventsForSingleMatch(fixtureId: fixtureId)

            // Auto-start Live Activity for favorite team matches
            if isFavoriteTeamMatch(updatedGame) && !LiveActivityManager.shared.isActivityActive(for: Int32(fixtureId)) {
                print("🌟 Auto-starting Live Activity for favorite team match going live: \(updatedGame.homeTeam) vs \(updatedGame.awayTeam)")
                let state = createLiveActivityState(from: updatedGame, events: fixtureEvents[fixtureId] ?? [])
                _ = LiveActivityManager.shared.startActivity(
                    fixtureID: Int32(fixtureId),
                    homeTeam: updatedGame.homeTeam,
                    awayTeam: updatedGame.awayTeam,
                    competition: updatedGame.competition,
                    initialState: state
                )
            }
        } else if updatedGame.status == .upcoming {
            // Update in upcoming list
            if let index = upcomingMatches.firstIndex(where: { $0.id == fixtureId }) {
                upcomingMatches[index] = updatedGame

                // Update widget store for upcoming match changes (e.g., kickoff time)
                let snapshot = createWidgetSnapshot(from: updatedGame, events: fixtureEvents[fixtureId] ?? [])
                HomeWidgetSnapshotStore.shared.save(snapshot)
                WidgetCenter.shared.reloadAllTimelines()
            }
        } else if updatedGame.status == .finished {
            // Match finished - remove from live, add to finished
            liveMatches.removeAll { $0.id == fixtureId }

            // Update stream status
            streamService.updateLiveMatchesStatus(hasLiveMatches: !liveMatches.isEmpty)

            // Add to finished if it's from today and not already there
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let gameDay = calendar.startOfDay(for: updatedGame.date)

            if calendar.isDate(gameDay, inSameDayAs: today) {
                // Only add if not already in finished matches
                if !finishedMatches.contains(where: { $0.id == fixtureId }) {
                    finishedMatches.append(updatedGame)
                    // Re-sort finished matches by most recent first
                    finishedMatches.sort { $0.date > $1.date }
                } else {
                    // Update existing finished match
                    if let index = finishedMatches.firstIndex(where: { $0.id == fixtureId }) {
                        finishedMatches[index] = updatedGame
                    }
                }

                // Fetch final events
                await fetchEventsForSingleMatch(fixtureId: fixtureId)
            }
        }
    }

    // MARK: - Fetch Events for Single Match
    private func fetchEventsForSingleMatch(fixtureId: Int) async {
        do {
            let events = try await service.getFixtureEvents(fixtureId: Int32(fixtureId))

            // Store events in SwiftData
            if let dataManager = dataManager {
                await dataManager.storeEvents(events, for: fixtureId)
            }

            await MainActor.run {
                self.fixtureEvents[fixtureId] = events

                // Update widget and Live Activity after fetching events
                if let game = self.liveMatches.first(where: { $0.id == fixtureId }) ??
                              self.finishedMatches.first(where: { $0.id == fixtureId }) {
                    self.updateWidgetAndLiveActivity(for: game)
                }
            }
        } catch {
            print("❌ Failed to fetch events for fixture \(fixtureId): \(error)")
        }
    }

    // MARK: - Widget & Live Activity Updates

    /// Update widget and Live Activity for a match
    private func updateWidgetAndLiveActivity(for game: Game) {
        let events = fixtureEvents[game.id] ?? []

        // Save widget snapshot
        let snapshot = createWidgetSnapshot(from: game, events: events)
        HomeWidgetSnapshotStore.shared.save(snapshot)

        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()

        // Update or start Live Activity for live matches
        if game.status == .live {
            updateLiveActivity(for: game, events: events)
        } else if game.status == .finished {
            // End Live Activity when match finishes
            Task {
                await LiveActivityManager.shared.endActivity(
                    fixtureID: Int32(game.id),
                    finalState: createLiveActivityState(from: game, events: events)
                )
            }
        }
    }

    /// Create widget snapshot from game data
    private func createWidgetSnapshot(from game: Game, events: [Afcon_FixtureEvent]) -> LiveMatchWidgetSnapshot {
        let goalEvents = events.filter { $0.isGoal }
        let homeGoals = goalEvents.filter { $0.team.id == Int32(game.homeTeamId) }.map { formatGoalEvent($0) }
        let awayGoals = goalEvents.filter { $0.team.id == Int32(game.awayTeamId) }.map { formatGoalEvent($0) }

        // Calculate elapsed seconds
        let elapsedSeconds: Int
        if let minuteValue = Int(game.minute.filter { $0.isNumber }) {
            elapsedSeconds = minuteValue * 60
        } else {
            elapsedSeconds = 0
        }

        return LiveMatchWidgetSnapshot(
            fixtureID: Int32(game.id),
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            competition: game.competition,
            homeScore: game.homeScore,
            awayScore: game.awayScore,
            status: game.statusShort,
            elapsedSeconds: elapsedSeconds,
            lastUpdated: Date(),
            homeLogoPath: game.homeTeamFlagAsset,
            awayLogoPath: game.awayTeamFlagAsset,
            homeGoalEvents: homeGoals,
            awayGoalEvents: awayGoals,
            fixtureTimestamp: Int(game.date.timeIntervalSince1970)
        )
    }

    /// Create Live Activity state from game data
    private func createLiveActivityState(from game: Game, events: [Afcon_FixtureEvent]) -> LiveScoreActivityAttributes.ContentState {
        let goalEvents = events.filter { $0.isGoal }
        let homeGoals = goalEvents.filter { $0.team.id == Int32(game.homeTeamId) }.map { formatGoalEvent($0) }
        let awayGoals = goalEvents.filter { $0.team.id == Int32(game.awayTeamId) }.map { formatGoalEvent($0) }

        // Parse elapsed minutes
        let elapsed: Int32
        if let minuteValue = Int(game.minute.filter { $0.isNumber }) {
            elapsed = Int32(minuteValue)
        } else {
            elapsed = 0
        }

        return LiveScoreActivityAttributes.ContentState(
            homeScore: Int32(game.homeScore),
            awayScore: Int32(game.awayScore),
            status: game.statusShort,
            elapsed: elapsed,
            lastUpdateTime: Date(),
            firstPeriodStart: nil, // Could be calculated if we have match start time
            secondPeriodStart: nil, // Could be calculated if we track half time
            homeTeamLogoPath: game.homeTeamFlagAsset,
            awayTeamLogoPath: game.awayTeamFlagAsset,
            homeGoalEvents: homeGoals,
            awayGoalEvents: awayGoals
        )
    }

    /// Update or start Live Activity
    private func updateLiveActivity(for game: Game, events: [Afcon_FixtureEvent]) {
        let state = createLiveActivityState(from: game, events: events)

        if LiveActivityManager.shared.isActivityActive(for: Int32(game.id)) {
            // Update existing activity
            Task {
                await LiveActivityManager.shared.updateActivity(
                    fixtureID: Int32(game.id),
                    newState: state
                )
            }
        } else {
            // Start new activity
            LiveActivityManager.shared.startActivity(
                fixtureID: Int32(game.id),
                homeTeam: game.homeTeam,
                awayTeam: game.awayTeam,
                competition: game.competition,
                initialState: state
            )
        }
    }

    /// Format goal event for display
    private func formatGoalEvent(_ event: Afcon_FixtureEvent) -> String {
        let minute = event.time.elapsed > 0 ? "\(event.time.elapsed)'" : ""
        let player = event.player.name

        if event.hasAssist && !event.assist.name.isEmpty {
            return "\(minute) \(player) (Ast. \(event.assist.name))"
        } else {
            return "\(minute) \(player)"
        }
    }
}
