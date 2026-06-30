import Foundation

/// Maps API-Football team IDs to asset image names.
/// Reads the active tournament's map from TournamentConfigStore so all existing
/// static call sites (TeamFlagMapper.flagAssetName(for:)) require no changes.
public struct TeamFlagMapper {
    public static func flagAssetName(for teamId: Int) -> String? {
        TournamentConfigStore.current.teamFlagMap[teamId]
    }

    public static func fifaCode(for teamId: Int) -> String? {
        TournamentConfigStore.current.teamFlagMap[teamId]
    }
}
