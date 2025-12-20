import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: FixtureDataManager?
    @State private var showingClearConfirmation = false
    @State private var fixtureCount: Int = 0

    var body: some View {
        NavigationView {
            List {
                // Data Management Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fixtures in Database")
                                .font(.subheadline)
                            Text("\(fixtureCount) fixtures")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if let lastSync = dataManager?.lastSyncDate {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Last Sync")
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
                                Text("Initialize Fixtures")
                                    .foregroundColor(.primary)
                                Text("Fetch all tournament fixtures from server")
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
                                Text("Sync Live Matches")
                                    .foregroundColor(.primary)
                                Text("Update live and recent matches")
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
                            Text("Clear All Fixtures")
                        }
                    }
                    .disabled(dataManager?.isInitializing == true)

                } header: {
                    Text("Data Management")
                } footer: {
                    if let error = dataManager?.initializationError {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        Text("Initialize fixtures before the tournament starts to have offline access to the schedule.")
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Tournament")
                        Spacer()
                        Text("AFCON 2025")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            setupDataManager()
            updateFixtureCount()
        }
        .confirmationDialog(
            "Clear All Fixtures",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Data", role: .destructive) {
                clearAllFixtures()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all \(fixtureCount) fixtures from local storage. You can re-download them anytime.")
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
}

#Preview {
    SettingsView()
        .modelContainer(for: FixtureModel.self)
}
