//
//  AppView.swift
//  AFCON2025
//
//  Created by Audrey Zebaze on 14/12/2025.
//

import SwiftUI

struct AppView: View {
    @State private var showOnboarding = !AppSettings.shared.hasCompletedOnboarding

    var body: some View {
        ZStack {
            if showOnboarding {
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
        }
    }

    private func completeOnboarding() {
        AppSettings.shared.completeOnboarding()
        withAnimation {
            showOnboarding = false
        }
    }
}

#Preview("Onboarding") {
    @Previewable @State var showOnboarding = true
    AppView()
}

