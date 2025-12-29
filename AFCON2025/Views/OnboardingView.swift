import SwiftUI
import SwiftData
import UIKit
import Foundation

private let moroccoGradient = LinearGradient(
    colors: [Color("moroccoRed"), Color("moroccoGreen")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct OnboardingView: View {
    @State private var selection = 0
    var onFinished: (() -> Void)?
    
    var body: some View {
        TabView(selection: $selection) {
            TeamSelectionPage {
                selection = 1
            }
            .tag(0)
            
            NotificationsIntroPage {
                onFinished?()
            } onMaybeLater: {
                onFinished?()
            }
            .tag(1)
        }
        .tabViewStyle(.page)
    }
}

// MARK: - TeamSelectionPage

struct TeamSelectionPage: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTeams = Set<NationalTeam>()
    var onContinue: () -> Void
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Your Favorite Teams")
                .font(.title2)
                .bold()
                .padding(.top, 40)
            
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
            }
            
            Button {
                saveSelectedTeams()
                onContinue()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTeams.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(moroccoGradient))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedTeams.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private func toggleSelection(_ team: NationalTeam) {
        if selectedTeams.contains(team) {
            selectedTeams.remove(team)
        } else {
            selectedTeams.insert(team)
        }
    }
    
    private func saveSelectedTeams() {
        for team in selectedTeams {
            // Check if team is already a favorite
            let teamId = team.id
            let descriptor = FetchDescriptor<FavoriteTeam>(
                predicate: #Predicate<FavoriteTeam> { fav in
                    fav.teamId == teamId
                }
            )

            do {
                let existingFavorites = try modelContext.fetch(descriptor)
                if existingFavorites.isEmpty {
                    let favorite = FavoriteTeam(teamId: team.id)
                    modelContext.insert(favorite)
                }
            } catch {
                // If fetch fails, insert anyway
                let favorite = FavoriteTeam(teamId: team.id)
                modelContext.insert(favorite)
            }
        }
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save favorite teams: \(error)")
        }
    }
}

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
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color("moroccoRed").opacity(0.15) : Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - NotificationsIntroPage

struct NotificationsIntroPage: View {
    @StateObject private var notificationService = AppNotificationService.shared
    @State private var isAuthorized: Bool = false
    @State private var isLoading: Bool = false
    var onFinished: () -> Void
    var onMaybeLater: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(moroccoGradient)
            
            Text("Stay Updated with Notifications")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Enable notifications to get real-time updates about your favorite teams and match results.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if isAuthorized {
                Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            }
            
            if notificationService.authorizationStatus == .denied {
                Text("Notifications are disabled. Enable them in Settings to get match alerts.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                
                Button("Open Settings") {
                    openAppSettings()
                }
                .font(.headline)
                .foregroundStyle(moroccoGradient)
            }
            
            Spacer()
            
            Button {
                Task {
                    await requestAuthorization()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Enable Notifications")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isAuthorized ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(moroccoGradient))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isAuthorized || isLoading)
            .padding(.horizontal, 20)
            
            Button("Maybe later") {
                onMaybeLater()
            }
            .padding(.bottom, 40)
            .foregroundStyle(moroccoGradient)
        }
        .task {
            await notificationService.checkAuthorizationStatus()
            isAuthorized = notificationService.authorizationStatus == .authorized
        }
    }
    
    private func requestAuthorization() async {
        guard !isAuthorized else { return }
        isLoading = true
        do {
            let granted = try await AppNotificationService.shared.requestAuthorization()
            withAnimation {
                isAuthorized = granted
            }
            if granted {
                // Delay a bit then call finished
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                onFinished()
            }
        } catch {
            // Handle any error if needed
        }
        isLoading = false
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// Dummy NotificationService for demonstration

/*
final class NotificationServiceMock {
    static let shared = AppNotificationService()
    
    private init() {}
    
    func requestAuthorization() async throws -> Bool {
        // Simulate async notification authorization request
        try await Task.sleep(nanoseconds: 600_000_000)
        // Simulate user granting permission
        return true
    }
}

@MainActor
private struct OnboardingPreviewWrapper: View {
    var body: some View {
        OnboardingView()
    }
}

#Preview {
    OnboardingPreviewWrapper()
        .modelContainer(for: FavoriteTeam.self, inMemory: true)
}
*/
