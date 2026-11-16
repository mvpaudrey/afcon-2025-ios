import Foundation
import TournamentKit

/// Demo competition: only the league and the season matter, everything else is neutral.
/// Defaults to the Champions League; override per run with AFCON_DEMO_LEAGUE_ID / AFCON_DEMO_SEASON
/// (scheme environment variables). The local server must use the same pair as its
/// DEMO_LEAGUE_ID / DEMO_SEASON (see swift-server-playground/talk/DEMO.md).
struct DemoTournamentConfig: TournamentConfig {
    let leagueId: Int32
    let season: Int32
    let competitionName = "Demo"
    let groupCount = 0
    let teamCount = 0
    let accentColorName = "AccentColor"
    let secondaryColorName = "AccentColor"
    let appGroupIdentifier = "group.com.cheulah.demo"
    let teamFlagMap: [Int: String] = [:]

    init() {
        let env = ProcessInfo.processInfo.environment
        leagueId = Int32(env["AFCON_DEMO_LEAGUE_ID"] ?? "") ?? 2
        season = Int32(env["AFCON_DEMO_SEASON"] ?? "") ?? 2026
    }
}
