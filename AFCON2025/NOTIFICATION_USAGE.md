# Notification Service Usage Guide

## Overview

The NotificationService provides a comprehensive solution for managing local and push notifications in the AFCON 2025 iOS app.

## Quick Start

### 1. Request Permission

Show the permission prompt to users (typically on first launch):

```swift
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var showPermissionSheet = false

    var body: some View {
        VStack {
            // Your onboarding content

            Button("Get Started") {
                showPermissionSheet = true
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            NotificationPermissionView()
        }
    }
}
```

### 2. Schedule Match Reminders

Schedule a notification before a match starts:

```swift
Task {
    do {
        try await notificationService.scheduleMatchReminder(
            fixtureId: 12345,
            homeTeam: "Senegal",
            awayTeam: "Cameroon",
            matchDate: matchStartDate,
            minutesBefore: 30  // Notify 30 minutes before
        )
    } catch {
        print("Failed to schedule reminder: \(error)")
    }
}
```

### 3. Send Score Update Notifications

Notify users about goals during a match:

```swift
Task {
    do {
        try await notificationService.notifyScoreUpdate(
            fixtureId: 12345,
            homeTeam: "Senegal",
            awayTeam: "Cameroon",
            homeScore: 1,
            awayScore: 0,
            event: "Goal by Sadio Mané!"
        )
    } catch {
        print("Failed to send score update: \(error)")
    }
}
```

### 4. Send Match Result Notification

Notify when a match finishes:

```swift
Task {
    do {
        try await notificationService.notifyMatchResult(
            fixtureId: 12345,
            homeTeam: "Senegal",
            awayTeam: "Cameroon",
            homeScore: 2,
            awayScore: 1
        )
    } catch {
        print("Failed to send match result: \(error)")
    }
}
```

## Integration Examples

### Add to Schedule View

```swift
struct ScheduleView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var fixtures: [FixtureModel] = []

    var body: some View {
        List(fixtures) { fixture in
            FixtureRow(fixture: fixture)
                .swipeActions {
                    Button {
                        toggleReminder(for: fixture)
                    } label: {
                        Label("Remind Me", systemImage: "bell")
                    }
                    .tint(.blue)
                }
        }
    }

    private func toggleReminder(for fixture: FixtureModel) {
        guard let matchDate = fixture.date else { return }

        Task {
            do {
                try await notificationService.scheduleMatchReminder(
                    fixtureId: fixture.id,
                    homeTeam: fixture.homeTeam,
                    awayTeam: fixture.awayTeam,
                    matchDate: matchDate,
                    minutesBefore: 30
                )
            } catch {
                print("Failed to schedule reminder: \(error)")
            }
        }
    }
}
```

### Add Settings Link

```swift
struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                Label("Notifications", systemImage: "bell.badge")
            }
        }
        .navigationTitle("Settings")
    }
}
```

### Check Notification Status

```swift
struct ContentView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var showPermissionPrompt = false

    var body: some View {
        TabView {
            // Your tabs
        }
        .onAppear {
            checkNotificationStatus()
        }
        .sheet(isPresented: $showPermissionPrompt) {
            NotificationPermissionView()
        }
    }

    private func checkNotificationStatus() {
        // Show permission prompt if not determined
        if notificationService.authorizationStatus == .notDetermined {
            // Wait a bit before showing the prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showPermissionPrompt = true
            }
        }
    }
}
```

## Handling Notification Taps

The service automatically handles notification taps. To respond to them in your app:

```swift
struct ContentView: View {
    @State private var selectedFixtureId: Int?

    var body: some View {
        NavigationStack {
            // Your content
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMatchDetail"))) { notification in
            if let fixtureId = notification.userInfo?["fixtureId"] as? Int {
                selectedFixtureId = fixtureId
                // Navigate to match detail
            }
        }
    }
}
```

## Managing Notifications

### Cancel Specific Match Reminders

```swift
notificationService.cancelMatchReminders(fixtureId: 12345)
```

### Clear All Notifications

```swift
notificationService.clearAllNotifications()
```

### Get Pending Notifications

```swift
Task {
    let pending = await notificationService.getPendingNotifications()
    print("Scheduled notifications: \(pending.count)")
}
```

## Push Notifications

### Backend Integration

When a device registers for push notifications, the device token is printed to the console. You'll need to send this token to your backend:

1. In `NotificationService.swift`, implement `sendTokenToServer`:

```swift
private func sendTokenToServer(_ token: String) {
    // Send to your backend
    Task {
        do {
            try await AFCONService.shared.registerDeviceToken(token)
        } catch {
            print("Failed to register token: \(error)")
        }
    }
}
```

2. Uncomment the call in `setDeviceToken`:

```swift
func setDeviceToken(_ token: Data) {
    let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
    self.deviceToken = tokenString
    print("📱 Device Token: \(tokenString)")

    sendTokenToServer(tokenString)  // Uncomment this line
}
```

### Push Notification Payload

Your backend should send push notifications with this format:

```json
{
  "aps": {
    "alert": {
      "title": "Match Starting Soon",
      "body": "Senegal vs Cameroon starts in 30 minutes"
    },
    "sound": "default",
    "badge": 1,
    "category": "MATCH_REMINDER"
  },
  "fixtureId": 12345,
  "type": "match_reminder"
}
```

## Best Practices

1. **Request Permission at the Right Time**: Don't ask for notification permission immediately on launch. Wait until the user has seen value in your app.

2. **Be Specific**: Use clear, descriptive notification content that tells users exactly what happened.

3. **Respect User Preferences**: Allow users to customize which notifications they receive.

4. **Test Thoroughly**: Test notifications in both foreground and background states.

5. **Handle Errors**: Always handle errors when scheduling notifications.

6. **Clear Badge Counts**: Clear the app badge when users open the app:
   ```swift
   UIApplication.shared.applicationIconBadgeNumber = 0
   ```

## Troubleshooting

### Notifications Not Appearing

1. Check authorization status in Settings
2. Verify notification content is not empty
3. Ensure trigger date is in the future
4. Check device notification settings

### Push Notifications Not Working

1. Verify `aps-environment` in entitlements file
2. Check that device token is being received
3. Ensure backend is using correct token format
4. Verify push notification payload format

### Device Token Not Received

1. Test on a physical device (simulator has limitations)
2. Check network connectivity
3. Verify Apple Push Notification service is enabled in capabilities

## Additional Resources

- [Apple's User Notifications Documentation](https://developer.apple.com/documentation/usernotifications)
- [Push Notifications Tutorial](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns)
