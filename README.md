# AFCON 2025 iOS App 📱⚽

A dedicated iOS app for following the **Africa Cup of Nations 2025** tournament with real-time match updates, Live Activities, and comprehensive match data.

## Overview

This is an AFCON-specific iOS app that connects to the AFCON middleware to provide:
- **Live match streaming** with real-time updates
- **Live Activities** on Lock Screen and Dynamic Island
- **Match fixtures** and schedules
- **Team standings** and group tables
- **Match events** (goals, cards, substitutions, VAR)

## Project Structure

```
AFCONiOSApp/
├── AFCON2025/                   # iOS app target
│   ├── AFCON2025App.swift       # Main app entry point
│   ├── ContentView.swift        # Hosts the AFCONHomeView tabs
│   ├── Models/                  # Data models (FixtureModel, Match, LiveScoreActivityAttributes)
│   ├── Views/                   # UI (LiveScoresView, GroupsView, ScheduleViewNew, BracketView, VenuesView, SocialView, AFCONHomeView)
│   ├── ViewModels/              # LiveScoresViewModel, ScheduleViewModel
│   ├── Services/                # AFCONService wrapper + gRPC client
│   └── Extensions/              # Color + gRPC model helpers
└── LiveScoreWidgetExtension/    # Live Activity / widget files
```

## Features

### ✅ Live Match Updates
- Real-time match score updates
- Event notifications (goals, cards, substitutions)
- Connection status indicators

### ✅ Live Activities
- Match scores on Lock Screen
- Dynamic Island integration (iPhone 14 Pro+)
- Real-time score updates without opening app
- Match events displayed in Live Activity

### ✅ AFCON 2025 Specific
- Pre-configured for AFCON (League ID: 6, Season: 2025)
- AFCON branding and colors
- Group stage and knockout tracking
- All 24 participating teams

## Setup Instructions

### Prerequisites
- Xcode 15+
- iOS 17+ target
- AFCONApp backend server running
- Swift Package Manager

### Step 1: Open in Xcode

You'll need to create an Xcode project since only the source files are provided:

1. **Create New Xcode Project**:
   ```
   File → New → Project
   Choose: iOS → App
   Name: AFCONiOSApp
   Interface: SwiftUI
   Language: Swift
   ```

2. **Add Source Files**:
   - Delete the default `ContentView.swift` and `AFCONiOSAppApp.swift`
   - Drag all files from `AFCONiOSApp/` into your Xcode project
   - Ensure all files are added to the AFCONiOSApp target

### Step 2: Add Dependencies

Add the AFCONClient library:

1. In Xcode: `File → Add Package Dependencies`
2. Add local package: `/path/to/AFCONApp`
3. Select `AFCONClient` library

Or manually in `Package.swift`:
```swift
dependencies: [
    .package(path: "../")  // Path to AFCONApp root
]
```

### Step 3: Configure Live Activities

#### Main App Target

1. Select **AFCONiOSApp** target
2. Go to **Info** tab
3. Add key: `NSSupportsLiveActivities` = `YES`

#### Widget Extension (for Live Activities)

1. Create Widget Extension:
   - `File → New → Target → Widget Extension`
   - Name: `LiveScoreWidget`
   - Don't include Configuration Intent

2. Add files to widget:
   - Copy widget files from parent DesignPlayground if available
   - OR create new widget using `LiveScoreActivityAttributes`

3. Configure widget target:
   - Add `NSSupportsLiveActivities` = `YES` to Info.plist
   - Add `LiveScoreActivityAttributes.swift` to both targets

### Step 4: Build & Run

```bash
# Select AFCONiOSApp scheme
# Select simulator or device
# Build (Cmd+B)
# Run (Cmd+R)
```

## Usage

### Starting Live Match Streaming

1. **Ensure the AFCON middleware is reachable** (gRPC endpoint that serves league ID 6).
2. **Open the iOS app**:
   - Use the Live tab for real-time matches
   - App refreshes fixtures on launch (every 6 hours) and caches them locally
   - Schedule tab lets you manually refresh fixtures on demand
   - Live Activities can be enabled from the Live view when running on device

### Live Activity on Lock Screen

When matches are live:
```
┌─────────────────────────────┐
│  🏆 AFCON 2025              │
│  ─────────────────────────  │
│                             │
│  Nigeria          Cameroon  │
│     2        VS       1     │
│                67'          │
│                             │
│  ⚽ Goal by Osimhen          │
└─────────────────────────────┘
```

### Dynamic Island (iPhone 14 Pro+)

- **Compact**: Shows score `2 - 1`
- **Minimal**: Soccer ball icon ⚽
- **Expanded**: Full match details with latest event

## Configuration

### AFCONService Settings

The client is pinned to AFCON 2025:

```swift
// In AFCONService.swift
var leagueID: Int32 = 6
var season: Int32 = 2025
```

Configure the middleware endpoint when you initialize the wrapper:

```swift
let service = AFCONServiceWrapper(host: "your-remote-host", port: 50051)
```

You can also set defaults via environment variables `AFCON_API_HOST` and `AFCON_API_PORT`.

### Live Activities Toggle

```swift
// Enable/disable Live Activities
AFCONService.shared.liveActivitiesEnabled = true
```

## Architecture

### AFCONService

Main service class that handles:
- gRPC connection to backend
- Live match streaming
- Live Activity management
- Match data caching

### Data Flow

```
Backend Server (AFCONApp)
    ↓ gRPC Stream
AFCONService
    ↓ @Observable
LiveScoresView
    ↓ Live Activity
Lock Screen / Dynamic Island
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `AFCONService` | Main service, handles gRPC streaming |
| `LiveScoresView` | UI for live matches |
| `LiveActivityManager` | Manages Live Activities |
| `ScheduleViewNew` | AFCON fixtures with local caching |

## Customization

### Branding

Update colors in `ContentView.swift`:
```swift
.tint(Color("moroccoRed"))  // AFCON brand color
```

### Match Display

Modify `LiveScoresView.swift` and `MatchCard.swift` to customize:
- Match card layout
- Event display format
- Filtering and sorting
- UI animations

### Live Activity UI

Create custom widget views in `LiveScoreWidget` target:
- Lock Screen compact view
- Lock Screen expanded view
- Dynamic Island views

## Troubleshooting

### Can't Connect to Server

```swift
// Confirm your configured host:port is reachable
// Example: grpcurl -plaintext your-host:50051 list
```

### Live Activities Not Showing

1. Check Settings → Face ID & Passcode → Live Activities (ON)
2. Ensure iOS 16.1+ (or simulator with 16.1+)
3. Verify `NSSupportsLiveActivities` in both Info.plists
4. Toggle must be ON in app before starting stream

### Build Errors

```bash
# Clean build folder
Shift+Cmd+K

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
Cmd+B
```

### Missing AFCONClient

Ensure the package dependency is correctly added:
1. Check `Package.swift` has correct path
2. Try: `File → Packages → Reset Package Caches`
3. Verify AFCONApp backend is built: `cd /path/to/AFCONApp && swift build`

## Development

### Testing on Simulator

```bash
# Select iPhone 15 Pro (for Dynamic Island)
# Or iPhone 14 Pro+ for full Live Activity experience
# Run app (Cmd+R)
```

### Testing Live Activities

1. Run app on device or simulator
2. Enable Live Activities in app
3. Start streaming
4. Lock device (Cmd+L on simulator)
5. Live Activity should appear

### Debugging

Enable verbose logging:
```swift
// In AFCONService.swift
print("🔴 LIVE UPDATE - Event: \(update.eventType)")
```

## Next Steps

- [ ] Add fixtures view with calendar
- [ ] Add standings view with group tables
- [ ] Add team details view
- [ ] Add match notifications
- [ ] Add widget for upcoming matches
- [ ] Add iPad support with split view

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- AFCONApp backend server

## Resources

- [Backend Server README](../README.md)
- [Live Activity Documentation](../LIVE_ACTIVITY_QUICK_START.md)
- [Apple Live Activities Guide](https://developer.apple.com/documentation/activitykit)

## Support

For issues:
1. Check backend server is running
2. Verify gRPC connection on port 50051
3. Check Xcode console for errors
4. Review server logs

---

**Made for AFCON 2025** 🏆 | Real-time African football on iOS!
