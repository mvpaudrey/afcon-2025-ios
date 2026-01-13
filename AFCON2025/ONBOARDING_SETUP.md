# Onboarding & Notification Setup - Complete Guide

## Overview

The AFCON 2025 iOS app now has a complete onboarding flow that runs on first launch and includes notification permission requests.

## What Was Configured

### 1. Onboarding Flow (OnboardingView.swift:1)
A two-page onboarding experience:
- **Page 1**: Team Selection - Users select their favorite teams
- **Page 2**: Notification Permission - Users enable notifications for match updates

### 2. First Launch Tracking (AppSettings.swift:1)
- Tracks whether user has completed onboarding
- Stores app version and launch history
- Provides methods to reset for testing

### 3. Main App Integration (ContentView.swift:10)
- Shows onboarding on first launch
- Transitions to main app after completion
- Smooth animation between screens

### 4. Settings Integration (SettingsView.swift:102)
- Link to notification settings
- Onboarding status display
- Developer tools for testing (DEBUG builds only)

### 5. Notification Service (NotificationService.swift:14)
- `AppNotificationService` handles all notification operations
- Already integrated into onboarding flow

## How It Works

### First Launch Flow

1. User opens app for the first time
2. `ContentView` checks `AppSettings.shared.hasCompletedOnboarding` → `false`
3. Shows `OnboardingView`:
   - **Team Selection**: User picks favorite teams → saved to SwiftData
   - **Notification Permission**: User enables notifications → calls `AppNotificationService.shared.requestAuthorization()`
4. When onboarding completes:
   - `AppSettings.shared.completeOnboarding()` is called
   - Onboarding view animates out
   - Main app (AFCONHomeView) appears

### Subsequent Launches

1. User opens app
2. `ContentView` checks `AppSettings.shared.hasCompletedOnboarding` → `true`
3. Directly shows `AFCONHomeView`

## Files Modified/Created

### Created
- `AppSettings.swift` - First launch and settings manager
- `AppNotificationService.swift` - Notification management service
- `NotificationPermissionView.swift` - Permission prompt UI
- `NotificationSettingsView.swift` - Notification management UI
- `NOTIFICATION_USAGE.md` - Notification service usage guide

### Modified
- `ContentView.swift` - Added onboarding gate logic
- `SettingsView.swift` - Added notification settings link and developer tools
- `AFCON2025App.swift` - Integrated AppDelegate for push notifications
- `OnboardingView.swift` - Already had the notification page implemented

## Testing the Onboarding Flow

### Method 1: Delete and Reinstall App
1. Delete the app from your device/simulator
2. Run the app again from Xcode
3. Onboarding will appear on first launch

### Method 2: Use Developer Settings (DEBUG builds only)
1. Open the app
2. Navigate to Settings
3. Scroll to "Developer" section
4. Tap "Reset Onboarding"
5. Force quit and restart the app
6. Onboarding will appear again

### Method 3: Reset UserDefaults Programmatically
```swift
// In Xcode console or test code
UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
```

## Notification Permission States

The onboarding handles all notification permission states:

### Not Determined
- User hasn't been asked yet
- Onboarding will request permission
- iOS shows system permission dialog

### Granted
- User granted permission
- "Enable Notifications" button shows checkmark
- Auto-advances to main app after 1 second

### Denied
- User denied permission
- Can re-enable in iOS Settings
- App still works without notifications

### Provisional (iOS 12+)
- Silent notifications delivered to Notification Center
- User hasn't made explicit choice yet

## Customization

### Change Onboarding Pages

Edit `OnboardingView.swift`:
```swift
TabView(selection: $selection) {
    TeamSelectionPage { ... }.tag(0)
    NotificationsIntroPage { ... }.tag(1)
    // Add more pages here
    YourCustomPage { ... }.tag(2)
}
```

### Skip Team Selection

If you want to only show notification permission:
```swift
// In OnboardingView
var body: some View {
    NotificationsIntroPage {
        onFinished?()
    } onMaybeLater: {
        onFinished?()
    }
}
```

### Change Notification Timing

Edit reminder timing in `NotificationService.swift`:
```swift
try await scheduleMatchReminder(
    fixtureId: id,
    homeTeam: home,
    awayTeam: away,
    matchDate: date,
    minutesBefore: 15  // Changed from 30 to 15 minutes
)
```

## Troubleshooting

### Onboarding Doesn't Appear
1. Check if onboarding was previously completed:
   ```swift
   print(AppSettings.shared.hasCompletedOnboarding)
   ```
2. Reset using developer settings or delete app

### Notification Permission Not Requested
1. Check authorization status:
   ```swift
   print(AppNotificationService.shared.authorizationStatus)
   ```
2. Verify app has notification entitlements
3. Test on physical device (simulators have limitations)

### Onboarding Appears Every Launch
1. Check if `completeOnboarding()` is being called
2. Verify UserDefaults is working:
   ```swift
   UserDefaults.standard.synchronize()
   ```

## App Flow Diagram

```
App Launch
    ↓
ContentView.onAppear
    ↓
Check hasCompletedOnboarding?
    ↓               ↓
   YES             NO
    ↓               ↓
AFCONHomeView   OnboardingView
                    ↓
              Team Selection
                    ↓
              Notification Permission
                    ↓
              completeOnboarding()
                    ↓
              AFCONHomeView
```

## Best Practices

1. **Don't Skip Onboarding**: Even if user denies notifications, mark onboarding as complete
2. **Provide Settings Access**: Always allow users to change notification preferences later
3. **Test All Paths**: Test both "Enable" and "Maybe Later" flows
4. **Smooth Transitions**: Use animations when transitioning between onboarding and main app
5. **Clear Communication**: Explain why you need permissions with clear benefits

## Additional Features

### Track Selected Teams

Teams selected during onboarding are saved to SwiftData:
```swift
@Query private var favoriteTeams: [FavoriteTeam]

// Access in your views
let teamIds = favoriteTeams.map { $0.teamId }
```

### Handle App Updates

Check if app was updated:
```swift
if AppSettings.shared.wasAppUpdated {
    // Show "What's New" screen
    // Don't show full onboarding
}
```

## Next Steps

1. **Customize Onboarding**: Add your branding and content
2. **Integrate Match Reminders**: Use notification service to schedule match alerts
3. **Add Analytics**: Track onboarding completion rates
4. **Implement Deep Links**: Handle notification taps to open specific matches

## Resources

- [NotificationService Usage Guide](NOTIFICATION_USAGE.md)
- [Apple's Onboarding Best Practices](https://developer.apple.com/design/human-interface-guidelines/onboarding)
- [User Notifications Documentation](https://developer.apple.com/documentation/usernotifications)
