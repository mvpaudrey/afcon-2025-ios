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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FixtureModel.self
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
            // Fallback to in-memory storage
            print("⚠️ File storage failed, using in-memory: \(error)")
            let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
