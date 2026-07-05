import SwiftUI
import SwiftData
import TournamentKit

/// Root FWC 2026 experience with the core tournament tabs.
struct FWCHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tournamentConfig) private var config
    @State private var selectedTab: Int?
    @State private var isInitializingFixtures = false
    @State private var hasCheckedFixtures = false
    @State private var liveScoresViewModel: LiveScoresViewModel?

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            TabView(selection: Binding(
                get: { selectedTab ?? 0 },
                set: { selectedTab = $0 }
            )) {
                if let viewModel = liveScoresViewModel {
                    LiveScoresView(viewModel: viewModel, onOpenSchedule: {
                        selectedTab = 2
                    })
                    .tabItem { Label(LocalizedStringKey("Live"), systemImage: "bolt.fill") }
                    .tag(0)
                } else {
                    ProgressView("Initializing...")
                        .tabItem { Label(LocalizedStringKey("Live"), systemImage: "bolt.fill") }
                        .tag(0)
                }

                FWCGroupsView()
                    .tabItem { Label(LocalizedStringKey("Groups"), systemImage: "trophy.fill") }
                    .tag(1)

                ScheduleViewNew()
                    .tabItem { Label(LocalizedStringKey("Schedule"), systemImage: "calendar") }
                    .tag(2)

                FWCBracketView()
                    .tabItem { Label(LocalizedStringKey("Bracket"), systemImage: "chart.bar.doc.horizontal") }
                    .tag(3)
            }
            .tabViewStyle(.sidebarAdaptable)
            .tint(Color(config.accentColorName))
            .tabViewBottomAccessory {
                if let viewModel = liveScoresViewModel, viewModel.hasGamesToday {
                    QuickStatsBarLive(liveScoresViewModel: viewModel)
                        .ignoresSafeArea(edges: .horizontal)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .background(Color(.systemGroupedBackground))
        }
        .overlay {
            if isInitializingFixtures {
                FWCInitializingOverlay(accentColorName: config.accentColorName)
            }
        }
        .onAppear {
            if liveScoresViewModel == nil {
                liveScoresViewModel = LiveScoresViewModel(modelContext: modelContext)
            }
            if selectedTab == nil {
                selectedTab = 0
            }
            Task {
                await checkAndInitializeFixtures()
            }
        }
    }

    // MARK: - Fixture Initialization

    @MainActor
    private func checkAndInitializeFixtures() async {
        guard !hasCheckedFixtures else { return }
        hasCheckedFixtures = true

        let descriptor = FetchDescriptor<FixtureModel>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        let dataManager = FixtureDataManager(modelContext: modelContext)

        if count == 0 {
            isInitializingFixtures = true
            await dataManager.initializeFixtures()
            isInitializingFixtures = false
            if let viewModel = liveScoresViewModel {
                await viewModel.fetchLiveMatches()
                viewModel.startLiveUpdates()
            }
        } else {
            await dataManager.syncLiveFixtures()
            if let viewModel = liveScoresViewModel {
                await viewModel.fetchLiveMatches()
                viewModel.startLiveUpdates()
            }
        }
    }
}

// MARK: - Initializing Overlay

struct FWCInitializingOverlay: View {
    let accentColorName: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(colorScheme == .dark ? 0.95 : 0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color(accentColorName))

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(accentColorName))

                VStack(spacing: 8) {
                    Text(LocalizedStringKey("Initializing Tournament Data"))
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(LocalizedStringKey("Loading fixtures for FIFA World Cup 2026..."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
            .shadow(color: Color.primary.opacity(0.2), radius: 20)
            .padding(40)
        }
    }
}

#Preview {
    FWCHomeView()
}
