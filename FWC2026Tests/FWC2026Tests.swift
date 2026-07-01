//
//  FWC2026Tests.swift
//  FWC2026Tests
//
//  Created by Audrey Zebaze on 25/06/2026.
//

import Testing
@testable import FWC2026

struct FWCBracketTypesTests {

    @Test func bracketRoundAllCasesCount() {
        #expect(FWCBracketRound.allCases.count == 5)
    }

    @Test func bracketRoundOrder() {
        let cases = FWCBracketRound.allCases
        #expect(cases[0] == .roundOf32)
        #expect(cases[1] == .roundOf16)
        #expect(cases[2] == .quarterFinals)
        #expect(cases[3] == .semiFinals)
        #expect(cases[4] == .final)
    }

    @Test func bracketMatchInitializes() {
        let m = FWCBracketMatch(
            id: 1, date: "2026-07-04", time: "18:00",
            team1: "France", team2: "Maroc",
            team1Id: 2, team2Id: 31,
            venue: "MetLife Stadium",
            score1: nil, score2: nil
        )
        #expect(m.id == 1)
        #expect(m.team1 == "France")
        #expect(m.penalty1 == nil)
    }
}
