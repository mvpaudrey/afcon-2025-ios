import TournamentKit

/// Conference-talk demo tournament: FIFA U-20 Women's World Cup 2026 (API-Football league 920).
///
/// Season 2026 runs 2026-09-05 → 2026-09-13, so there are real live matches to stream
/// during the talk. Point the app at the local demo server by setting `AFCON_API_HOST` /
/// `AFCON_API_PORT` in the run scheme (see talk/DEMO.md).
///
/// Reuses the FWC2026 target's assets (fifaBlue / fifaGold) and `FWCViewFactory`.
/// Nothing here touches the AFCON 2025 or FIFA World Cup 2026 configs.
struct U20WWCTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 920
    let season: Int32 = 2026
    let competitionName = "U-20 Women's World Cup"
    let groupCount = 6
    let teamCount = 24
    let accentColorName = "fifaBlue"
    let secondaryColorName = "fifaGold"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    var availableTeams: [NationalTeam] { NationalTeam.u20WomensWorldCupTeams }
    // U-20 squads have their own API-Football team IDs (distinct from senior sides).
    // All 24 nations mapped. Flags sourced as SVGs in FWC2026/Assets.xcassets/Teams:
    // TAN/BEN/NGA copied from the AFCON2025 catalog; POL/CHN/CRC/ITA/PRK/NCL hand-authored.
    let teamFlagMap: [Int: String] = [
        23457: "ARG",  // Argentina U20 W
        28364: "BEN",  // Benin U20 W
        19079: "BRA",  // Brazil U20 W
        19080: "CAN",  // Canada U20 W
        23209: "CHN",  // China PR U20 W
        19081: "COL",  // Colombia U20 W
        19082: "CRC",  // Costa Rica U20 W
        23460: "ECU",  // Ecuador U20 W
        27219: "ENG",  // England U20 W
        19083: "FRA",  // France U20 W
        19085: "GHA",  // Ghana U20 W
        28365: "ITA",  // Italy U20 W
        19086: "JPN",  // Japan U20 W
        23206: "PRK",  // Korea DPR U20 W
        19087: "KOR",  // Korea Republic U20 W
        19088: "MEX",  // Mexico U20 W
        28366: "NCL",  // New Caledonia U20 W
        19089: "NZL",  // New Zealand U20 W
        19090: "NGA",  // Nigeria U20 W
        28367: "POL",  // Poland U20 W
        28368: "POR",  // Portugal U20 W
        19078: "ESP",  // Spain U20 W
        28369: "TAN",  // Tanzania U20 W
        19091: "USA",  // United States U20 W
    ]
}
