import Foundation
import SwiftData

/// Service to load bundled fixture data from JSON into SwiftData
@MainActor
public class BundledFixturesLoader {
    private let modelContext: ModelContext

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Load fixtures from bundled JSON file based on current locale
    public func loadBundledFixtures() throws {
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
                penaltyHome: data.penaltyHome,
                penaltyAway: data.penaltyAway,
                competition: data.competition,
                round: data.round
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

public struct FixtureData: Codable {
    public let id: Int
    public let referee: String
    public let timezone: String
    public let timestamp: Int
    public let venueId: Int
    public let venueName: String
    public let venueCity: String
    public let statusLong: String
    public let statusShort: String
    public let statusElapsed: Int
    public let homeTeamId: Int
    public let homeTeamName: String
    public let homeTeamLogo: String
    public let homeTeamWinner: Bool
    public let awayTeamId: Int
    public let awayTeamName: String
    public let awayTeamLogo: String
    public let awayTeamWinner: Bool
    public let homeGoals: Int
    public let awayGoals: Int
    public let halftimeHome: Int
    public let halftimeAway: Int
    public let fulltimeHome: Int
    public let fulltimeAway: Int
    public let penaltyHome: Int
    public let penaltyAway: Int
    public let competition: String
    public let round: String?
}

// MARK: - Errors

public enum BundledFixturesError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "InitialFixtures.json not found in app bundle"
        case .decodingFailed:
            return "Failed to decode fixture data from JSON"
        }
    }
}
