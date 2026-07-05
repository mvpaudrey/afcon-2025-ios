import Foundation
import SwiftData
import SwiftUI

@Model public final class FavoriteTeam {
    public var teamId: Int

    public init(teamId: Int) {
        self.teamId = teamId
    }

    @MainActor public var name: String {
        NationalTeam.team(for: teamId)?.localizedName ?? ""
    }

    @MainActor public var logoName: String {
        NationalTeam.team(for: teamId)?.assetName ?? ""
    }
}

public struct NationalTeam: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let assetName: String

    public init(id: Int, name: String, assetName: String) {
        self.id = id
        self.name = name
        self.assetName = assetName
    }

    public static let sampleTeams: [NationalTeam] = [
        // Group A - Using API-Football team IDs
        .init(id: 31, name: "Morocco", assetName: "MAR"),
        .init(id: 1500, name: "Mali", assetName: "MLI"),
        .init(id: 1507, name: "Zambia", assetName: "ZAM"),
        .init(id: 1524, name: "Comoros", assetName: "COM"),

        // Group B
        .init(id: 32, name: "Egypt", assetName: "EGY"),
        .init(id: 1531, name: "South Africa", assetName: "RSA"),
        .init(id: 1522, name: "Zimbabwe", assetName: "ZIM"),
        .init(id: 1529, name: "Angola", assetName: "ANG"),

        // Group C
        .init(id: 19, name: "Nigeria", assetName: "NGA"),
        .init(id: 28, name: "Tunisia", assetName: "TUN"),
        .init(id: 1489, name: "Tanzania", assetName: "TAN"),
        .init(id: 1519, name: "Uganda", assetName: "UGA"),

        // Group D
        .init(id: 13, name: "Senegal", assetName: "SEN"),
        .init(id: 1508, name: "DR Congo", assetName: "COD"),
        .init(id: 1516, name: "Benin", assetName: "BEN"),
        .init(id: 1520, name: "Botswana", assetName: "BOT"),

        // Group E
        .init(id: 1532, name: "Algeria", assetName: "ALG"),
        .init(id: 1502, name: "Burkina Faso", assetName: "BFA"),
        .init(id: 1521, name: "Equatorial Guinea", assetName: "EQG"),
        .init(id: 1510, name: "Sudan", assetName: "SDN"),

        // Group F
        .init(id: 1501, name: "Ivory Coast", assetName: "CIV"),
        .init(id: 1530, name: "Cameroon", assetName: "CMR"),
        .init(id: 1503, name: "Gabon", assetName: "GAB"),
        .init(id: 1512, name: "Mozambique", assetName: "MOZ")
    ]

    public static let worldCupTeams: [NationalTeam] = [
        // Group A
        .init(id: 16, name: "Mexico", assetName: "MEX"),
        .init(id: 1531, name: "South Africa", assetName: "RSA"),
        .init(id: 17, name: "South Korea", assetName: "KOR"),
        .init(id: 770, name: "Czech Republic", assetName: "CZE"),
        // Group B
        .init(id: 15, name: "Switzerland", assetName: "SUI"),
        .init(id: 5529, name: "Canada", assetName: "CAN"),
        .init(id: 1113, name: "Bosnia & Herzegovina", assetName: "BIH"),
        .init(id: 1569, name: "Qatar", assetName: "QAT"),
        // Group C
        .init(id: 6, name: "Brazil", assetName: "BRA"),
        .init(id: 31, name: "Morocco", assetName: "MAR"),
        .init(id: 1108, name: "Scotland", assetName: "SCO"),
        .init(id: 2386, name: "Haiti", assetName: "HAI"),
        // Group D
        .init(id: 2384, name: "United States", assetName: "USA"),
        .init(id: 20, name: "Australia", assetName: "AUS"),
        .init(id: 2380, name: "Paraguay", assetName: "PAR"),
        .init(id: 777, name: "Turkey", assetName: "TUR"),
        // Group E
        .init(id: 25, name: "Germany", assetName: "GER"),
        .init(id: 1501, name: "Ivory Coast", assetName: "CIV"),
        .init(id: 2382, name: "Ecuador", assetName: "ECU"),
        .init(id: 5530, name: "Curacao", assetName: "CUW"),
        // Group F
        .init(id: 1118, name: "Netherlands", assetName: "NED"),
        .init(id: 12, name: "Japan", assetName: "JPN"),
        .init(id: 5, name: "Sweden", assetName: "SWE"),
        .init(id: 28, name: "Tunisia", assetName: "TUN"),
        // Group G
        .init(id: 1, name: "Belgium", assetName: "BEL"),
        .init(id: 32, name: "Egypt", assetName: "EGY"),
        .init(id: 22, name: "Iran", assetName: "IRN"),
        .init(id: 4673, name: "New Zealand", assetName: "NZL"),
        // Group H
        .init(id: 9, name: "Spain", assetName: "ESP"),
        .init(id: 1533, name: "Cape Verde", assetName: "CPV"),
        .init(id: 7, name: "Uruguay", assetName: "URU"),
        .init(id: 23, name: "Saudi Arabia", assetName: "KSA"),
        // Group I
        .init(id: 2, name: "France", assetName: "FRA"),
        .init(id: 1090, name: "Norway", assetName: "NOR"),
        .init(id: 13, name: "Senegal", assetName: "SEN"),
        .init(id: 1567, name: "Iraq", assetName: "IRQ"),
        // Group J
        .init(id: 26, name: "Argentina", assetName: "ARG"),
        .init(id: 775, name: "Austria", assetName: "AUT"),
        .init(id: 1532, name: "Algeria", assetName: "ALG"),
        .init(id: 1548, name: "Jordan", assetName: "JOR"),
        // Group K
        .init(id: 8, name: "Colombia", assetName: "COL"),
        .init(id: 27, name: "Portugal", assetName: "POR"),
        .init(id: 1508, name: "DR Congo", assetName: "COD"),
        .init(id: 1568, name: "Uzbekistan", assetName: "UZB"),
        // Group L
        .init(id: 10, name: "England", assetName: "ENG"),
        .init(id: 3, name: "Croatia", assetName: "CRO"),
        .init(id: 1504, name: "Ghana", assetName: "GHA"),
        .init(id: 11, name: "Panama", assetName: "PAN")
    ]

    public static func team(for id: Int) -> NationalTeam? {
        (sampleTeams + worldCupTeams).first { $0.id == id }
    }

    public var localizedName: String {
        NSLocalizedString(name, comment: "")
    }
}
