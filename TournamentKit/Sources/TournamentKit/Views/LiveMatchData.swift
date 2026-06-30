//
//  LiveMatchData.swift
//  TournamentKit
//

import Foundation
import Observation
import AFCONClient
import GRPC
import NIO
internal import SwiftProtobuf

public struct LiveMatchData: Identifiable {
    public let id = UUID()
    public let fixtureID: Int32
    public var homeTeamName: String
    public var awayTeamName: String
    /// Relative path (within the shared App Group) for the cached home crest.
    public var homeTeamLogoPath: String?
    /// Relative path (within the shared App Group) for the cached away crest.
    public var awayTeamLogoPath: String?
    public var homeScore: Int32
    public var awayScore: Int32
    public var status: Afcon_FixtureStatus  // Materialized status object
    public var eventType: String
    public var timestamp: Date  // When this update was received
    public var serverElapsed: Int32  // Elapsed time from server at timestamp
    public var recentEvents: [Afcon_FixtureEvent]  // Recent match events
    public var fixtureTimestamp: Int?

    public init(
        fixtureID: Int32,
        homeTeamName: String,
        awayTeamName: String,
        homeTeamLogoPath: String? = nil,
        awayTeamLogoPath: String? = nil,
        homeScore: Int32,
        awayScore: Int32,
        status: Afcon_FixtureStatus,
        eventType: String,
        timestamp: Date,
        serverElapsed: Int32,
        recentEvents: [Afcon_FixtureEvent],
        fixtureTimestamp: Int? = nil
    ) {
        self.fixtureID = fixtureID
        self.homeTeamName = homeTeamName
        self.awayTeamName = awayTeamName
        self.homeTeamLogoPath = homeTeamLogoPath
        self.awayTeamLogoPath = awayTeamLogoPath
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.status = status
        self.eventType = eventType
        self.timestamp = timestamp
        self.serverElapsed = serverElapsed
        self.recentEvents = recentEvents
        self.fixtureTimestamp = fixtureTimestamp
    }

    public var timeAgo: String {
        let seconds = Date().timeIntervalSince(timestamp)
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        }
    }

    // Convenience accessors for status
    public var statusShort: String {
        status.short
    }

    public var statusLong: String {
        status.long
    }

    public var isLive: Bool {
        let liveStatuses: Set<String> = ["LIVE", "1H", "2H", "HT", "ET", "BT", "P"]
        let short = statusShort.uppercased()
        if liveStatuses.contains(short) {
            return true
        }

        let long = statusLong.lowercased()
        if long.contains("live") ||
            long.contains("1st half") ||
            long.contains("2nd half") ||
            long.contains("extra time") ||
            long.contains("break time") ||
            long.contains("penalties") {
            return true
        }

        return eventType.lowercased() == "match_started"
    }

    public var kickoffDate: Date? {
        guard let fixtureTimestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(fixtureTimestamp))
    }

    public var isFinished: Bool {
        let finishedStatuses: Set<String> = ["FT", "AET", "PEN", "AWD", "WO", "ABD", "CANC", "SUSP"]
        let short = statusShort.uppercased()
        if finishedStatuses.contains(short) {
            return true
        }

        let long = statusLong.lowercased()
        if long.contains("match finished") ||
            long.contains("full time") ||
            long.contains("after extra time") {
            return true
        }

        return eventType.lowercased() == "match_finished"
    }

    public var isUpcoming: Bool {
        guard !isLive && !isFinished else { return false }
        guard let kickoff = kickoffDate else { return true }
        return kickoff > Date()
    }

    public var isTodayPastMatch: Bool {
        guard !isLive && !isFinished, let kickoff = kickoffDate else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(kickoff) && kickoff <= Date()
    }

    // Live elapsed time calculation
    public var elapsed: Int32 {
        // Only calculate live time if match is actually in progress
        guard status.short == "1H" || status.short == "2H" else {
            return serverElapsed
        }

        // Calculate how much time has passed since last server update
        let secondsSinceUpdate = Date().timeIntervalSince(timestamp)
        let minutesSinceUpdate = Int32(secondsSinceUpdate / 60.0)

        // Add to server elapsed time
        return serverElapsed + minutesSinceUpdate
    }
}
