import Foundation
import SwiftData

/// Service to load bundled fixture data from JSON into SwiftData
@MainActor
class BundledFixturesLoader {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Load fixtures from bundled JSON file based on current locale
    func loadBundledFixtures() throws {
        let locale = Locale.current.language.languageCode?.identifier ?? "en"
        let fileName = fixtureFileName(for: locale)

        print("Loading fixtures for locale: \(locale) from \(fileName).json")

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw BundledFixturesError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let fixtureData = try decoder.decode([FixtureData].self, from: data)

        print("Loading \(fixtureData.count) bundled fixtures into SwiftData...")

        for data in fixtureData {
            let fixture = FixtureModel(
                id: data.id,
                referee: data.referee,
                timezone: data.timezone,
                date: Date(timeIntervalSince1970: TimeInterval(data.timestamp)),
                timestamp: data.timestamp,
                venueId: data.venueId,
                venueName: data.venueName,
                venueCity: data.venueCity,
                statusLong: data.statusLong,
                statusShort: data.statusShort,
                statusElapsed: data.statusElapsed,
                homeTeamId: data.homeTeamId,
                homeTeamName: data.homeTeamName,
                homeTeamLogo: data.homeTeamLogo,
                homeTeamWinner: data.homeTeamWinner,
                awayTeamId: data.awayTeamId,
                awayTeamName: data.awayTeamName,
                awayTeamLogo: data.awayTeamLogo,
                awayTeamWinner: data.awayTeamWinner,
                homeGoals: data.homeGoals,
                awayGoals: data.awayGoals,
                halftimeHome: data.halftimeHome,
                halftimeAway: data.halftimeAway,
                fulltimeHome: data.fulltimeHome,
                fulltimeAway: data.fulltimeAway,
                competition: data.competition
            )

            modelContext.insert(fixture)
        }

        try modelContext.save()
        print("Successfully loaded \(fixtureData.count) fixtures from bundle!")
    }

    /// Maps locale to the appropriate JSON file name
    private func fixtureFileName(for locale: String) -> String {
        switch locale {
        case "ar":
            return "InitialFixtures_ar"
        case "fr":
            return "InitialFixtures_fr"
        default:
            return "InitialFixtures_en"
        }
    }
}

// MARK: - Decodable Models

struct FixtureData: Codable {
    let id: Int
    let referee: String
    let timezone: String
    let timestamp: Int
    let venueId: Int
    let venueName: String
    let venueCity: String
    let statusLong: String
    let statusShort: String
    let statusElapsed: Int
    let homeTeamId: Int
    let homeTeamName: String
    let homeTeamLogo: String
    let homeTeamWinner: Bool
    let awayTeamId: Int
    let awayTeamName: String
    let awayTeamLogo: String
    let awayTeamWinner: Bool
    let homeGoals: Int
    let awayGoals: Int
    let halftimeHome: Int
    let halftimeAway: Int
    let fulltimeHome: Int
    let fulltimeAway: Int
    let competition: String
}

// MARK: - Errors

enum BundledFixturesError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "InitialFixtures.json not found in app bundle"
        case .decodingFailed:
            return "Failed to decode fixture data from JSON"
        }
    }
}
