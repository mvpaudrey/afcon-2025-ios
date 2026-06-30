import Foundation

/// Called at app launch to write the active tournament config into the shared
/// AppGroup UserDefaults, so the widget can read it without knowing the target.
public func writeTournamentConfigToAppGroup(_ config: any TournamentConfig) {
    guard let defaults = UserDefaults(suiteName: config.appGroupIdentifier) else { return }
    defaults.set(Int(config.leagueId),  forKey: "tournamentLeagueId")
    defaults.set(Int(config.season),    forKey: "tournamentSeason")
    defaults.set(config.competitionName, forKey: "tournamentName")
    defaults.set(config.groupCount,     forKey: "tournamentGroupCount")
}
