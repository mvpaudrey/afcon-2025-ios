import SwiftUI
import SwiftData

/// Root AFCON experience with the core tournament tabs.
struct AFCONHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var isInitializingFixtures = false
    @State private var hasCheckedFixtures = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            TabView(selection: $selectedTab) {
                Tab(value: 0) {
                    LiveScoresView()
                } label: {
                    Label(LocalizedStringKey("Live"), systemImage: "bolt.fill")
                }

                Tab(value: 1) {
                    GroupsView()
                } label: {
                    Label(LocalizedStringKey("Groups"), systemImage: "trophy.fill")
                }

                Tab(value: 2) {
                    ScheduleViewNew()
                } label: {
                    Label(LocalizedStringKey("Schedule"), systemImage: "calendar")
                }

                Tab(value: 3) {
                    BracketView()
                } label: {
                    Label(LocalizedStringKey("Bracket"), systemImage: "chart.bar.doc.horizontal")
                }

                Tab(value: 4) {
                    VenuesView()
                } label: {
                    Label(LocalizedStringKey("Venues"), systemImage: "map.fill")
                }

                Tab(value: 5) {
                    SocialView()
                } label: {
                    Label(LocalizedStringKey("Social"), systemImage: "person.2.fill")
                }

                Tab(value: 6) {
                    SettingsView()
                } label: {
                    Label(LocalizedStringKey("Settings"), systemImage: "gearshape.fill")
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .modifier(TabViewBottomAccessoryCompat())
            .modifier(TabBarMinimizeBehaviorCompat())
            .tint(Color("moroccoRed"))
            .background(Color(.systemGroupedBackground))
        }
        .overlay(alignment: .bottom) {
            if #available(iOS 26.0, *) {
                // Fallback overlay is empty on iOS 26+ since accessory is applied natively
                EmptyView()
            } else {
                // Fallback on earlier iOS versions: show the quick stats bar as a bottom overlay
                QuickStatsBarLive()
            }
        }
        .overlay {
            if isInitializingFixtures {
                InitializingOverlay()
            }
        }
        .task {
            await checkAndInitializeFixtures()
        }
    }

    // MARK: - Fixture Initialization

    @MainActor
    private func checkAndInitializeFixtures() async {
        // Only check once
        guard !hasCheckedFixtures else { return }
        hasCheckedFixtures = true

        // Check if we have any fixtures
        let descriptor = FetchDescriptor<FixtureModel>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        // If no fixtures, load them from bundled JSON
        if count == 0 {
            print("No fixtures found - loading from bundle...")
            isInitializingFixtures = true

            do {
                let loader = BundledFixturesLoader(modelContext: modelContext)
                try loader.loadBundledFixtures()
                print("Successfully loaded bundled fixtures!")
            } catch {
                print("Failed to load bundled fixtures: \(error)")
                // Fallback to server fetch if bundled load fails
                print("Falling back to server fetch...")
                let dataManager = FixtureDataManager(modelContext: modelContext)
                await dataManager.initializeFixtures()
            }

            isInitializingFixtures = false
        } else {
            print("Found \(count) fixtures - skipping initialization")
        }
    }
}

// MARK: - Initializing Overlay

struct InitializingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                VStack(spacing: 8) {
                    Text("Initializing Tournament Data")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Loading fixtures for AFCON 2025...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.95))
            )
            .shadow(radius: 20)
            .padding(40)
        }
    }
}

private struct TabViewBottomAccessoryCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabViewBottomAccessory {
                    QuickStatsBarLive()
                }
        } else {
            content
        }
    }
}

private struct TabBarMinimizeBehaviorCompat: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

#Preview {
    AFCONHomeView()
}
