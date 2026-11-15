import SwiftUI
import SwiftData
import TournamentKit

struct DemoViewFactory: TournamentViewFactory {
    func makeHomeView() -> some View {
        DemoHomeView()
    }
}

/// Live scores and schedule from the local server, using the views shared through TournamentKit.
struct DemoHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var liveScoresViewModel: LiveScoresViewModel?
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            TabView(selection: $selectedTab) {
                Group {
                    if let viewModel = liveScoresViewModel {
                        LiveScoresView(viewModel: viewModel, onOpenSchedule: { selectedTab = 1 })
                    } else {
                        ProgressView("Initializing...")
                    }
                }
                .tabItem { Label("Live", systemImage: "bolt.fill") }
                .tag(0)

                ScheduleViewNew()
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                    .tag(1)
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            if liveScoresViewModel == nil {
                liveScoresViewModel = LiveScoresViewModel(modelContext: modelContext)
            }
            Task { await start() }
        }
    }

    @MainActor
    private func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        let dataManager = FixtureDataManager(modelContext: modelContext)
        await dataManager.initializeFixtures()
        if let viewModel = liveScoresViewModel {
            await viewModel.fetchLiveMatches()
            viewModel.startLiveUpdates()
        }
    }
}
