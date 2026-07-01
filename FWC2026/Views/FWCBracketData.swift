import Foundation

struct FWCBracketData {

    static let placeholderMatches = FWCBracketMatches(
        roundOf32:     (65...80).map { placeholder(id: $0) },
        roundOf16:     (81...88).map { placeholder(id: $0) },
        quarterFinals: (89...92).map { placeholder(id: $0) },
        semiFinals:    (93...94).map { placeholder(id: $0) },
        final:         placeholder(id: 95),
        thirdPlace:    placeholder(id: 96)
    )

    private static func placeholder(id: Int) -> FWCBracketMatch {
        FWCBracketMatch(
            id: id,
            date: "",
            time: "",
            team1: "TBD",
            team2: "TBD",
            team1Id: nil,
            team2Id: nil,
            venue: "TBD",
            score1: nil,
            score2: nil
        )
    }
}
