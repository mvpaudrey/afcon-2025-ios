//
//  AFCONApp.swift
//  AFCONiOSApp
//
//  Main entry point for AFCON 2025 iOS app
//

import SwiftUI
import SwiftData

/// Legacy launcher kept for compatibility. The active entry point is `AFCON2025App`.
struct AFCONApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([FixtureModel.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
