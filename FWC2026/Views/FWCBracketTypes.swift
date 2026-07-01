import Foundation

// MARK: - Round

enum FWCBracketRound: String, CaseIterable {
    case roundOf32     = "Seizièmes"
    case roundOf16     = "Huitièmes"
    case quarterFinals = "Quarts"
    case semiFinals    = "Demi-finales"
    case final         = "Finale"
}

// MARK: - Match

struct FWCBracketMatch: Sendable {
    let id: Int
    let date: String
    let time: String
    let team1: String
    let team2: String
    let team1Id: Int?
    let team2Id: Int?
    let venue: String
    let score1: Int?
    let score2: Int?
    var penalty1: Int? = nil
    var penalty2: Int? = nil
}

// MARK: - Container

struct FWCBracketMatches: Sendable {
    let roundOf32:     [FWCBracketMatch]
    let roundOf16:     [FWCBracketMatch]
    let quarterFinals: [FWCBracketMatch]
    let semiFinals:    [FWCBracketMatch]
    let final:          FWCBracketMatch
    let thirdPlace:     FWCBracketMatch
}
