import Testing
import SwiftUI
@testable import TournamentKit

@Suite("TournamentKit")
struct TournamentKitTests {}

@Suite("TournamentConfig")
struct TournamentConfigTests {
    @Test("DefaultTournamentConfig has AFCON defaults")
    func defaultConfigHasAFCONDefaults() {
        let config = DefaultTournamentConfig()
        #expect(config.leagueId == 6)
        #expect(config.season == 2025)
        #expect(config.groupCount == 6)
        #expect(config.teamCount == 24)
        #expect(config.appGroupIdentifier == "group.com.cheulah.afcon")
    }

    @Test("TournamentConfigStore defaults to DefaultTournamentConfig")
    func storeDefaultsToAfcon() {
        #expect(TournamentConfigStore.current.leagueId == 6)
    }
}
