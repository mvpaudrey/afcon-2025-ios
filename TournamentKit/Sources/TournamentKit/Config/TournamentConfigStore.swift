import Foundation

/// Provides the active tournament config to non-SwiftUI code (services, singletons).
/// Set once at app launch before any service is accessed.
public final class TournamentConfigStore: @unchecked Sendable {
    nonisolated(unsafe) public static var current: any TournamentConfig = DefaultTournamentConfig()
}
