import SwiftUI

public protocol TournamentConfig: Sendable {
    var leagueId: Int32 { get }
    var season: Int32 { get }
    var competitionName: String { get }
    var groupCount: Int { get }
    var teamCount: Int { get }
    var accentColorName: String { get }
    var secondaryColorName: String { get }
    var appGroupIdentifier: String { get }
    /// Maps API-Football team IDs to asset image names (FIFA codes, e.g. "MAR")
    var teamFlagMap: [Int: String] { get }
}

// Internal fallback — every App struct injects a concrete config before any view renders
struct DefaultTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 6
    let season: Int32 = 2025
    let competitionName = "AFCON 2025"
    let groupCount = 6
    let teamCount = 24
    let accentColorName = "moroccoGreen"
    let secondaryColorName = "moroccoRed"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    let teamFlagMap: [Int: String] = [:]
}

// MARK: - SwiftUI Environment

public struct TournamentConfigKey: EnvironmentKey {
    public static let defaultValue: any TournamentConfig = DefaultTournamentConfig()
}

public extension EnvironmentValues {
    var tournamentConfig: any TournamentConfig {
        get { self[TournamentConfigKey.self] }
        set { self[TournamentConfigKey.self] = newValue }
    }
}
