import Foundation
import SwiftData
import WidgetKit
import AFCONClient
import UIKit

/// Global service that manages live match streaming in the background
/// This service continues streaming even when switching tabs
@Observable
@MainActor
public final class LiveMatchStreamService {
    public static let shared = LiveMatchStreamService()

    private let service = TournamentServiceWrapper.shared
    private var streamingTask: Task<Void, Never>?
    private var reconnectionTask: Task<Void, Never>?

    public var isStreaming: Bool {
        streamingTask != nil && !(streamingTask?.isCancelled ?? true)
    }

    public var hasLiveMatches = false
    public var lastError: String?

    // Callbacks for updating UI
    public var onMatchUpdate: ((Afcon_LiveMatchUpdate) -> Void)?
    public var onMatchStatusCheck: (() async -> Bool)?  // Callback to check if there are live matches

    // Background check timer for upcoming matches
    @MainActor private var statusCheckTimer: Timer?

    // Track if we should resume streaming when returning to foreground
    private var shouldResumeStreaming = false

    // Track if we're currently syncing data to prevent concurrent updates
    public private(set) var isSyncing = false

    private init() {
        // Private initializer for singleton
        MainActor.assumeIsolated {
            startStatusCheckTimer()
            setupLifecycleObservers()
        }
    }

    deinit {
        MainActor.assumeIsolated {
            statusCheckTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
    }

    // MARK: - Lifecycle Observers

    /// Setup observers for app lifecycle events
    private func setupLifecycleObservers() {
        // Observe when app enters background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterBackground()
            }
        }

        // Observe when app enters foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleEnterForeground()
            }
        }
    }

    /// Handle app entering background
    @MainActor
    private func handleEnterBackground() {
        print("App entering background - pausing stream")

        // Remember if we were streaming
        shouldResumeStreaming = isStreaming && hasLiveMatches

        // Stop the stream to save resources
        if isStreaming {
            stopStreaming()
        }
    }

    /// Handle app entering foreground
    @MainActor
    private func handleEnterForeground() {
        print("App entering foreground - will resume after sync completes")
        // Note: Streaming will resume after syncLiveFixtures() completes in LiveScoresViewModel
        // This prevents race conditions between sync and stream updates
    }

    /// Begin sync operation (blocks stream updates)
    @MainActor
    public func beginSync() {
        isSyncing = true
        print("Beginning sync - stream updates paused")
    }

    /// End sync operation and resume streaming if needed
    @MainActor
    public func endSyncAndResume() {
        isSyncing = false
        print("Sync complete - stream updates resumed")

        if shouldResumeStreaming {
            print("Resuming stream after sync completion...")
            Task {
                // Check if there are still live matches
                if let onMatchStatusCheck = self.onMatchStatusCheck {
                    let hasLive = await onMatchStatusCheck()
                    if hasLive {
                        self.startStreaming(hasLiveMatches: true)
                    }
                }
            }
            shouldResumeStreaming = false
        }
    }

    // MARK: - Start Streaming

    /// Start streaming live matches
    /// - Parameter hasLiveMatches: Whether there are currently live matches
    public func startStreaming(hasLiveMatches: Bool) {
        self.hasLiveMatches = hasLiveMatches

        // Don't start if already streaming
        guard !isStreaming else {
            print("Live stream already active, skipping...")
            return
        }

        // Only start if there are live matches
        guard hasLiveMatches else {
            print("No live matches, stream will start when matches go live")
            return
        }

        print("Starting global live updates stream...")
        lastError = nil

        streamingTask = Task { @MainActor in
            await streamWithReconnection()
        }
    }

    // MARK: - Stop Streaming

    /// Stop the live streaming
    public func stopStreaming() {
        print("Stopping global live updates stream...")
        streamingTask?.cancel()
        streamingTask = nil
        reconnectionTask?.cancel()
        reconnectionTask = nil
    }

    // MARK: - Update Live Matches Status

    /// Call this when live matches count changes
    public func updateLiveMatchesStatus(hasLiveMatches: Bool) {
        let wasStreaming = isStreaming
        self.hasLiveMatches = hasLiveMatches

        if hasLiveMatches && !wasStreaming {
            // Start streaming if we have live matches and aren't already streaming
            startStreaming(hasLiveMatches: true)
            // Schedule background refresh to keep updates coming
            scheduleBackgroundRefresh()
        } else if !hasLiveMatches && wasStreaming {
            // Stop streaming if no more live matches
            print("No more live matches, stopping stream...")
            stopStreaming()
        }
    }

    /// Schedule a background refresh task for live match updates
    private func scheduleBackgroundRefresh() {
        // App-specific background refresh scheduling is handled via
        // backgroundRefreshHandler if set by the app delegate.
        backgroundRefreshHandler?()
    }

    /// Optional closure to call when a background refresh should be scheduled.
    /// Set this at app launch from AppDelegate.
    public var backgroundRefreshHandler: (() -> Void)?

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
            print("Status check: Live matches detected, starting stream...")
            updateLiveMatchesStatus(hasLiveMatches: true)
        } else if !hasLive && isStreaming {
            print("Status check: No live matches, stopping stream...")
            updateLiveMatchesStatus(hasLiveMatches: false)
        }
    }

    // MARK: - Private Methods

    /// Stream with automatic reconnection on errors
    @MainActor
    private func streamWithReconnection() async {
        let serviceRef = service
        while !Task.isCancelled && hasLiveMatches {
            do {
                print("Connecting to live updates stream...")

                try await serviceRef.streamLiveMatches { [weak self] update in
                    guard let self = self else { return }

                    // Forward update to callback
                    Task { @MainActor in
                        self.onMatchUpdate?(update)
                    }
                }

                // If we get here, stream ended normally
                print("Stream ended normally")
                break

            } catch {
                // Log error
                let errorMsg = "Stream error: \(error.localizedDescription)"
                print(errorMsg)
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }

                // Don't reconnect if task was cancelled or no more live matches
                guard !Task.isCancelled && hasLiveMatches else {
                    print("Not reconnecting (cancelled or no live matches)")
                    break
                }

                // Wait before reconnecting (exponential backoff could be added here)
                print("Waiting 5 seconds before reconnecting...")
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

                guard !Task.isCancelled else { break }

                print("Attempting to reconnect...")
            }
        }

        // Clean up
        await MainActor.run {
            self.streamingTask = nil
        }
    }
}
