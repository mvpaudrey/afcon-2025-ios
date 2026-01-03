//
//  AFCON2025App.swift
//  AFCON2025
//
//  Created by Audrey Zebaze on 14/12/2025.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct AFCON2025App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationService = AppNotificationService.shared
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FixtureModel.self,
            FixtureEventModel.self,
            FavoriteTeam.self
        ])

        // Get app support directory
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Could not find application support directory")
        }

        // Create AFCON2025 directory if it doesn't exist
        let afconDirectoryURL = appSupportURL.appendingPathComponent("AFCON2025", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: afconDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("⚠️ Could not create directory: \(error)")
        }

        // Create model configuration with explicit URL
        let storeURL = afconDirectoryURL.appendingPathComponent("afcon2025.store")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ SwiftData initialized at: \(storeURL.path)")
            return container
        } catch {
            // Migration failed - delete old database and create fresh one
            print("⚠️ File storage failed, deleting old database: \(error)")

            // Delete the old database files
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("store-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("store-wal"))

            // Try again with fresh database
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ SwiftData initialized with fresh database at: \(storeURL.path)")
                return container
            } catch {
                // Final fallback to in-memory storage
                print("⚠️ Still failed, using in-memory storage: \(error)")
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(notificationService)
                .onAppear {
                    notificationService.setupNotificationCategories()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    // Background task identifier
    private let backgroundRefreshTaskIdentifier = "com.afcon2025.refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Setup notification categories
        AppNotificationService.shared.setupNotificationCategories()

        // Register background task for live match updates
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundRefreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        AppNotificationService.shared.setDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppNotificationService.shared.handleRegistrationError(error)
    }

    // MARK: - Background Tasks

    /// Handle background refresh task for live match updates
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("📲 Background refresh task triggered")

        // Schedule the next background refresh
        scheduleBackgroundRefresh()

        // Create a task to handle the refresh
        let refreshTask = Task {
            // Check if there are live matches
            guard LiveMatchStreamService.shared.hasLiveMatches else {
                print("ℹ️ No live matches, skipping background refresh")
                task.setTaskCompleted(success: true)
                return
            }

            // Keep the stream alive in background
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            task.setTaskCompleted(success: true)
        }

        // Handle task expiration
        task.expirationHandler = {
            print("⚠️ Background refresh task expired")
            refreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    /// Schedule a background refresh task
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshTaskIdentifier)

        // Schedule to run as soon as possible when live matches are active
        // The system will determine the best time to run
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled background refresh task")
        } catch {
            print("❌ Failed to schedule background refresh: \(error)")
        }
    }
}
