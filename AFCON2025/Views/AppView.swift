//
//  AppView.swift
//  AFCON2025
//
//  Created by Audrey Zebaze on 14/12/2025.
//

import SwiftUI
import SwiftData
import UIKit

private let moroccoGradient = LinearGradient(
    colors: [Color("moroccoRed"), Color("moroccoGreen")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

struct AppView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showOnboarding = !AppSettings.shared.hasCompletedOnboarding
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                LaunchScreen()
            } else if showOnboarding {
                OnboardingView {
                    completeOnboarding()
                }
            } else {
                AFCONHomeView()
            }
        }
        .onAppear {
            // Update launch tracking
            AppSettings.shared.updateLastLaunchVersion()

            // Clear badge when app opens
            Task {
                await AppNotificationService.shared.clearBadge()
            }

            loadFavoriteTeams()
            Task {
                await AppNotificationService.shared.syncIfPossibleOnLaunch()
            }

            // Simulate minimum loading time for smooth experience
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }

    private func completeOnboarding() {
        AppSettings.shared.completeOnboarding()
        withAnimation {
            showOnboarding = false
        }
    }

    private func loadFavoriteTeams() {
        let descriptor = FetchDescriptor<FavoriteTeam>()
        do {
            let favorites = try modelContext.fetch(descriptor)
            AppSettings.shared.selectedFavoriteTeamIds = favorites.map { $0.teamId }
        } catch {
            print("❌ Failed to load favorite teams: \(error)")
        }
    }
}

// MARK: - Launch Screen

struct LaunchScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Background gradient
            moroccoGradient
                .ignoresSafeArea()
                .opacity(0.1)

            Color(.systemBackground)
                .opacity(colorScheme == .dark ? 0.95 : 0.97)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo with subtle pulse animation
                logoView
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .opacity(pulseAnimation ? 0.8 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                // Progress indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color("moroccoRed"))

                    Text("AFCON 2025")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(moroccoGradient)
                }
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }

    @ViewBuilder
    private var logoView: some View {
        if let logo = UIImage(named: "AppIcon") {
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(moroccoGradient, lineWidth: 3)
                )
                .shadow(color: Color("moroccoRed").opacity(0.4), radius: 16)
        } else {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(moroccoGradient)
                .shadow(color: Color("moroccoRed").opacity(0.4), radius: 16)
        }
    }
}

#Preview("Onboarding") {
    @Previewable @State var showOnboarding = true
    AppView()
}
