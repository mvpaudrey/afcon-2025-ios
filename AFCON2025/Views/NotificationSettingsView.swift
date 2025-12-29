//
//  NotificationSettingsView.swift
//  AFCON2025
//
//  Notification settings and management view
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var notificationService: AppNotificationService
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isLoading = true
    @State private var showPermissionSheet = false

    var body: some View {
        List {
            // Alert Banner when notifications are disabled
            if notificationService.authorizationStatus == .denied {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.slash.fill")
                                .font(.title2)
                                .foregroundColor(.red)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notifications Disabled")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("You won't receive match updates or alerts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button {
                            openSettings()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Open iOS Settings", systemImage: "gear")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .background(Color("moroccoRed"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        Text("Go to Settings → Notifications → AFCON 2025 and enable \"Allow Notifications\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
            }

            // Status Section
            Section {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    Text("Notification Status")
                    Spacer()
                    Text(statusText)
                        .foregroundColor(.secondary)
                }

                if notificationService.authorizationStatus == .notDetermined {
                    Button {
                        showPermissionSheet = true
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.badge")
                    }
                }
            } header: {
                Text("Status")
            }

            // Device Token Section (for debugging)
            if let token = notificationService.deviceToken {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Token")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(token)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    Button {
                        UIPasteboard.general.string = token
                    } label: {
                        Label("Copy Token", systemImage: "doc.on.doc")
                    }
                } header: {
                    Text("Push Notifications")
                }
            }

            // Pending Notifications Section
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if pendingNotifications.isEmpty {
                    Text("No scheduled notifications")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        PendingNotificationRow(notification: notification)
                    }
                }
            } header: {
                HStack {
                    Text("Scheduled Notifications")
                    Spacer()
                    Text("\(pendingNotifications.count)")
                        .foregroundColor(.secondary)
                }
            }

            // Actions Section
            Section {
                Button(role: .destructive) {
                    clearAllNotifications()
                } label: {
                    Label("Clear All Notifications", systemImage: "trash")
                }
                .disabled(pendingNotifications.isEmpty)

                Button {
                    loadPendingNotifications()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Actions")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshAuthorizationStatus()
            loadPendingNotifications()
        }
        .refreshable {
            await refreshAuthorizationStatusAsync()
            loadPendingNotifications()
        }
        .sheet(isPresented: $showPermissionSheet) {
            NotificationPermissionView()
        }
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "exclamationmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }

    private var statusText: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Methods

    private func loadPendingNotifications() {
        isLoading = true
        Task {
            let notifications = await notificationService.getPendingNotifications()
            await MainActor.run {
                pendingNotifications = notifications
                isLoading = false
            }
        }
    }

    private func clearAllNotifications() {
        notificationService.clearAllNotifications()
        loadPendingNotifications()
    }

    private func refreshAuthorizationStatus() {
        Task {
            await notificationService.checkAuthorizationStatus()
        }
    }

    private func refreshAuthorizationStatusAsync() async {
        await notificationService.checkAuthorizationStatus()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Pending Notification Row

struct PendingNotificationRow: View {
    let notification: UNNotificationRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notification.content.title)
                .font(.headline)

            Text(notification.content.body)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(nextTriggerDate, style: .relative)
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(AppNotificationService.shared)
    }
}
