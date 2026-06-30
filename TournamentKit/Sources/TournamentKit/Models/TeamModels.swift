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

    public static func team(for id: Int) -> NationalTeam? {
        sampleTeams.first { $0.id == id }
    }

    public var localizedName: String {
        NSLocalizedString(name, comment: "")
    }
}
