import SwiftUI
import SwiftData
import TournamentKit

@main
struct DemoApp: App {
    // Declared first on purpose: stored properties initialize in order, so the server is pinned
    // to the local machine before AppNotificationService or any other service can read the host.
    private let serverSetup: Void = DemoServer.configure()

    @StateObject private var notificationService = AppNotificationService.shared

    private let tournamentConfig = DemoTournamentConfig()

    // In memory: every launch starts from the server's data, never from a previous league's cache.
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([FixtureModel.self, FixtureEventModel.self, FavoriteTeam.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        TournamentConfigStore.current = DemoTournamentConfig()
    }

    var body: some Scene {
        WindowGroup {
            AppView(factory: DemoViewFactory())
                .environment(\.tournamentConfig, tournamentConfig)
                .environmentObject(notificationService)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// The demo build talks to a local server, never to production.
enum DemoServer {
    static func configure() {
        let env = ProcessInfo.processInfo.environment
        // AFCON_API_HOST stays useful to reach the Mac from a physical device (use its LAN address).
        let host = env["AFCON_API_HOST"] ?? "localhost"
        let port = Int(env["AFCON_API_PORT"] ?? "") ?? 50051
        precondition(!host.contains("amazonaws.com"), "The Demo target must never talk to the production server")
        TournamentServiceWrapper.useServer(host: host, port: port)
    }
}
