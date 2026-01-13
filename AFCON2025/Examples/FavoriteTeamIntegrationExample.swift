import SwiftUI
import SwiftData

/// EXAMPLE: How to integrate favorite team syncing with your SwiftData model
///
/// Add this to your existing SwiftData model or settings view

// MARK: - Example SwiftData Model

@Model
class UserSettings {
    var favoriteTeamId: Int?
    var favoriteTeamName: String?
    var lastSynced: Date?

    init(favoriteTeamId: Int? = nil, favoriteTeamName: String? = nil) {
        self.favoriteTeamId = favoriteTeamId
        self.favoriteTeamName = favoriteTeamName
    }
}

// MARK: - Example Settings View

struct FavoriteTeamSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]

    @State private var syncService = FavoriteTeamSyncService()
    @State private var showError = false
    @State private var errorMessage = ""

    // All AFCON 2025 teams with IDs
    let teams: [(id: Int, name: String)] = [
        (1532, "Algeria"),
        (1529, "Angola"),
        (1516, "Benin"),
        (1520, "Botswana"),
        (1502, "Burkina Faso"),
        (1530, "Cameroon"),
        (1524, "Comoros"),
        (1508, "Congo DR"),
        (32, "Egypt"),
        (1521, "Equatorial Guinea"),
        (1503, "Gabon"),
        (1501, "Ivory Coast"),
        (1500, "Mali"),
        (31, "Morocco"),
        (1512, "Mozambique"),
        (19, "Nigeria"),
        (13, "Senegal"),
        (1531, "South Africa"),
        (1510, "Sudan"),
        (1489, "Tanzania"),
        (28, "Tunisia"),
        (1519, "Uganda"),
        (1507, "Zambia"),
        (1522, "Zimbabwe")
    ]

    var currentSettings: UserSettings {
        if let existing = settings.first {
            return existing
        }
        let new = UserSettings()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        Form {
            Section("Favorite Team") {
                Picker("Select Team", selection: Binding(
                    get: { currentSettings.favoriteTeamId ?? 0 },
                    set: { newTeamId in
                        selectTeam(id: newTeamId)
                    }
                )) {
                    Text("No Favorite").tag(0)
                    ForEach(teams, id: \.id) { team in
                        Text(team.name).tag(team.id)
                    }
                }

                if let teamName = currentSettings.favoriteTeamName {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("Your team: \(teamName)")
                            .font(.subheadline)
                    }
                }

                if let synced = currentSettings.lastSynced {
                    Text("Last synced: \(synced, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("You'll automatically receive Live Activities for all matches of your favorite team!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .alert("Sync Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func selectTeam(id: Int) {
        guard id != 0 else {
            currentSettings.favoriteTeamId = nil
            currentSettings.favoriteTeamName = nil
            return
        }

        guard let team = teams.first(where: { $0.id == id }) else { return }

        // Update SwiftData
        currentSettings.favoriteTeamId = id
        currentSettings.favoriteTeamName = team.name

        // Sync to server
        Task {
            do {
                try await syncService.updateFavoriteTeam(
                    teamId: id,
                    teamName: team.name
                )

                await MainActor.run {
                    currentSettings.lastSynced = Date()
                    try? modelContext.save()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Example App Delegate Integration

/// Add this to your AppDelegate or App struct to register the device
class ExampleAppDelegate: NSObject, UIApplicationDelegate {
    let syncService = FavoriteTeamSyncService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device Token: \(token)")

        // Register device with server
        Task {
            do {
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                let osVersion = UIDevice.current.systemVersion

                let uuid = try await syncService.registerDevice(
                    userId: "user-\(deviceId)", // Or use your actual user ID
                    deviceToken: token,
                    deviceId: deviceId,
                    appVersion: appVersion,
                    osVersion: osVersion
                )

                print("✅ Device registered with UUID: \(uuid)")

                // If user already has a favorite team in SwiftData, sync it now
                // You'd need to access your SwiftData context here
                // await syncExistingFavoriteTeam()

            } catch {
                print("❌ Failed to register device: \(error)")
            }
        }
    }
}

// MARK: - Usage in SwiftUI App
//
// Example of how to integrate with your main App struct:
//
// @main
// struct AFCON2025App: App {
//     @UIApplicationDelegateAdaptor(ExampleAppDelegate.self) var appDelegate
//
//     var body: some Scene {
//         WindowGroup {
//             ContentView()
//         }
//         .modelContainer(for: UserSettings.self)
//     }
// }
