import Foundation
import SwiftData
import WidgetKit
import AFCONClient
import UIKit

/// Global service that manages live match streaming in the background
/// This service continues streaming even when switching tabs
@Observable
@MainActor
final class LiveMatchStreamService {
    static let shared = LiveMatchStreamService()

    private let service = AFCONServiceWrapper.shared
    private var streamingTask: Task<Void, Never>?
    private var reconnectionTask: Task<Void, Never>?

    var isStreaming: Bool {
        streamingTask != nil && !(streamingTask?.isCancelled ?? true)
    }

    var hasLiveMatches = false
    var lastError: String?

    // Callbacks for updating UI
    var onMatchUpdate: ((Afcon_LiveMatchUpdate) -> Void)?
    var onMatchStatusCheck: (() async -> Bool)?  // Callback to check if there are live matches

    // Background check timer for upcoming matches
    @MainActor private var statusCheckTimer: Timer?

    private init() {
        // Private initializer for singleton
        MainActor.assumeIsolated { startStatusCheckTimer() }
    }

    deinit {
        MainActor.assumeIsolated { statusCheckTimer?.invalidate() }
    }

    // MARK: - Start Streaming

    /// Start streaming live matches
    /// - Parameter hasLiveMatches: Whether there are currently live matches
    func startStreaming(hasLiveMatches: Bool) {
        self.hasLiveMatches = hasLiveMatches

        // Don't start if already streaming
        guard !isStreaming else {
            print("⏭️ Live stream already active, skipping...")
            return
        }

        // Only start if there are live matches
        guard hasLiveMatches else {
            print("ℹ️ No live matches, stream will start when matches go live")
            return
        }

        print("🚀 Starting global live updates stream...")
        lastError = nil

        streamingTask = Task {
            await streamWithReconnection()
        }
    }

    // MARK: - Stop Streaming

    /// Stop the live streaming
    func stopStreaming() {
        print("🛑 Stopping global live updates stream...")
        streamingTask?.cancel()
        streamingTask = nil
        reconnectionTask?.cancel()
        reconnectionTask = nil
    }

    // MARK: - Update Live Matches Status

    /// Call this when live matches count changes
    func updateLiveMatchesStatus(hasLiveMatches: Bool) {
        let wasStreaming = isStreaming
        self.hasLiveMatches = hasLiveMatches

        if hasLiveMatches && !wasStreaming {
            // Start streaming if we have live matches and aren't already streaming
            startStreaming(hasLiveMatches: true)
            // Schedule background refresh to keep updates coming
            scheduleBackgroundRefresh()
        } else if !hasLiveMatches && wasStreaming {
            // Stop streaming if no more live matches
            print("ℹ️ No more live matches, stopping stream...")
            stopStreaming()
        }
    }

    /// Schedule a background refresh task for live match updates
    private func scheduleBackgroundRefresh() {
        // Get the app delegate to schedule the background task
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleBackgroundRefresh()
        }
    }

    // MARK: - Status Check Timer

    /// Start a timer that periodically checks if there are live matches
    /// This allows the stream to restart automatically when a match goes live
    private func startStatusCheckTimer() {
        // Check every 30 seconds if there are live matches
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForLiveMatches()
            }
        }
    }

    /// Check if there are live matches and start stream if needed
    @MainActor
    private func checkForLiveMatches() async {
        // Ask the callback if there are live matches
        guard let onMatchStatusCheck = onMatchStatusCheck else { return }

        let hasLive = await onMatchStatusCheck()

        if hasLive && !isStreaming {
            print("🔔 Status check: Live matches detected, starting stream...")
            updateLiveMatchesStatus(hasLiveMatches: true)
        } else if !hasLive && isStreaming {
            print("🔔 Status check: No live matches, stopping stream...")
            updateLiveMatchesStatus(hasLiveMatches: false)
        }
    }

    // MARK: - Private Methods

    /// Stream with automatic reconnection on errors
    private func streamWithReconnection() async {
        while !Task.isCancelled && hasLiveMatches {
            do {
                print("📡 Connecting to live updates stream...")

                try await service.streamLiveMatches { [weak self] update in
                    guard let self = self else { return }

                    // Forward update to callback
                    Task { @MainActor in
                        self.onMatchUpdate?(update)
                    }
                }

                // If we get here, stream ended normally
                print("ℹ️ Stream ended normally")
                break

            } catch {
                // Log error
                let errorMsg = "❌ Stream error: \(error.localizedDescription)"
                print(errorMsg)
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }

                // Don't reconnect if task was cancelled or no more live matches
                guard !Task.isCancelled && hasLiveMatches else {
                    print("ℹ️ Not reconnecting (cancelled or no live matches)")
                    break
                }

                // Wait before reconnecting (exponential backoff could be added here)
                print("⏳ Waiting 5 seconds before reconnecting...")
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                guard !Task.isCancelled else { break }

                print("🔄 Attempting to reconnect...")
            }
        }

        // Clean up
        await MainActor.run {
            self.streamingTask = nil
        }
    }
}
