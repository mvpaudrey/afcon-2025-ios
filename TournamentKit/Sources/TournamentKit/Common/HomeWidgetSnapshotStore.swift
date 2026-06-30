import Foundation

// Note: LiveMatchWidgetSnapshot is defined in TournamentKit/Models/LiveMatchWidgetSnapshot.swift
// which is shared between the main app and widget extension

public final class HomeWidgetSnapshotStore: Sendable {
    public static let shared = HomeWidgetSnapshotStore()

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

    public func save(_ snapshot: LiveMatchWidgetSnapshot) {
        print("🟢 HomeWidgetSnapshotStore - Saving snapshot for fixture \(snapshot.fixtureID): \(snapshot.homeTeam) vs \(snapshot.awayTeam)")
        print("🟢 HomeWidgetSnapshotStore - Container URL: \(containerURL?.path ?? "nil")")
        var snapshots = loadSnapshots()
        snapshots.removeAll { $0.fixtureID == snapshot.fixtureID }
        snapshots.append(snapshot)
        storeSnapshots(snapshots)
        print("🟢 HomeWidgetSnapshotStore - Total snapshots after save: \(snapshots.count)")
    }

    public func snapshots() -> [LiveMatchWidgetSnapshot] {
        loadSnapshots()
    }

    public func prune(keepingFixtureIDs fixtureIDs: Set<Int32>) {
        let snapshots = loadSnapshots().filter { fixtureIDs.contains($0.fixtureID) }
        storeSnapshots(snapshots)
    }

    public func clear() {
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
        guard let url = snapshotsURL else {
            print("❌ HomeWidgetSnapshotStore - No snapshots URL available")
            return
        }

        var ordered = snapshots.sorted { $0.lastUpdated > $1.lastUpdated }
        if ordered.count > 20 {
            ordered = Array(ordered.prefix(20))
        }

        if ordered.isEmpty {
            print("🟢 HomeWidgetSnapshotStore - No snapshots to store, removing file")
            try? FileManager.default.removeItem(at: url)
            if let legacyURL {
                try? FileManager.default.removeItem(at: legacyURL)
            }
            return
        }

        do {
            let data = try encoder.encode(ordered)
            print("🟢 HomeWidgetSnapshotStore - Encoded \(ordered.count) snapshots (\(data.count) bytes)")
            try data.write(to: url, options: [.atomic])
            print("🟢 HomeWidgetSnapshotStore - Successfully wrote to: \(url.path)")

            // Verify file was written
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            print("🟢 HomeWidgetSnapshotStore - File exists after write: \(fileExists)")

            if let legacyURL {
                try? FileManager.default.removeItem(at: legacyURL)
            }
        } catch {
            print("❌ HomeWidgetSnapshotStore: failed to persist snapshot – \(error)")
        }
    }
}
