import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: FixtureDataManager?
    @State private var showingClearConfirmation = false
    @State private var fixtureCount: Int = 0
    @State private var selectedLanguage: AppLanguage = AppSettings.shared.appLanguage
    @State private var showRestartAlert = false

    var body: some View {
        NavigationView {
            List {
                #if DEBUG
                // Data Management Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey("Fixtures in Database"))
                                .font(.subheadline)
                            Text(LocalizedStringKey("\(fixtureCount) fixtures"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if let lastSync = dataManager?.lastSyncDate {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(LocalizedStringKey("Last Sync"))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(lastSync, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button {
                        Task {
                            await initializeData()
                        }
                    } label: {
                        HStack {
                            if dataManager?.isInitializing == true {
                                ProgressView()
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(Color("moroccoRed"))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey("Initialize Fixtures"))
                                    .foregroundColor(.primary)
                                Text(LocalizedStringKey("Fetch all tournament fixtures from server"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(dataManager?.isInitializing == true)

                    Button {
                        Task {
                            await syncLiveMatches()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(Color("moroccoGreen"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey("Sync Live Matches"))
                                    .foregroundColor(.primary)
                                Text(LocalizedStringKey("Update live and recent matches"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(dataManager?.isInitializing == true)

                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text(LocalizedStringKey("Clear All Fixtures"))
                        }
                    }
                    .disabled(dataManager?.isInitializing == true)

                } header: {
                    Text(LocalizedStringKey("Data Management"))
                } footer: {
                    if let error = dataManager?.initializationError {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        Text(LocalizedStringKey("Initialize fixtures before the tournament starts to have offline access to the schedule."))
                    }
                }
                #endif

                // Notifications Section
                Section(LocalizedStringKey("Notifications")) {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.blue)
                            Text(LocalizedStringKey("Notification Settings"))
                        }
                    }
                }

                // Favorite Teams Section
                Section(LocalizedStringKey("Favorite Teams")) {
                    NavigationLink {
                        FavoriteTeamManagementView()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color("moroccoRed"))
                            Text(LocalizedStringKey("Manage Favorite Teams"))
                        }
                    }
                }

                // Language Section
                Section {
                    Picker(LocalizedStringKey("App Language"), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.localizedName)
                                .tag(language)
                        }
                    }
                    .onChange(of: selectedLanguage) { oldValue, newValue in
                        AppSettings.shared.appLanguage = newValue
                        showRestartAlert = true
                    }
                } header: {
                    Text(LocalizedStringKey("Language"))
                } footer: {
                    Text(LocalizedStringKey("Restart the app to apply language changes."))
                }

                // About Section
                Section(LocalizedStringKey("About")) {
                    HStack {
                        Text(LocalizedStringKey("Version"))
                        Spacer()
                        Text(AppSettings.shared.currentAppVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(LocalizedStringKey("Tournament"))
                        Spacer()
                        Text(LocalizedStringKey("AFCON 2025"))
                            .foregroundColor(.secondary)
                    }

                    if AppSettings.shared.hasCompletedOnboarding {
                        HStack {
                            Text(LocalizedStringKey("Onboarding Status"))
                            Spacer()
                            Text(LocalizedStringKey("Completed"))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Developer Section (for testing)
                #if DEBUG
                Section(LocalizedStringKey("Developer")) {
                    Button {
                        resetOnboarding()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.orange)
                            Text(LocalizedStringKey("Reset Onboarding"))
                        }
                    }

                    Button {
                        AppNotificationService.shared.clearAllNotifications()
                    } label: {
                        HStack {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.orange)
                            Text(LocalizedStringKey("Clear All Notifications"))
                        }
                    }

                    NavigationLink {
                        LiveActivityDiagnosticsView()
                    } label: {
                        HStack {
                            Image(systemName: "livephoto.badge.automatic")
                                .foregroundColor(.purple)
                            Text(LocalizedStringKey("Live Activity Diagnostics"))
                        }
                    }

                    Button {
                        Task {
                            await LiveActivityManager.shared.endAllActivities()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "livephoto.slash")
                                .foregroundColor(.red)
                            Text(LocalizedStringKey("Stop All Live Activities"))
                        }
                    }
                }
                #endif
            }
            .navigationTitle(LocalizedStringKey("Settings"))
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            setupDataManager()
            updateFixtureCount()
        }
        .confirmationDialog(
            LocalizedStringKey("Clear All Fixtures"),
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(LocalizedStringKey("Clear All Data"), role: .destructive) {
                clearAllFixtures()
            }
            Button(LocalizedStringKey("Cancel"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("This will remove all \(fixtureCount) fixtures from local storage. You can re-download them anytime."))
        }
        .alert(LocalizedStringKey("Language Changed"), isPresented: $showRestartAlert) {
            Button(LocalizedStringKey("OK"), role: .cancel) {}
        } message: {
            Text(LocalizedStringKey("Please restart the app to see the changes."))
        }
    }

    // MARK: - Helper Methods

    private func setupDataManager() {
        if dataManager == nil {
            dataManager = FixtureDataManager(modelContext: modelContext)
        }
    }

    private func updateFixtureCount() {
        do {
            let descriptor = FetchDescriptor<FixtureModel>()
            fixtureCount = try modelContext.fetchCount(descriptor)
        } catch {
            print("Error counting fixtures: \(error)")
            fixtureCount = 0
        }
    }

    private func initializeData() async {
        guard let manager = dataManager else { return }
        await manager.initializeFixtures()
        updateFixtureCount()
    }

    private func syncLiveMatches() async {
        guard let manager = dataManager else { return }
        await manager.syncLiveFixtures()
        updateFixtureCount()
    }

    private func clearAllFixtures() {
        do {
            let descriptor = FetchDescriptor<FixtureModel>()
            let allFixtures = try modelContext.fetch(descriptor)

            for fixture in allFixtures {
                modelContext.delete(fixture)
            }

            try modelContext.save()
            updateFixtureCount()

        } catch {
            print("Error clearing fixtures: \(error)")
        }
    }

    private func resetOnboarding() {
        AppSettings.shared.resetOnboarding()
        // Note: App needs to be restarted to see onboarding again
    }
}

// MARK: - FavoriteTeamManagementView

struct FavoriteTeamManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var favoriteTeams: [FavoriteTeam]
    @State private var selectedTeams = Set<NationalTeam>()

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(LocalizedStringKey("Select teams to receive automatic Live Activities and notifications when they play"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGroupedBackground))

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(NationalTeam.sampleTeams.sorted {
                        $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending
                    }) { team in
                        TeamCardView(team: team, isSelected: selectedTeams.contains(team))
                            .onTapGesture {
                                toggleSelection(team)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(LocalizedStringKey("Favorite Teams"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey("Save")) {
                    saveSelectedTeams()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            loadCurrentFavorites()
        }
    }

    private func loadCurrentFavorites() {
        selectedTeams = Set(
            favoriteTeams.compactMap { favorite in
                NationalTeam.team(for: favorite.teamId)
            }
        )
    }

    private func toggleSelection(_ team: NationalTeam) {
        if selectedTeams.contains(team) {
            selectedTeams.remove(team)
        } else {
            selectedTeams.insert(team)
        }
    }

    private func saveSelectedTeams() {
        // Remove all existing favorites
        for favorite in favoriteTeams {
            modelContext.delete(favorite)
        }

        // Add newly selected teams
        for team in selectedTeams {
            let favorite = FavoriteTeam(teamId: team.id)
            modelContext.insert(favorite)
        }

        do {
            try modelContext.save()
            print("✅ Saved \(selectedTeams.count) favorite teams")
        } catch {
            print("❌ Failed to save favorite teams: \(error)")
        }
    }
}

// MARK: - TeamCardView (reusable)

private struct TeamCardView: View {
    let team: NationalTeam
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(team.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color("moroccoRed") : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? Color("moroccoRed").opacity(0.4) : .clear, radius: 6)

            Text(team.localizedName)
                .font(.footnote)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color("moroccoRed").opacity(0.15) : Color(UIColor.secondarySystemBackground))
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: FixtureModel.self)
}
