//
//  LiveMatchData.swift
//  AFCON2025
//
//  Created by Audrey Zebaze on 14/12/2025.
//

import Foundation
import Observation
import AFCONClient
import GRPC
import NIO
internal import SwiftProtobuf

struct LiveMatchData: Identifiable {
    let id = UUID()
    let fixtureID: Int32
    var homeTeamName: String
    var awayTeamName: String
    /// Relative path (within the shared App Group) for the cached home crest.
    var homeTeamLogoPath: String?
    /// Relative path (within the shared App Group) for the cached away crest.
    var awayTeamLogoPath: String?
    var homeScore: Int32
    var awayScore: Int32
    var status: Afcon_FixtureStatus  // Materialized status object
    var eventType: String
    var timestamp: Date  // When this update was received
    var serverElapsed: Int32  // Elapsed time from server at timestamp
    var recentEvents: [Afcon_FixtureEvent]  // Recent match events
    var fixtureTimestamp: Int?

    var timeAgo: String {
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
    var statusShort: String {
        status.short
    }

    var statusLong: String {
        status.long
    }

    var isLive: Bool {
        let liveStatuses: Set<String> = ["LIVE", "1H", "2H", "HT", "ET", "P"]
        let short = statusShort.uppercased()
        if liveStatuses.contains(short) {
            return true
        }

        let long = statusLong.lowercased()
        if long.contains("live") ||
            long.contains("1st half") ||
            long.contains("2nd half") ||
            long.contains("extra time") ||
            long.contains("penalties") {
            return true
        }

        return eventType.lowercased() == "match_started"
    }

    var kickoffDate: Date? {
        guard let fixtureTimestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(fixtureTimestamp))
    }

    var isFinished: Bool {
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

    var isUpcoming: Bool {
        guard !isLive && !isFinished else { return false }
        guard let kickoff = kickoffDate else { return true }
        return kickoff > Date()
    }

    var isTodayPastMatch: Bool {
        guard !isLive && !isFinished, let kickoff = kickoffDate else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(kickoff) && kickoff <= Date()
    }

    // Live elapsed time calculation
    var elapsed: Int32 {
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
