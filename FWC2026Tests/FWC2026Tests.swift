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

struct FWCBracketDataTests {

    @Test func roundOf32HasSixteenMatches() {
        #expect(FWCBracketData.placeholderMatches.roundOf32.count == 16)
    }

    @Test func roundOf16HasEightMatches() {
        #expect(FWCBracketData.placeholderMatches.roundOf16.count == 8)
    }

    @Test func quarterFinalsHasFourMatches() {
        #expect(FWCBracketData.placeholderMatches.quarterFinals.count == 4)
    }

    @Test func semiFinalsHasTwoMatches() {
        #expect(FWCBracketData.placeholderMatches.semiFinals.count == 2)
    }

    @Test func allMatchIdsAreUnique() {
        let m = FWCBracketData.placeholderMatches
        let allIds = m.roundOf32.map(\.id)
            + m.roundOf16.map(\.id)
            + m.quarterFinals.map(\.id)
            + m.semiFinals.map(\.id)
            + [m.final.id, m.thirdPlace.id]
        #expect(Set(allIds).count == allIds.count)
    }
}

struct FWCBracketViewModelTests {

    @Test func defaultSelectedRoundIsR32() {
        let vm = FWCBracketViewModel()
        #expect(vm.selectedRound == .roundOf32)
    }

    @Test func placeholderMatchesLoadedByDefault() {
        let vm = FWCBracketViewModel()
        #expect(vm.bracketMatches != nil)
        #expect(vm.bracketMatches?.roundOf32.count == 16)
    }

    @Test func determineCurrentRoundBeforeTournamentIsR32() {
        // Valide tant que la date du jour est avant le 2026-07-04.
        let vm = FWCBracketViewModel()
        #expect(vm.determineCurrentRound() == .roundOf32)
    }
}
