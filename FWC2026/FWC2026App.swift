import SwiftUI
import SwiftData
import BackgroundTasks
import TournamentKit

@main
struct FWC2026App: App {
    @UIApplicationDelegateAdaptor(FWCAppDelegate.self) var appDelegate
    @StateObject private var notificationService = AppNotificationService.shared

    private let tournamentConfig = FWCTournamentConfig()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FixtureModel.self,
            FixtureEventModel.self,
            FavoriteTeam.self
        ])

        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Could not find application support directory")
        }

        let dirURL = appSupportURL.appendingPathComponent("FWC2026", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: dirURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("⚠️ Could not create FWC2026 directory: \(error)")
        }

        let storeURL = dirURL.appendingPathComponent("fwc2026.store")
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
            print("⚠️ File storage failed, deleting old database: \(error)")

            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("store-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("store-wal"))

            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ SwiftData initialized with fresh database at: \(storeURL.path)")
                return container
            } catch {
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
            AppView(factory: FWCViewFactory())
                .environment(\.tournamentConfig, tournamentConfig)
                .environmentObject(notificationService)
                .onAppear {
                    notificationService.setupNotificationCategories()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - AppDelegate

class FWCAppDelegate: NSObject, UIApplicationDelegate {
    private let backgroundRefreshTaskIdentifier = "com.cheulah.fwc2026.refresh"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        TournamentConfigStore.current = FWCTournamentConfig()

        // Write config to AppGroup so the widget can read it (before any view appears)
        writeTournamentConfigToAppGroup(FWCTournamentConfig())

        LiveMatchStreamService.shared.backgroundRefreshHandler = { [weak self] in
            self?.scheduleBackgroundRefresh()
        }

        AppNotificationService.shared.setupNotificationCategories()

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

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard
            let type = userInfo["type"] as? String,
            type == "start_live_activity",
            let fixtureIdStr = userInfo["fixture_id"] as? String,
            let fixtureId = Int32(fixtureIdStr),
            let homeTeam = userInfo["home_team"] as? String,
            let awayTeam = userInfo["away_team"] as? String
        else {
            completionHandler(.noData)
            return
        }

        guard let deviceUuid = FavoriteTeamSyncService().getDeviceUuid() else {
            print("⚠️ start_live_activity: no device UUID, skipping")
            completionHandler(.failed)
            return
        }

        let initialState = LiveScoreActivityAttributes.ContentState(
            homeScore: 0,
            awayScore: 0,
            status: "NS",
            elapsed: 0,
            lastUpdateTime: Date()
        )

        let started = LiveActivityManager.shared.startActivityAndRegisterWithServer(
            fixtureID: fixtureId,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            competition: TournamentConfigStore.current.competitionName,
            initialState: initialState,
            deviceUuid: deviceUuid
        )

        completionHandler(started ? .newData : .noData)
    }

    // MARK: - Background Tasks

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("📲 FWC2026 background refresh task triggered")

        scheduleBackgroundRefresh()

        let refreshTask = Task {
            guard LiveMatchStreamService.shared.hasLiveMatches else {
                print("ℹ️ No live matches, skipping background refresh")
                task.setTaskCompleted(success: true)
                return
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            print("⚠️ FWC2026 background refresh task expired")
            refreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ FWC2026: Scheduled background refresh task")
        } catch {
            print("❌ FWC2026: Failed to schedule background refresh: \(error)")
        }
    }
}
