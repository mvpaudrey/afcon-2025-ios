import SwiftUI
import UIKit

public struct LaunchScreen: View {
    @Environment(\.tournamentConfig) private var config
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulseAnimation = false

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(config.accentColorName), Color(config.secondaryColorName)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.1)

            Color(.systemBackground)
                .opacity(colorScheme == .dark ? 0.95 : 0.97)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                logoView
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .opacity(pulseAnimation ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                               value: pulseAnimation)

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color(config.accentColorName))

                    Text(config.competitionName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(config.accentColorName), Color(config.secondaryColorName)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .onAppear { pulseAnimation = true }
    }

    @ViewBuilder
    private var logoView: some View {
        if let logo = UIImage(named: "AppIcon") {
            let gradient = LinearGradient(
                colors: [Color(config.accentColorName), Color(config.secondaryColorName)],
                startPoint: .leading, endPoint: .trailing
            )
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(gradient, lineWidth: 3))
                .shadow(color: Color(config.accentColorName).opacity(0.4), radius: 16)
        } else {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(config.accentColorName), Color(config.secondaryColorName)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
        }
    }
}
