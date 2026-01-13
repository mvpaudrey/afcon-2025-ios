# Live Activities & Push Notifications Setup

## 🎯 Overview

Your AFCON iOS app now has **automatic Live Activities** that are created whenever your favorite team plays! Here's how it works:

## 🔄 How It Works

### 1. Device Registration (One-time setup)
When your app launches for the first time:
- App requests push notification permissions
- App registers with APNs and gets a device token
- App sends device token to server via `registerDevice()`
- Server returns a `device_uuid` that uniquely identifies your device

### 2. Favorite Team Selection (User action)
When user selects/changes their favorite team:
- App updates SwiftData locally (your source of truth)
- App calls `updateFavoriteTeam()` to sync with server
- Server creates/updates a subscription for that team
- **Subscription settings:**
  - ✅ Goals notifications
  - ✅ Match start (15 min before)
  - ✅ Match end notifications
  - ✅ Red card notifications
  - ❌ Lineups (optional)
  - ❌ VAR decisions (optional)

### 3. Automatic Live Activity Creation (Server-side magic)
**30 minutes before each match starts**, the server automatically:
- Finds all upcoming fixtures (next 30 minutes)
- Checks which devices are subscribed to teams in those fixtures
- Creates Live Activity for each subscribed device
- Sends initial push notification

### 4. Live Updates During Match
While the match is live:
- Server polls API-Football every 15 seconds
- Detects goals, red cards, status changes
- Sends push-to-update to your Live Activity
- Updates appear instantly on your lock screen!

### 5. Match End
When match finishes:
- Server sends final score update
- Live Activity dismissed automatically (or stays for post-match recap)

## 📱 iOS Integration Guide

### Step 1: Add FavoriteTeamSyncService to Your App

The service is already created at `Services/FavoriteTeamSyncService.swift`.

### Step 2: Register Device on App Launch

```swift
// In your AppDelegate or App struct

func application(_ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    let syncService = FavoriteTeamSyncService.shared

    Task {
        do {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

            let uuid = try await syncService.registerDevice(
                userId: "user-\(deviceId)",
                deviceToken: token,
                deviceId: deviceId,
                appVersion: appVersion,
                osVersion: UIDevice.current.systemVersion
            )

            print("✅ Registered with UUID: \(uuid)")
        } catch {
            print("❌ Registration failed: \(error)")
        }
    }
}
```

### Step 3: Sync Favorite Team When User Selects It

```swift
// In your Settings View or wherever user selects favorite team

func onFavoriteTeamChanged(teamId: Int, teamName: String) {
    // 1. Update SwiftData (your source of truth)
    userSettings.favoriteTeamId = teamId
    userSettings.favoriteTeamName = teamName
    try? modelContext.save()

    // 2. Sync to server
    Task {
        do {
            try await syncService.updateFavoriteTeam(
                teamId: teamId,
                teamName: teamName
            )
            print("✅ Synced! Live Activities will be created for \(teamName) matches")
        } catch {
            print("❌ Sync failed: \(error)")
        }
    }
}
```

### Step 4: (Optional) Handle Live Activity Push Tokens

If you want to manually start Live Activities from your app:

```swift
import ActivityKit

if let activity = try? Activity<YourAttributes>.request(
    attributes: attributes,
    content: content,
    pushType: .token
) {
    // Get the push token for this specific activity
    Task {
        for await data in activity.pushTokenUpdates {
            let token = data.map { String(format: "%02.2hhx", $0) }.joined()

            // Optionally send to server for manual control
            try? await AFCONServiceWrapper.shared.startLiveActivity(
                deviceUuid: deviceUuid,
                fixtureId: fixtureId,
                activityId: activity.id,
                pushToken: token
            )
        }
    }
}
```

## 🗺️ Team IDs Reference

| Team | ID |
|------|-----|
| Algeria | 1532 |
| Angola | 1529 |
| Benin | 1516 |
| Botswana | 1520 |
| Burkina Faso | 1502 |
| Cameroon | 1530 |
| Comoros | 1524 |
| Congo DR | 1508 |
| Egypt | 32 |
| Equatorial Guinea | 1521 |
| Gabon | 1503 |
| Ivory Coast | 1501 |
| Mali | 1500 |
| Morocco | 31 |
| Mozambique | 1512 |
| Nigeria | 19 |
| Senegal | 13 |
| South Africa | 1531 |
| Sudan | 1510 |
| Tanzania | 1489 |
| Tunisia | 28 |
| Uganda | 1519 |
| Zambia | 1507 |
| Zimbabwe | 1522 |

## 🔧 Server Configuration

### APNs Credentials
- **Environment**: Development
- **Team ID**: 486Q5MQF2F
- **Key ID**: D77LGXHPT2
- **Bundle ID**: com.cheulah.AFCON2025
- **Status**: ✅ Configured and active

### Automatic Service
- **Check Interval**: Every 5 minutes
- **Trigger Window**: 30 minutes before kickoff
- **Update Frequency**: Every 15 seconds during live matches

## 🧪 Testing

### Test Device Registration
```bash
# Your device is already registered:
Device UUID: a5f1d7c8-ed65-400a-bdaf-150a0803a9eb
Device Token: 7f89eea16ba1c3ef23736d96e8cb533b5b1f1deb49ed73feadf4a6dbc0dbe953
```

### Test Favorite Team Sync
Use the `FavoriteTeamSettingsView` example or call directly:
```swift
try await syncService.updateFavoriteTeam(teamId: 1530, teamName: "Cameroon")
```

### Verify Subscription
Check server database:
```bash
docker exec afcon-postgres psql -U postgres -d afcon -c "
SELECT ns.*, dr.device_token
FROM notification_subscriptions ns
JOIN device_registrations dr ON ns.device_id = dr.id
WHERE dr.device_token = 'YOUR_DEVICE_TOKEN';
"
```

## 📊 Server Logs

Monitor Live Activity creation:
```bash
aws logs tail /ecs/staging-afcon-server --region eu-north-1 --since 30m --format short | grep -E "Live Activity|subscription"
```

## ❓ Troubleshooting

### Not Receiving Live Activities?
1. Check device is registered: `syncService.getDeviceUuid()` should return UUID
2. Verify favorite team is set: Call `getSubscriptions()` and check response
3. Check server logs for "Auto-created Live Activity" messages
4. Ensure push notifications are enabled in iOS Settings

### Live Activity Not Updating?
1. Verify APNs credentials are configured (check server logs)
2. Check if match is actually live (server polls every 15s)
3. Ensure ActivityKit is properly configured in your app

### Want to Test Now?
The next AFCON 2025 matches are:
- **Sudan vs Burkina Faso** - Today at 16:00 UTC
- **Equatorial Guinea vs Algeria** - Today at 16:00 UTC
- **Gabon vs Ivory Coast** - Today at 19:00 UTC
- **Mozambique vs Cameroon** - Today at 19:00 UTC

Set your favorite team now and the server will automatically create a Live Activity 30 minutes before their match!

## 🎉 Success!

Your app now has:
- ✅ Automatic device registration
- ✅ Favorite team syncing from SwiftData → Server
- ✅ Automatic Live Activity creation (30 min before matches)
- ✅ Real-time match updates via push notifications
- ✅ Support for all 24 AFCON 2025 teams

No more manual Live Activity creation - it all happens automatically! 🚀
