import Foundation
import SwiftData
import AFCONClient
import Observation

/// Manager for syncing fixtures from server to SwiftData
@Observable
@MainActor
class FixtureDataManager {
    private let service: AFCONServiceWrapper
    private let modelContext: ModelContext

    var isInitializing = false
    var initializationError: String?
    var lastSyncDate: Date?

    init(service: AFCONServiceWrapper = .shared, modelContext: ModelContext) {
        self.service = service
        self.modelContext = modelContext
    }

    // MARK: - Initialize Fixtures

    /// Fetch all fixtures from server and populate SwiftData
    func initializeFixtures(leagueId: Int32 = 6, season: Int32 = 2025) async {
        isInitializing = true
        initializationError = nil

        do {
            // Fetch all fixtures from server
            let serverFixtures = try await service.getFixtures(
                leagueId: leagueId,
                season: season
            )

            print("Fetched \(serverFixtures.count) fixtures from server")

            // Clear existing fixtures (optional - remove if you want to merge)
            try await clearAllFixtures()

            // Map and save each fixture
            for grpcFixture in serverFixtures {
                let fixtureModel = mapToFixtureModel(grpcFixture)
                modelContext.insert(fixtureModel)
            }

            // Save to SwiftData
            try modelContext.save()

            lastSyncDate = Date()
            print("Successfully initialized \(serverFixtures.count) fixtures in SwiftData")

        } catch {
            initializationError = "Failed to initialize fixtures: \(error.localizedDescription)"
            print("Error initializing fixtures: \(error)")
        }

        isInitializing = false
    }

    // MARK: - Sync Updates

    /// Sync specific fixtures (e.g., today's matches or live matches)
    func syncLiveFixtures(leagueId: Int32 = 6, season: Int32 = 2025) async {
        do {
            let liveFixtures = try await service.getFixtures(
                leagueId: leagueId,
                season: season,
                live: true
            )

            for grpcFixture in liveFixtures {
                // Check if fixture exists
                let fixtureId = Int(grpcFixture.id)
                let descriptor = FetchDescriptor<FixtureModel>(
                    predicate: #Predicate<FixtureModel> { fixture in
                        fixture.id == fixtureId
                    }
                )

                if let existingFixture = try modelContext.fetch(descriptor).first {
                    // Update existing fixture
                    updateFixtureModel(existingFixture, with: grpcFixture)
                } else {
                    // Insert new fixture
                    let fixtureModel = mapToFixtureModel(grpcFixture)
                    modelContext.insert(fixtureModel)
                }
            }

            try modelContext.save()
            lastSyncDate = Date()

        } catch {
            print("Error syncing live fixtures: \(error)")
        }
    }

    /// Sync fixtures for a specific date
    func syncFixturesForDate(_ date: Date, leagueId: Int32 = 6, season: Int32 = 2025) async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        do {
            let fixtures = try await service.getFixturesByDate(
                leagueId: leagueId,
                season: season,
                date: dateString
            )

            for grpcFixture in fixtures {
                let fixtureId = Int(grpcFixture.id)
                let descriptor = FetchDescriptor<FixtureModel>(
                    predicate: #Predicate<FixtureModel> { fixture in
                        fixture.id == fixtureId
                    }
                )

                if let existingFixture = try modelContext.fetch(descriptor).first {
                    updateFixtureModel(existingFixture, with: grpcFixture)
                } else {
                    let fixtureModel = mapToFixtureModel(grpcFixture)
                    modelContext.insert(fixtureModel)
                }
            }

            try modelContext.save()
            lastSyncDate = Date()

        } catch {
            print("Error syncing fixtures for date: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func clearAllFixtures() async throws {
        let descriptor = FetchDescriptor<FixtureModel>()
        let allFixtures = try modelContext.fetch(descriptor)

        for fixture in allFixtures {
            modelContext.delete(fixture)
        }

        try modelContext.save()
        print("Cleared all existing fixtures")
    }

    private func mapToFixtureModel(_ grpcFixture: Afcon_Fixture) -> FixtureModel {
        let timestamp = Int(grpcFixture.timestamp)
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        return FixtureModel(
            id: Int(grpcFixture.id),
            referee: grpcFixture.referee,
            timezone: grpcFixture.timezone,
            date: date,
            timestamp: timestamp,
            venueId: Int(grpcFixture.venue.id),
            venueName: grpcFixture.venue.name,
            venueCity: grpcFixture.venue.city,
            statusLong: grpcFixture.status.long,
            statusShort: grpcFixture.status.short,
            statusElapsed: Int(grpcFixture.status.elapsed),
            homeTeamId: Int(grpcFixture.teams.home.id),
            homeTeamName: grpcFixture.teams.home.name,
            homeTeamLogo: grpcFixture.teams.home.logo,
            homeTeamWinner: grpcFixture.teams.home.winner,
            awayTeamId: Int(grpcFixture.teams.away.id),
            awayTeamName: grpcFixture.teams.away.name,
            awayTeamLogo: grpcFixture.teams.away.logo,
            awayTeamWinner: grpcFixture.teams.away.winner,
            homeGoals: Int(grpcFixture.goals.home),
            awayGoals: Int(grpcFixture.goals.away),
            halftimeHome: Int(grpcFixture.score.halftime.home),
            halftimeAway: Int(grpcFixture.score.halftime.away),
            fulltimeHome: Int(grpcFixture.score.fulltime.home),
            fulltimeAway: Int(grpcFixture.score.fulltime.away),
            competition: "AFCON 2025"
        )
    }

    private func updateFixtureModel(_ model: FixtureModel, with grpcFixture: Afcon_Fixture) {
        // Update mutable fields that might change during a match
        model.statusLong = grpcFixture.status.long
        model.statusShort = grpcFixture.status.short
        model.statusElapsed = Int(grpcFixture.status.elapsed)

        model.homeGoals = Int(grpcFixture.goals.home)
        model.awayGoals = Int(grpcFixture.goals.away)

        model.halftimeHome = Int(grpcFixture.score.halftime.home)
        model.halftimeAway = Int(grpcFixture.score.halftime.away)
        model.fulltimeHome = Int(grpcFixture.score.fulltime.home)
        model.fulltimeAway = Int(grpcFixture.score.fulltime.away)

        model.homeTeamWinner = grpcFixture.teams.home.winner
        model.awayTeamWinner = grpcFixture.teams.away.winner

        model.lastUpdated = Date()
    }
}

// MARK: - Query Helpers
extension FixtureDataManager {
    /// Get all fixtures from SwiftData
    func getAllFixtures() throws -> [FixtureModel] {
        let descriptor = FetchDescriptor<FixtureModel>(
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get live fixtures from SwiftData
    func getLiveFixtures() throws -> [FixtureModel] {
        let descriptor = FetchDescriptor<FixtureModel>(
            predicate: #Predicate { fixture in
                ["LIVE", "1H", "2H", "HT", "ET", "P"].contains(fixture.statusShort)
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get upcoming fixtures from SwiftData
    func getUpcomingFixtures() throws -> [FixtureModel] {
        let descriptor = FetchDescriptor<FixtureModel>(
            predicate: #Predicate { fixture in
                !["LIVE", "1H", "2H", "HT", "ET", "P", "FT", "AET", "PEN"].contains(fixture.statusShort)
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Get fixtures for a specific date
    func getFixtures(for date: Date) throws -> [FixtureModel] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<FixtureModel>(
            predicate: #Predicate { fixture in
                fixture.date >= startOfDay && fixture.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }
}
