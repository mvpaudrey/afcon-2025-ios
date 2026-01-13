import Foundation

/// Maps team IDs to FIFA country codes for displaying team flags from Assets
struct TeamFlagMapper {
    /// Maps API-Football team IDs to their FIFA three-letter country codes
    /// These IDs are consistent across all locales (English, French, Arabic)
    private static let teamIdToFIFACode: [Int: String] = [
        // Major teams (low IDs from API-Football)
        13: "SEN",    // Senegal
        19: "NGA",    // Nigeria
        28: "TUN",    // Tunisia
        31: "MAR",    // Morocco
        32: "EGY",    // Egypt

        // Other AFCON 2025 teams (1489-1532 range)
        1489: "TAN",  // Tanzania
        1500: "MLI",  // Mali
        1501: "CIV",  // Ivory Coast
        1502: "BFA",  // Burkina Faso
        1503: "GAB",  // Gabon
        1507: "ZAM",  // Zambia
        1508: "COD",  // Congo DR
        1510: "SDN",  // Sudan
        1512: "MOZ",  // Mozambique
        1516: "BEN",  // Benin
        1519: "UGA",  // Uganda
        1520: "BOT",  // Botswana
        1521: "EQG",  // Equatorial Guinea
        1522: "ZIM",  // Zimbabwe
        1524: "COM",  // Comoros
        1529: "ANG",  // Angola
        1530: "CMR",  // Cameroon
        1531: "RSA",  // South Africa
        1532: "ALG"   // Algeria
    ]

    /// Returns the FIFA country code for a given team ID
    /// - Parameter teamId: API-Football team ID
    /// - Returns: FIFA three-letter country code (e.g., "MAR" for Morocco), or nil if not found
    static func fifaCode(for teamId: Int) -> String? {
        return teamIdToFIFACode[teamId]
    }

    /// Returns the asset name for a team's flag
    /// - Parameter teamId: API-Football team ID
    /// - Returns: Asset name for the team flag (e.g., "MAR"), or nil if not found
    static func flagAssetName(for teamId: Int) -> String? {
        return fifaCode(for: teamId)
    }
}
