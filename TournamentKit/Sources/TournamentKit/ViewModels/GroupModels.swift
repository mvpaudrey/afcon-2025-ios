import Foundation

// MARK: - Group Stage Data Models

public struct Group {
    public let name: String
    public let teams: [Team]

    public init(name: String, teams: [Team]) {
        self.name = name
        self.teams = teams
    }
}

public struct Team {
    public let name: String
    public let teamId: Int
    public let played: Int
    public let won: Int
    public let drawn: Int
    public let lost: Int
    public let gf: Int
    public let ga: Int
    public let points: Int
    public let position: Int
    public let groupName: String?

    public init(
        name: String,
        teamId: Int,
        played: Int,
        won: Int,
        drawn: Int,
        lost: Int,
        gf: Int,
        ga: Int,
        points: Int,
        position: Int,
        groupName: String?
    ) {
        self.name = name
        self.teamId = teamId
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.gf = gf
        self.ga = ga
        self.points = points
        self.position = position
        self.groupName = groupName
    }
}
