import TournamentKit

/// Demo competition. Change the league here for each talk; everything else follows.
/// The server must be started locally with the same league (see swift-server-playground/talk/DEMO.md).
struct DemoTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 1
    let season: Int32 = 2026
    let competitionName = "Demo"
    let groupCount = 12
    let teamCount = 48
    let accentColorName = "AccentColor"
    let secondaryColorName = "AccentColor"
    let appGroupIdentifier = "group.com.cheulah.demo"
    let teamFlagMap: [Int: String] = [:]
}
