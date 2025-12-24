import SwiftUI
import ActivityKit

struct LiveActivityDiagnosticsView: View {
    @State private var diagnosticInfo: String = ""
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .font(.title2)
                            .foregroundColor(.purple)
                        Text("Live Activity Diagnostics")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Check if your device supports Live Activities and Dynamic Island")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                // Quick Status Cards
                HStack(spacing: 12) {
                    StatusCard(
                        title: "Live Activities",
                        status: LiveActivityDiagnostics.isSupported,
                        icon: "livephoto"
                    )

                    StatusCard(
                        title: "Dynamic Island",
                        status: LiveActivityDiagnostics.hasDynamicIsland,
                        icon: "iphone.gen3.radiowaves.left.and.right"
                    )
                }

                // Active Activities
                let activeCount = ActivityKit.Activity<LiveScoreActivityAttributes>.activities.count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Live Activities")
                        .font(.headline)

                    if activeCount > 0 {
                        VStack(spacing: 8) {
                            ForEach(ActivityKit.Activity<LiveScoreActivityAttributes>.activities, id: \.id) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                    } else {
                        Text("No active Live Activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // Detailed Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detailed Information")
                        .font(.headline)

                    Text(diagnosticInfo)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }

                // Refresh Button
                Button(action: refresh) {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isRefreshing)

                // Troubleshooting Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Troubleshooting Tips")
                        .font(.headline)

                    TroubleshootingTip(
                        icon: "iphone.gen3",
                        title: "Device Requirements",
                        description: "Live Activities require iOS 16.1 or later. Dynamic Island requires iPhone 14 Pro or newer."
                    )

                    TroubleshootingTip(
                        icon: "gearshape",
                        title: "Check Settings",
                        description: "Go to Settings > [App Name] and ensure Live Activities are enabled."
                    )

                    TroubleshootingTip(
                        icon: "sportscourt",
                        title: "Start from Live Match",
                        description: "Tap 'Start Live Activity' button on a live match card to manually start a Live Activity."
                    )

                    TroubleshootingTip(
                        icon: "arrow.up.right.square",
                        title: "View on Lock Screen",
                        description: "Live Activities appear on the Lock Screen and in the Dynamic Island (if supported)."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refresh()
        }
    }

    private func refresh() {
        isRefreshing = true
        diagnosticInfo = LiveActivityDiagnostics.getDiagnosticInfo()
        LiveActivityDiagnostics.printDiagnostics()

        // Simulate a small delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let status: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status ? .green : .red)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            Text(status ? "✅ Supported" : "❌ Not Available")
                .font(.caption2)
                .foregroundColor(status ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status ? Color.green : Color.red, lineWidth: 1)
        )
    }
}

struct ActivityRow: View {
    let activity: ActivityKit.Activity<LiveScoreActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let titleText = "\(activity.attributes.homeTeam) vs \(activity.attributes.awayTeam)"
            let statusText = activity.content.state.status
            let scoreText = "Score: \(activity.content.state.homeScore) - \(activity.content.state.awayScore)"
            let idSuffix = String(describing: activity.attributes.fixtureID)

            HStack {
                Text(titleText)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(statusText)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }

            HStack {
                Text(scoreText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("ID: \(idSuffix)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TroubleshootingTip: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        LiveActivityDiagnosticsView()
    }
}
