import Foundation

struct LiveMatchWidgetSnapshot: Codable, Equatable {
    let fixtureID: Int32
    let homeTeam: String
    let awayTeam: String
    let competition: String
    let homeScore: Int
    let awayScore: Int
    let status: String
    let elapsedSeconds: Int
    let lastUpdated: Date
    let homeLogoPath: String?
    let awayLogoPath: String?
    let homeGoalEvents: [String]
    let awayGoalEvents: [String]
    let fixtureTimestamp: Int?
}

final class HomeWidgetSnapshotStore: Sendable {
    static let shared = HomeWidgetSnapshotStore()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let snapshotsFileName = "live_match_snapshots.json"
    private let legacyFileName = "live_match_snapshot.json"

    private init() {}

    private var containerURL: URL? {
        AppGroup.containerURL
    }

    private var snapshotsURL: URL? {
        containerURL?.appendingPathComponent(snapshotsFileName)
    }

    private var legacyURL: URL? {
        containerURL?.appendingPathComponent(legacyFileName)
    }

    func save(_ snapshot: LiveMatchWidgetSnapshot) {
        var snapshots = loadSnapshots()
        snapshots.removeAll { $0.fixtureID == snapshot.fixtureID }
        snapshots.append(snapshot)
        storeSnapshots(snapshots)
    }

    func snapshots() -> [LiveMatchWidgetSnapshot] {
        loadSnapshots()
    }

    func prune(keepingFixtureIDs fixtureIDs: Set<Int32>) {
        let snapshots = loadSnapshots().filter { fixtureIDs.contains($0.fixtureID) }
        storeSnapshots(snapshots)
    }

    func clear() {
        if let url = snapshotsURL {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = legacyURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Private helpers

    private func loadSnapshots() -> [LiveMatchWidgetSnapshot] {
        if let url = snapshotsURL,
           let data = try? Data(contentsOf: url),
           let snapshots = try? decoder.decode([LiveMatchWidgetSnapshot].self, from: data) {
            return snapshots.sorted { $0.lastUpdated > $1.lastUpdated }
        }

        if let legacyURL,
           let data = try? Data(contentsOf: legacyURL),
           let snapshot = try? decoder.decode(LiveMatchWidgetSnapshot.self, from: data) {
            return [snapshot]
        }

        return []
    }

    private func storeSnapshots(_ snapshots: [LiveMatchWidgetSnapshot]) {
        guard let url = snapshotsURL else { return }

        var ordered = snapshots.sorted { $0.lastUpdated > $1.lastUpdated }
        if ordered.count > 20 {
            ordered = Array(ordered.prefix(20))
        }

        if ordered.isEmpty {
            try? FileManager.default.removeItem(at: url)
            if let legacyURL {
                try? FileManager.default.removeItem(at: legacyURL)
            }
            return
        }

        do {
            let data = try encoder.encode(ordered)
            try data.write(to: url, options: [.atomic])
            if let legacyURL {
                try? FileManager.default.removeItem(at: legacyURL)
            }
        } catch {
            print("HomeWidgetSnapshotStore: failed to persist snapshot – \(error)")
        }
    }
}
