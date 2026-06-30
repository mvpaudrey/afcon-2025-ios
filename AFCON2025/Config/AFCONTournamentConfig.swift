import TournamentKit

struct AFCONTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 6
    let season: Int32 = 2025
    let competitionName = "AFCON 2025"
    let groupCount = 6
    let teamCount = 24
    // moroccoRed is the primary/accent color (header gradient start, tints)
    // moroccoGreen is the secondary color (gradient end)
    let accentColorName = "moroccoRed"
    let secondaryColorName = "moroccoGreen"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    let teamFlagMap: [Int: String] = [
        13: "SEN", 19: "NGA", 28: "TUN", 31: "MAR", 32: "EGY",
        1489: "TAN", 1500: "MLI", 1501: "CIV", 1502: "BFA", 1503: "GAB",
        1507: "ZAM", 1508: "COD", 1510: "SDN", 1512: "MOZ", 1516: "BEN",
        1519: "UGA", 1520: "BOT", 1521: "EQG", 1522: "ZIM", 1524: "COM",
        1529: "ANG", 1530: "CMR", 1531: "RSA", 1532: "ALG"
    ]
}
