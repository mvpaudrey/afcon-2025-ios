//
//  AFCON2025App.swift
//  AFCON2025
//
//  Created by Audrey Zebaze on 14/12/2025.
//

import SwiftUI
import SwiftData

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
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Setup notification categories
        AppNotificationService.shared.setupNotificationCategories()
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
}
