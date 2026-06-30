import SwiftUI
import SwiftData

public struct AppView<Factory: TournamentViewFactory>: View {
    @State private var isLoading = true
    @State private var showOnboarding = false
    @EnvironmentObject private var notificationService: AppNotificationService
    @Environment(\.modelContext) private var modelContext

    private let factory: Factory

    public init(factory: Factory) {
        self.factory = factory
    }

    public var body: some View {
        ZStack {
            if isLoading {
                LaunchScreen()
            } else if showOnboarding {
                OnboardingView {
                    AppSettings.shared.completeOnboarding()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                }
            } else {
                factory.makeHomeView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                    showOnboarding = !AppSettings.shared.hasCompletedOnboarding
                }

                // Sync notifications and favorites in the background
                Task {
                    await notificationService.syncIfPossibleOnLaunch()
                }
            }
        }
    }
}
