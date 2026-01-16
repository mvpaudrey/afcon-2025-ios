import Foundation
import Observation
import SwiftData
import AFCONClient

@Observable
final class ScheduleViewModel {
    private let afconService: AFCONServiceWrapper
    var modelContext: ModelContext?
    private let fixturesRefreshInterval: TimeInterval = 6 * 60 * 60

    var fixtures: [FixtureModel] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(afconService: AFCONServiceWrapper = .shared, modelContext: ModelContext? = nil) {
        self.afconService = afconService
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Fetch fixtures from local database
    @MainActor
    func loadFixturesFromDatabase() {
        guard let modelContext = modelContext else {
            print("No ModelContext available")
            return
        }

        do {
            let descriptor = FetchDescriptor<FixtureModel>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            fixtures = try modelContext.fetch(descriptor)
            print("✅ Loaded \(fixtures.count) fixtures from database")
        } catch {
            print("❌ Failed to load fixtures from database: \(error)")
            errorMessage = "Failed to load fixtures: \(error.localizedDescription)"
        }
    }

    /// Fetch all fixtures from middleware and save to database
    @MainActor
    func fetchAllFixtures() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📡 Fetching all fixtures from middleware...")
            let grpcFixtures = try await afconService.getFixtures(
                leagueId: 6,
                season: 2025
            )

            print("✅ Received \(grpcFixtures.count) fixtures from middleware")

            // Convert and save to database
            await saveFixturesToDatabase(grpcFixtures)
            AppSettings.shared.lastFixturesSyncAt = Date()

            // Reload from database
            loadFixturesFromDatabase()

        } catch {
            print("❌ Failed to fetch fixtures: \(error)")
            errorMessage = "Failed to fetch fixtures: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func shouldRefreshFixtures() -> Bool {
        guard let lastSync = AppSettings.shared.lastFixturesSyncAt else {
            return true
        }
        return Date().timeIntervalSince(lastSync) >= fixturesRefreshInterval
    }

    /// Fetch fixtures by date from middleware
    @MainActor
    func fetchFixturesByDate(_ date: String) async {
        isLoading = true
        errorMessage = nil

        do {
            print("📡 Fetching fixtures for date: \(date)")
            let grpcFixtures = try await afconService.getFixtures(
                leagueId: 6,
                season: 2025,
                date: date
            )

            print("✅ Received \(grpcFixtures.count) fixtures")

            // Convert and save to database
            await saveFixturesToDatabase(grpcFixtures)

            // Reload from database
            loadFixturesFromDatabase()

        } catch {
            print("❌ Failed to fetch fixtures: \(error)")
            errorMessage = "Failed to fetch fixtures: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh fixtures (fetch from middleware and update database)
    @MainActor
    func refreshFixtures() async {
        await fetchAllFixtures()
    }

    /// Sync fixtures to server database (one-time operation on first launch)
    @MainActor
    func syncFixturesToServer() async {
        isLoading = true
        errorMessage = nil

        do {
            print("🔄 Syncing fixtures to server database...")
            let response = try await afconService.syncFixtures(
                leagueId: 6,
                season: 2025,
                competition: "AFCON 2025"
            )

            if response.success {
                print("✅ Server sync successful: \(response.fixturesSynced) fixtures synced")
                print("📝 \(response.message)")

                // Now fetch fixtures from server (which will read from its database)
                await fetchAllFixtures()
            } else {
                print("❌ Server sync failed: \(response.message)")
                errorMessage = response.message
            }

        } catch {
            print("❌ Failed to sync fixtures to server: \(error)")
            errorMessage = "Failed to sync fixtures: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Check if fixtures need initial sync and perform it
    @MainActor
    func performInitialSyncIfNeeded() async {
        // Check if we have fixtures in local database
        loadFixturesFromDatabase()

        if !hasFixtures {
            print("📥 No fixtures in local database, performing initial sync...")
            await syncFixturesToServer()
        } else {
            print("✅ Fixtures already exist in local database (\(fixtures.count) fixtures)")
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func saveFixturesToDatabase(_ grpcFixtures: [Afcon_Fixture]) async {
        guard let modelContext = modelContext else {
            print("⚠️ No ModelContext available, skipping database save")
            return
        }

        do {
            // Convert gRPC fixtures to FixtureModel
            let fixtureModels = grpcFixtures.map { $0.toFixtureModel() }

            // Insert or update fixtures in database
            for fixtureModel in fixtureModels {
                // Capture the id as a plain value for the predicate
                let targetID = fixtureModel.id
                let predicate = #Predicate<FixtureModel> { fixture in
                    fixture.id == targetID
                }

                let descriptor = FetchDescriptor<FixtureModel>(predicate: predicate)
                let existingFixtures = try modelContext.fetch(descriptor)

                if let existingFixture = existingFixtures.first {
                    // Update existing fixture
                    existingFixture.statusLong = fixtureModel.statusLong
                    existingFixture.statusShort = fixtureModel.statusShort
                    existingFixture.statusElapsed = fixtureModel.statusElapsed
                    existingFixture.homeGoals = fixtureModel.homeGoals
                    existingFixture.awayGoals = fixtureModel.awayGoals
                    existingFixture.halftimeHome = fixtureModel.halftimeHome
                    existingFixture.halftimeAway = fixtureModel.halftimeAway
                    existingFixture.fulltimeHome = fixtureModel.fulltimeHome
                    existingFixture.fulltimeAway = fixtureModel.fulltimeAway
                    existingFixture.homeTeamWinner = fixtureModel.homeTeamWinner
                    existingFixture.awayTeamWinner = fixtureModel.awayTeamWinner
                    existingFixture.lastUpdated = Date()
                    print("🔄 Updated fixture: \(existingFixture.homeTeamName) vs \(existingFixture.awayTeamName)")
                } else {
                    // Insert new fixture
                    modelContext.insert(fixtureModel)
                    print("➕ Inserted new fixture: \(fixtureModel.homeTeamName) vs \(fixtureModel.awayTeamName)")
                }
            }

            // Save context
            try modelContext.save()
            print("✅ Successfully saved \(fixtureModels.count) fixtures to database")

        } catch {
            print("❌ Failed to save fixtures to database: \(error)")
            errorMessage = "Failed to save fixtures: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    var upcomingFixtures: [FixtureModel] {
        fixtures.filter { $0.isUpcoming }
    }

    var liveFixtures: [FixtureModel] {
        fixtures.filter { $0.isLive }
    }

    var finishedFixtures: [FixtureModel] {
        fixtures.filter { $0.isFinished }
    }

    var hasFixtures: Bool {
        !fixtures.isEmpty
    }
}
