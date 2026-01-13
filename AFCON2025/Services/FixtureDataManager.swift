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

        // Use localized team names
        let homeTeamName = localizedTeamName(grpcFixture.teams.home.name)
        let awayTeamName = localizedTeamName(grpcFixture.teams.away.name)

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
            homeTeamName: homeTeamName,
            homeTeamLogo: grpcFixture.teams.home.logo,
            homeTeamWinner: grpcFixture.teams.home.winner,
            awayTeamId: Int(grpcFixture.teams.away.id),
            awayTeamName: awayTeamName,
            awayTeamLogo: grpcFixture.teams.away.logo,
            awayTeamWinner: grpcFixture.teams.away.winner,
            homeGoals: Int(grpcFixture.goals.home),
            awayGoals: Int(grpcFixture.goals.away),
            halftimeHome: Int(grpcFixture.score.halftime.home),
            halftimeAway: Int(grpcFixture.score.halftime.away),
            fulltimeHome: Int(grpcFixture.score.fulltime.home),
            fulltimeAway: Int(grpcFixture.score.fulltime.away),
            penaltyHome: Int(grpcFixture.score.penalty.home),
            penaltyAway: Int(grpcFixture.score.penalty.away),
            competition: "AFCON 2025",
            round: grpcFixture.league.round.isEmpty ? nil : grpcFixture.league.round
        )
    }

    // MARK: - Localization Helper

    private func localizedTeamName(_ name: String) -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "fr"

        switch language {
        case "fr":
            return frenchTeamNames[name] ?? name
        case "ar":
            return arabicTeamNames[name] ?? name
        case "es":
            return spanishTeamNames[name] ?? name
        default:
            return name
        }
    }

    private let frenchTeamNames: [String: String] = [
        "Morocco": "Maroc",
        "Senegal": "Sénégal",
        "Algeria": "Algérie",
        "Tunisia": "Tunisie",
        "Egypt": "Égypte",
        "Nigeria": "Nigeria",
        "Cameroon": "Cameroun",
        "Ghana": "Ghana",
        "Ivory Coast": "Côte d'Ivoire",
        "Cote d'Ivoire": "Côte d'Ivoire",
        "South Africa": "Afrique du Sud",
        "Mali": "Mali",
        "Burkina Faso": "Burkina Faso",
        "Guinea": "Guinée",
        "Guinea-Bissau": "Guinée-Bissau",
        "Equatorial Guinea": "Guinée équatoriale",
        "Gabon": "Gabon",
        "Angola": "Angola",
        "Zambia": "Zambie",
        "Zimbabwe": "Zimbabwe",
        "Tanzania": "Tanzanie",
        "Comoros": "Comores",
        "Botswana": "Botswana",
        "Benin": "Bénin",
        "Uganda": "Ouganda",
        "Mozambique": "Mozambique",
        "DR Congo": "RD Congo",
        "Congo DR": "RD Congo",
        "Sudan": "Soudan"
    ]

    private let arabicTeamNames: [String: String] = [
        "Morocco": "المغرب",
        "Senegal": "السنغال",
        "Algeria": "الجزائر",
        "Tunisia": "تونس",
        "Egypt": "مصر",
        "Nigeria": "نيجيريا",
        "Cameroon": "الكاميرون",
        "Ghana": "غانا",
        "Ivory Coast": "كوت ديفوار",
        "Cote d'Ivoire": "كوت ديفوار",
        "South Africa": "جنوب أفريقيا",
        "Mali": "مالي",
        "Burkina Faso": "بوركينا فاسو",
        "Guinea": "غينيا",
        "Guinea-Bissau": "غينيا بيساو",
        "Equatorial Guinea": "غينيا الاستوائية",
        "Gabon": "الغابون",
        "Angola": "أنغولا",
        "Zambia": "زامبيا",
        "Zimbabwe": "زيمبابوي",
        "Tanzania": "تنزانيا",
        "Comoros": "جزر القمر",
        "Botswana": "بوتسوانا",
        "Benin": "بنين",
        "Uganda": "أوغندا",
        "Mozambique": "موزمبيق",
        "DR Congo": "جمهورية الكونغو الديمقراطية",
        "Congo DR": "جمهورية الكونغو الديمقراطية",
        "Sudan": "السودان"
    ]

    private let spanishTeamNames: [String: String] = [
        "Morocco": "Marruecos",
        "Senegal": "Senegal",
        "Algeria": "Argelia",
        "Tunisia": "Túnez",
        "Egypt": "Egipto",
        "Nigeria": "Nigeria",
        "Cameroon": "Camerún",
        "Ghana": "Ghana",
        "Ivory Coast": "Costa de Marfil",
        "Cote d'Ivoire": "Costa de Marfil",
        "South Africa": "Sudáfrica",
        "Mali": "Malí",
        "Burkina Faso": "Burkina Faso",
        "Guinea": "Guinea",
        "Guinea-Bissau": "Guinea-Bisáu",
        "Equatorial Guinea": "Guinea Ecuatorial",
        "Gabon": "Gabón",
        "Angola": "Angola",
        "Zambia": "Zambia",
        "Zimbabwe": "Zimbabue",
        "Tanzania": "Tanzania",
        "Comoros": "Comoras",
        "Botswana": "Botsuana",
        "Benin": "Benín",
        "Uganda": "Uganda",
        "Mozambique": "Mozambique",
        "DR Congo": "RD del Congo",
        "Congo DR": "RD del Congo",
        "Sudan": "Sudán"
    ]

    func updateFixtureModel(_ model: FixtureModel, with grpcFixture: Afcon_Fixture) {
        // Update mutable fields that might change during a match
        model.statusLong = grpcFixture.status.long
        model.statusShort = grpcFixture.status.short
        model.statusElapsed = Int(grpcFixture.status.elapsed)
        model.statusExtra = Int(grpcFixture.status.extra)

        model.homeGoals = Int(grpcFixture.goals.home)
        model.awayGoals = Int(grpcFixture.goals.away)

        model.halftimeHome = Int(grpcFixture.score.halftime.home)
        model.halftimeAway = Int(grpcFixture.score.halftime.away)
        model.fulltimeHome = Int(grpcFixture.score.fulltime.home)
        model.fulltimeAway = Int(grpcFixture.score.fulltime.away)
        model.penaltyHome = Int(grpcFixture.score.penalty.home)
        model.penaltyAway = Int(grpcFixture.score.penalty.away)

        model.homeTeamWinner = grpcFixture.teams.home.winner
        model.awayTeamWinner = grpcFixture.teams.away.winner

        // Note: round is not updated as it's not available from gRPC API

        model.lastUpdated = Date()
    }
}

// MARK: - Event Management
extension FixtureDataManager {
    /// Store events for a fixture in SwiftData
    func storeEvents(_ grpcEvents: [Afcon_FixtureEvent], for fixtureId: Int) async {
        do {
            for grpcEvent in grpcEvents {
                let eventModel = FixtureEventModel.from(grpcEvent, fixtureId: fixtureId)

                // Check if event already exists
                let eventId = eventModel.id
                let descriptor = FetchDescriptor<FixtureEventModel>(
                    predicate: #Predicate<FixtureEventModel> { event in
                        event.id == eventId
                    }
                )

                if try modelContext.fetch(descriptor).isEmpty {
                    // Insert new event
                    modelContext.insert(eventModel)
                    print("📝 Stored new event: \(eventModel.eventType) at \(eventModel.timeElapsed)' for fixture \(fixtureId)")
                }
            }

            try modelContext.save()
        } catch {
            print("❌ Failed to store events: \(error)")
        }
    }

    /// Get all events for a specific fixture from SwiftData
    func getEvents(for fixtureId: Int) throws -> [FixtureEventModel] {
        let descriptor = FetchDescriptor<FixtureEventModel>(
            predicate: #Predicate { event in
                event.fixtureId == fixtureId
            },
            sortBy: [
                SortDescriptor(\.timeElapsed),
                SortDescriptor(\.createdAt)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Convert stored events to Afcon_FixtureEvent for UI
    func getAfconEvents(for fixtureId: Int) throws -> [Afcon_FixtureEvent] {
        let storedEvents = try getEvents(for: fixtureId)
        return storedEvents.map { $0.toAfconFixtureEvent() }
    }

    /// Delete all events for a fixture
    func deleteEvents(for fixtureId: Int) throws {
        let descriptor = FetchDescriptor<FixtureEventModel>(
            predicate: #Predicate { event in
                event.fixtureId == fixtureId
            }
        )

        let events = try modelContext.fetch(descriptor)
        for event in events {
            modelContext.delete(event)
        }

        try modelContext.save()
        print("🗑️ Deleted \(events.count) events for fixture \(fixtureId)")
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
