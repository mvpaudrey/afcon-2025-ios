import SwiftUI
import SwiftData
import UIKit

private let moroccoGradient = LinearGradient(
    colors: [Color("moroccoRed"), Color("moroccoGreen")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

/// Root AFCON experience with the core tournament tabs.
struct AFCONHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var isInitializingFixtures = false
    @State private var hasCheckedFixtures = false
    @State private var liveScoresViewModel: LiveScoresViewModel?

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            TabView(selection: $selectedTab) {
                Tab(value: 0) {
                    if let viewModel = liveScoresViewModel {
                        LiveScoresView(viewModel: viewModel)
                    } else {
                        ProgressView("Initializing...")
                    }
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

                /*Tab(value: 5) {
                    SocialView()
                } label: {
                    Label(LocalizedStringKey("Social"), systemImage: "person.2.fill")
                }

                Tab(value: 6) {
                    SettingsView()
                } label: {
                    Label(LocalizedStringKey("Settings"), systemImage: "gearshape.fill")
                }*/
            }
            .tabViewStyle(.sidebarAdaptable)
            .modifier(TabViewBottomAccessoryCompat(viewModel: liveScoresViewModel))
            .modifier(TabBarMinimizeBehaviorCompat())
            .tint(Color("moroccoRed"))
            .background(Color(.systemGroupedBackground))
        }
        .overlay(alignment: .bottom) {
            if #available(iOS 26.0, *) {
                // iOS 26+ uses native tabViewBottomAccessory, no overlay needed
                EmptyView()
            } else {
                // Fallback for iOS < 26: show as bottom overlay
                if let viewModel = liveScoresViewModel {
                    QuickStatsBarLive(liveScoresViewModel: viewModel)
                        .ignoresSafeArea(edges: .horizontal)
                }
            }
        }
        .overlay {
            if isInitializingFixtures {
                InitializingOverlay()
            }
        }
        .onAppear {
            if liveScoresViewModel == nil {
                liveScoresViewModel = LiveScoresViewModel(modelContext: modelContext)
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

        // Always fetch from API if no fixtures
        if count == 0 {
            print("No fixtures found - fetching from server...")
            isInitializingFixtures = true

            let dataManager = FixtureDataManager(modelContext: modelContext)
            await dataManager.initializeFixtures()

            isInitializingFixtures = false
        } else {
            print("Found \(count) fixtures in SwiftData")

            // Even if fixtures exist, sync live matches to ensure fresh data
            let dataManager = FixtureDataManager(modelContext: modelContext)
            await dataManager.syncLiveFixtures()
        }
    }
}

// MARK: - Initializing Overlay

struct InitializingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(colorScheme == .dark ? 0.95 : 0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                logoView

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color("moroccoRed"))

                VStack(spacing: 8) {
                    Text("Initializing Tournament Data")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Loading fixtures for AFCON 2025...")
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

    @ViewBuilder
    private var logoView: some View {
        if let logo = UIImage(named: "AppIcon") {
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(moroccoGradient, lineWidth: 2)
                )
                .shadow(color: Color("moroccoRed").opacity(0.3), radius: 8)
        } else {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(moroccoGradient)
        }
    }
}

private struct TabViewBottomAccessoryCompat: ViewModifier {
    let viewModel: LiveScoresViewModel?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabViewBottomAccessory {
                    if let viewModel = viewModel {
                        QuickStatsBarLive(liveScoresViewModel: viewModel)
                            .ignoresSafeArea(edges: .horizontal)
                    }
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
