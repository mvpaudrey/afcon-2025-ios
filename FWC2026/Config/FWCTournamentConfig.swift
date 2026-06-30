import TournamentKit

struct FWCTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 1
    let season: Int32 = 2026
    let competitionName = "FIFA World Cup 2026"
    let groupCount = 12
    let teamCount = 48
    let accentColorName = "fifaBlue"
    let secondaryColorName = "fifaGold"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    let teamFlagMap: [Int: String] = [
        // Group A
        16: "MEX", 1531: "RSA", 17: "KOR", 770: "CZE",
        // Group B
        15: "SUI", 5529: "CAN", 1113: "BIH", 1569: "QAT",
        // Group C
        6: "BRA", 31: "MAR", 1108: "SCO", 2386: "HAI",
        // Group D
        2384: "USA", 20: "AUS", 2380: "PAR", 777: "TUR",
        // Group E
        25: "GER", 1501: "CIV", 2382: "ECU", 5530: "CUW",
        // Group F
        1118: "NED", 12: "JPN", 5: "SWE", 28: "TUN",
        // Group G
        1: "BEL", 32: "EGY", 22: "IRN", 4673: "NZL",
        // Group H
        9: "ESP", 1533: "CPV", 7: "URU", 23: "KSA",
        // Group I
        2: "FRA", 1090: "NOR", 13: "SEN", 1567: "IRQ",
        // Group J
        26: "ARG", 775: "AUT", 1532: "ALG", 1548: "JOR",
        // Group K
        8: "COL", 27: "POR", 1508: "COD", 1568: "UZB",
        // Group L
        10: "ENG", 3: "CRO", 1504: "GHA", 11: "PAN"
    ]
}
