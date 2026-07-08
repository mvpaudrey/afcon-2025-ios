import Foundation

struct WidgetTournamentConfig {
    let leagueId: Int32
    let season: Int32
    let competitionName: String
    let groupCount: Int
    let accentColorName: String
    let secondaryColorName: String
}

func loadWidgetTournamentConfig() -> WidgetTournamentConfig {
    let defaults = UserDefaults(suiteName: "group.com.cheulah.afcon")
    return WidgetTournamentConfig(
        leagueId: Int32(defaults?.integer(forKey: "tournamentLeagueId") ?? 6),
        season: Int32(defaults?.integer(forKey: "tournamentSeason") ?? 2025),
        competitionName: defaults?.string(forKey: "tournamentName") ?? "AFCON 2025",
        groupCount: defaults?.integer(forKey: "tournamentGroupCount") ?? 6,
        accentColorName: defaults?.string(forKey: "tournamentAccentColor") ?? "moroccoRed",
        secondaryColorName: defaults?.string(forKey: "tournamentSecondaryColor") ?? "moroccoGreen"
    )
}
