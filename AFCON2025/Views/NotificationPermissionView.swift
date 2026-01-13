//
//  NotificationPermissionView.swift
//  AFCON2025
//
//  Prompt view for requesting notification permissions
//

import SwiftUI
import Combine

struct NotificationPermissionView: View {
    private let notificationService = AppNotificationService.shared
    @Environment(\.dismiss) var dismiss
    @State private var isRequesting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }

            // Title and description
            VStack(spacing: 16) {
                Text("Stay Updated")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Get notified about match updates, goals, and important moments during AFCON 2025")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "clock.fill",
                    title: "Match Reminders",
                    description: "Get notified before matches start"
                )

                FeatureRow(
                    icon: "sportscourt.fill",
                    title: "Live Score Updates",
                    description: "Real-time notifications for goals and events"
                )

                FeatureRow(
                    icon: "trophy.fill",
                    title: "Match Results",
                    description: "Instant updates when matches finish"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    requestPermission()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Enable Notifications")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)

                Button {
                    dismiss()
                } label: {
                    Text("Maybe Later")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .alert("Notification Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            do {
                let granted = try await notificationService.requestAuthorization()

                await MainActor.run {
                    isRequesting = false

                    if granted {
                        dismiss()
                    } else {
                        errorMessage = "Notification permission was denied. You can enable it later in Settings."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    errorMessage = "Failed to request permission: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationPermissionView()
}
