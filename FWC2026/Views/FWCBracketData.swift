import Foundation

struct FWCBracketData {

    // Full schedule with bracket-ordered R32 (pairs 0+1, 2+3, … feed into same R16 slot)
    // and approximate dates for R16–Final. Times in CEST (UTC+2, summer Europe).
    static let allMatches = FWCBracketMatches(
        roundOf32: [
            // Pair → R16[0]
            FWCBracketMatch(id: 67, date: "2026-06-29", time: "22:30", team1: "1E", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 70, date: "2026-06-30", time: "23:00", team1: "1I", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[1]
            FWCBracketMatch(id: 65, date: "2026-06-28", time: "21:00", team1: "2A", team2: "2B", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 68, date: "2026-06-30", time: "03:00", team1: "1F", team2: "2C", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[2]
            FWCBracketMatch(id: 76, date: "2026-07-03", time: "01:00", team1: "2K", team2: "2L", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 75, date: "2026-07-02", time: "21:00", team1: "1H", team2: "2J", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[3]
            FWCBracketMatch(id: 74, date: "2026-07-02", time: "02:00", team1: "1D", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 73, date: "2026-07-01", time: "22:00", team1: "1G", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[4]
            FWCBracketMatch(id: 66, date: "2026-06-29", time: "19:00", team1: "1C", team2: "2F", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 69, date: "2026-06-30", time: "19:00", team1: "2E", team2: "2I", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[5]
            FWCBracketMatch(id: 71, date: "2026-07-01", time: "03:00", team1: "1A", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 72, date: "2026-07-01", time: "18:00", team1: "1L", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[6]
            FWCBracketMatch(id: 79, date: "2026-07-04", time: "00:00", team1: "1J", team2: "2H", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 77, date: "2026-07-03", time: "05:00", team1: "1B", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            // Pair → R16[7]
            FWCBracketMatch(id: 78, date: "2026-07-03", time: "20:00", team1: "2D", team2: "2G", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 80, date: "2026-07-04", time: "03:30", team1: "1K", team2: "3e", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
        ],
        roundOf16: [
            // R16[0] — Paraguay vs France [Jul 04 23:00]
            FWCBracketMatch(id: 81, date: "2026-07-04", time: "23:00", team1: "Paraguay", team2: "France", team1Id: 2380, team2Id: 2, venue: "", score1: 0, score2: 1),
            // R16[1] — Canada vs Morocco [Jul 04 19:00]
            FWCBracketMatch(id: 82, date: "2026-07-04", time: "19:00", team1: "Canada", team2: "Morocco", team1Id: 5529, team2Id: 31, venue: "", score1: 0, score2: 3),
            // R16[2] — Portugal vs Spain [Jul 06 21:00]
            FWCBracketMatch(id: 83, date: "2026-07-06", time: "21:00", team1: "Portugal", team2: "Spain", team1Id: 27, team2Id: 9, venue: "", score1: nil, score2: nil),
            // R16[3] — United States vs Belgium [Jul 07 02:00]
            FWCBracketMatch(id: 84, date: "2026-07-07", time: "02:00", team1: "United States", team2: "Belgium", team1Id: 2384, team2Id: 1, venue: "", score1: nil, score2: nil),
            // R16[4] — Brazil vs Norway [Jul 05 22:00]
            FWCBracketMatch(id: 85, date: "2026-07-05", time: "22:00", team1: "Brazil", team2: "Norway", team1Id: 6, team2Id: 1090, venue: "", score1: nil, score2: nil),
            // R16[5] — Mexico vs England [Jul 06 02:00]
            FWCBracketMatch(id: 86, date: "2026-07-06", time: "02:00", team1: "Mexico", team2: "England", team1Id: 16, team2Id: 10, venue: "", score1: nil, score2: nil),
            // R16[6] — Argentina vs Egypt [Jul 07 18:00]
            FWCBracketMatch(id: 87, date: "2026-07-07", time: "18:00", team1: "Argentina", team2: "Egypt", team1Id: 26, team2Id: 32, venue: "", score1: nil, score2: nil),
            // R16[7] — Switzerland vs Colombia [Jul 07 22:00]
            FWCBracketMatch(id: 88, date: "2026-07-07", time: "22:00", team1: "Switzerland", team2: "Colombia", team1Id: 15, team2Id: 8, venue: "", score1: nil, score2: nil),
        ],
        quarterFinals: [
            // QF[0] — France vs Morocco [Jul 09 22:00]
            FWCBracketMatch(id: 89, date: "2026-07-09", time: "22:00", team1: "France", team2: "Morocco", team1Id: 2, team2Id: 31, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 90, date: "2026-07-10", time: "21:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 91, date: "2026-07-11", time: "23:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 92, date: "2026-07-12", time: "03:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
        ],
        semiFinals: [
            FWCBracketMatch(id: 93, date: "2026-07-14", time: "21:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
            FWCBracketMatch(id: 94, date: "2026-07-15", time: "21:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
        ],
        final: FWCBracketMatch(id: 95, date: "2026-07-19", time: "21:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil),
        thirdPlace: FWCBracketMatch(id: 96, date: "2026-07-16", time: "21:00", team1: "TBD", team2: "TBD", team1Id: nil, team2Id: nil, venue: "", score1: nil, score2: nil)
    )

    static let placeholderMatches = FWCBracketMatches(
        roundOf32:     (65...80).map { placeholder(id: $0) },
        roundOf16:     (81...88).map { placeholder(id: $0) },
        quarterFinals: (89...92).map { placeholder(id: $0) },
        semiFinals:    (93...94).map { placeholder(id: $0) },
        final:         placeholder(id: 95),
        thirdPlace:    placeholder(id: 96)
    )

    static func placeholder(id: Int) -> FWCBracketMatch {
        FWCBracketMatch(
            id: id,
            date: "",
            time: "",
            team1: "TBD",
            team2: "TBD",
            team1Id: nil,
            team2Id: nil,
            venue: "",
            score1: nil,
            score2: nil
        )
    }
}
