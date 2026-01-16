# SwiftData Fixtures Guide

This guide explains how to use the SwiftData fixture system to store and display AFCON 2025 tournament data locally.

## Overview

The app now has a complete SwiftData integration that allows you to:
- Fetch all tournament fixtures from the server
- Store them locally in SwiftData
- Display scheduled, live, and finished games offline
- Sync live match updates during the tournament

## Components

### 1. FixtureModel (`Models/FixtureModel.swift`)
SwiftData model that stores all fixture information:
- Match details (teams, scores, status)
- Venue information
- Timestamps and dates
- Competition metadata

### 2. FixtureDataManager (`Services/FixtureDataManager.swift`)
Service that handles syncing between server and SwiftData:
- `initializeFixtures()` - Fetch all fixtures from server
- `syncAllFixtures()` - Upsert all fixtures without clearing
- `syncLiveFixtures()` - Update live matches
- `syncFixturesForDate()` - Sync fixtures for specific date
- Query helpers for getting fixtures by status

### 3. SettingsView (`Views/SettingsView.swift`)
User interface for managing fixture data:
- Initialize all fixtures button
- Sync live matches button
- Clear all data button
- Shows fixture count and last sync time

### 4. FixturesListView (`Views/FixturesListView.swift`)
Example view showing how to query and display fixtures from SwiftData

## Usage

### Automatic Refresh on App Launch

The app refreshes fixtures on launch if the last sync is older than 6 hours. This uses
`syncAllFixtures()` so new matches are added and existing matches are updated without clearing data.

### Step 1: Initialize Fixtures Before Tournament Starts

1. Launch the app
2. Go to the **Settings** tab (gear icon)
3. Tap **"Initialize Fixtures"**
4. Wait for the sync to complete
5. You'll see the fixture count update

This will fetch all AFCON 2025 fixtures from the server and store them locally.

### Step 2: Using Fixtures in Your Views

#### Basic Query - All Fixtures
```swift
import SwiftUI
import SwiftData

struct MyView: View {
    @Query(sort: \FixtureModel.date) private var fixtures: [FixtureModel]

    var body: some View {
        List(fixtures) { fixture in
            Text(fixture.homeTeamName)
        }
    }
}
```

#### Query Live Fixtures Only
```swift
@Query(
    filter: #Predicate<FixtureModel> { fixture in
        ["LIVE", "1H", "2H", "HT", "ET", "P"].contains(fixture.statusShort)
    },
    sort: \FixtureModel.date
) private var liveFixtures: [FixtureModel]
```

#### Query Upcoming Fixtures Only
```swift
@Query(
    filter: #Predicate<FixtureModel> { fixture in
        !["LIVE", "1H", "2H", "HT", "ET", "P", "FT", "AET", "PEN"].contains(fixture.statusShort)
    },
    sort: \FixtureModel.date
) private var upcomingFixtures: [FixtureModel]
```

#### Query Finished Fixtures Only
```swift
@Query(
    filter: #Predicate<FixtureModel> { fixture in
        ["FT", "AET", "PEN"].contains(fixture.statusShort)
    },
    sort: \FixtureModel.date
) private var finishedFixtures: [FixtureModel]
```

#### Query Fixtures for Specific Date
```swift
@Query(
    filter: #Predicate<FixtureModel> { fixture in
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return fixture.date >= startOfDay && fixture.date < endOfDay
    },
    sort: \FixtureModel.date
) private var todayFixtures: [FixtureModel]
```

### Step 3: Syncing Live Matches During Tournament

During the tournament, you can sync live matches to get real-time updates:

**Option A: From Settings Tab**
1. Go to Settings
2. Tap "Sync Live Matches"

**Option B: Programmatically**
```swift
@Environment(\.modelContext) private var modelContext
@State private var dataManager: FixtureDataManager?

// In your view
private func syncLiveMatches() async {
    let manager = FixtureDataManager(modelContext: modelContext)
    await manager.syncLiveFixtures()
}
```

### Step 4: Full Refresh (Non-Destructive)

If you want to pull the latest schedule updates without clearing local data:

```swift
@Environment(\.modelContext) private var modelContext

private func refreshAllFixtures() async {
    let manager = FixtureDataManager(modelContext: modelContext)
    await manager.syncAllFixtures()
}
```

## FixtureModel Properties

### Basic Info
- `id: Int` - Unique fixture ID
- `date: Date` - Match date/time
- `timestamp: Int` - Unix timestamp
- `referee: String` - Referee name
- `timezone: String` - Timezone

### Venue
- `venueId: Int` - Venue ID
- `venueName: String` - Stadium name
- `venueCity: String` - City
- `fullVenue: String` - Computed property combining name and city

### Status
- `statusLong: String` - e.g., "Match Finished"
- `statusShort: String` - e.g., "FT", "LIVE", "NS"
- `statusElapsed: Int` - Minutes elapsed
- `isLive: Bool` - Computed property
- `isFinished: Bool` - Computed property
- `isUpcoming: Bool` - Computed property

### Teams
- `homeTeamId: Int`
- `homeTeamName: String`
- `homeTeamLogo: String`
- `homeTeamWinner: Bool`
- `awayTeamId: Int`
- `awayTeamName: String`
- `awayTeamLogo: String`
- `awayTeamWinner: Bool`

### Scores
- `homeGoals: Int` - Current home goals
- `awayGoals: Int` - Current away goals
- `halftimeHome: Int`
- `halftimeAway: Int`
- `fulltimeHome: Int`
- `fulltimeAway: Int`

### Metadata
- `competition: String` - "AFCON 2025"
- `lastUpdated: Date` - Last sync timestamp
- `formattedDate: String` - Computed formatted date
- `formattedTime: String` - Computed formatted time (HH:mm)

## Integration Example: Update LiveScoresView

Here's how to update your `LiveScoresView` to use SwiftData:

```swift
import SwiftUI
import SwiftData

struct LiveScoresView: View {
    @Query(
        filter: #Predicate<FixtureModel> { fixture in
            ["LIVE", "1H", "2H", "HT", "ET", "P"].contains(fixture.statusShort)
        },
        sort: \FixtureModel.date
    ) private var liveFixtures: [FixtureModel]

    @Query(
        filter: #Predicate<FixtureModel> { fixture in
            !["LIVE", "1H", "2H", "HT", "ET", "P", "FT", "AET", "PEN"].contains(fixture.statusShort)
        },
        sort: \FixtureModel.date
    ) private var upcomingFixtures: [FixtureModel]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Live Matches Section
                if !liveFixtures.isEmpty {
                    Text("LIVE NOW")
                        .font(.headline)
                        .foregroundColor(.red)

                    ForEach(liveFixtures) { fixture in
                        FixtureCard(fixture: fixture)
                    }
                }

                // Upcoming Matches Section
                if !upcomingFixtures.isEmpty {
                    Text("UPCOMING")
                        .font(.headline)

                    ForEach(upcomingFixtures) { fixture in
                        FixtureCard(fixture: fixture)
                    }
                }
            }
            .padding()
        }
    }
}
```

## Best Practices

1. **Initialize Before Tournament**: Run initialization before the tournament starts to have all fixtures available offline

2. **Regular Syncs During Tournament**: During live matches, sync every few minutes to get score updates

3. **Error Handling**: Always handle potential fetch errors
   ```swift
   do {
       let fixtures = try dataManager.getAllFixtures()
   } catch {
       print("Error fetching fixtures: \(error)")
   }
   ```

4. **Offline First**: Design your UI to work with SwiftData first, fall back to server if needed

5. **Background Sync**: Consider using background tasks to sync live matches automatically

## Troubleshooting

### No fixtures showing up?
- Make sure you've initialized fixtures in Settings
- Check that the server is running and accessible
- Look at console logs for error messages

### Fixtures not updating during live matches?
- Tap "Sync Live Matches" in Settings
- Verify network connection
- Check that the server is streaming live updates

### Old data showing?
- Clear all fixtures in Settings
- Re-initialize to get fresh data from server

## Server API Endpoints Used

- `getFixtures(leagueId:season:)` - Get all fixtures
- `getFixtures(leagueId:season:live:)` - Get live fixtures only
- `getFixtures(leagueId:season:date:)` - Get fixtures for specific date

## Next Steps

See `FixturesListView.swift` for a complete working example of displaying fixtures with filtering and sorting.
