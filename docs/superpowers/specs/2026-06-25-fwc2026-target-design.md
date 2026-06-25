# FWC2026 Target Design

**Date:** 2026-06-25  
**Status:** Approved

## Goal

Extend the existing AFCON 2025 iOS app into a multi-tournament platform. One App Store listing (same bundle ID), multiple Xcode targets — one per tournament. Archive the relevant target when a new tournament begins and submit it as an app update. All common logic lives in a local Swift Package (`TournamentKit`) so new tournaments require no changes to shared code.

---

## Architecture Overview

```
AFCONiOSApp/
├── TournamentKit/                  ← local Swift Package (new)
│   └── Sources/TournamentKit/
│       ├── Config/                 TournamentConfig protocol + environment key
│       ├── Models/                 all shared SwiftData models
│       ├── Services/               all shared services
│       ├── ViewModels/             all shared view models
│       └── Views/                  all shared SwiftUI views
│
├── AFCON2025/                      ← existing target, trimmed to tournament-specific files
│   ├── Assets.xcassets             AFCON colors + 24 African team flags
│   ├── AFCON2025App.swift          injects AFCONTournamentConfig into environment
│   ├── Config/AFCONTournamentConfig.swift
│   └── Views/                      6-group layout, AFCON knockout bracket, AFCONHomeView
│
├── FWC2026/                        ← new target, same bundle ID as AFCON2025
│   ├── Assets.xcassets             WC colors + 48 global team flags
│   ├── FWC2026App.swift            injects FWCTournamentConfig into environment
│   ├── Config/FWCTournamentConfig.swift
│   └── Views/                      12-group layout, 48-team bracket, FWCHomeView
│
└── LiveScoreWidget/                ← unchanged, reads from AppGroup shared storage
```

**Archive workflow:**
- AFCON season → select `AFCON2025` scheme → archive → submit
- World Cup season → select `FWC2026` scheme (same bundle ID) → archive → submit as update
- No code changes needed between submissions — only scheme selection differs

---

## TournamentConfig Protocol

Defined in `TournamentKit`. Every piece of code that previously hardcoded `leagueId: 6` or `season: 2025` reads from this instead.

```swift
public protocol TournamentConfig {
    var leagueId: Int32 { get }
    var season: Int32 { get }
    var competitionName: String { get }
    var groupCount: Int { get }
    var teamCount: Int { get }
    var accentColorName: String { get }      // asset catalog color name in the active target
    var secondaryColorName: String { get }
    var appGroupIdentifier: String { get }
}

// Internal fallback — never used in production since every App struct injects a concrete config
struct DefaultTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 6
    let season: Int32 = 2025
    let competitionName = "AFCON 2025"
    let groupCount = 6
    let teamCount = 24
    let accentColorName = "moroccoGreen"
    let secondaryColorName = "moroccoRed"
    let appGroupIdentifier = "group.com.cheulah.afcon2025"
}

public struct TournamentConfigKey: EnvironmentKey {
    public static let defaultValue: any TournamentConfig = DefaultTournamentConfig()
}

public extension EnvironmentValues {
    var tournamentConfig: any TournamentConfig {
        get { self[TournamentConfigKey.self] }
        set { self[TournamentConfigKey.self] = newValue }
    }
}
```

### AFCON concrete type (in `AFCON2025` target)

```swift
public struct AFCONTournamentConfig: TournamentConfig {
    public let leagueId: Int32 = 6
    public let season: Int32 = 2025
    public let competitionName = "AFCON 2025"
    public let groupCount = 6
    public let teamCount = 24
    public let accentColorName = "moroccoGreen"
    public let secondaryColorName = "moroccoRed"
    public let appGroupIdentifier = "group.com.cheulah.afcon2025"
}
```

### FWC concrete type (in `FWC2026` target)

```swift
public struct FWCTournamentConfig: TournamentConfig {
    public let leagueId: Int32 = 1
    public let season: Int32 = 2026
    public let competitionName = "FIFA World Cup 2026"
    public let groupCount = 12
    public let teamCount = 48
    public let accentColorName = "fifaBlue"
    public let secondaryColorName = "fifaGold"
    public let appGroupIdentifier = "group.com.cheulah.afcon2025"  // same group → widget works for both
}
```

Each `App` struct injects the config at the root `WindowGroup`:

```swift
WindowGroup {
    AppView()
        .environment(\.tournamentConfig, FWCTournamentConfig())
}
```

---

## Shared vs Tournament-Specific Split

### Moves into `TournamentKit`

| Layer | Files |
|---|---|
| Models | `FixtureModel`, `FixtureEventModel`, `Match`, `TeamModels`, `LiveScoreActivityAttributes` |
| Services | `LiveMatchStreamService`, `FixtureDataManager`, `LiveActivityManager`, `NotificationService`, `BundledFixturesLoader`, `LogoCacheManager`, `FavoriteTeamSyncService`, `AppGroup`, `MockDataProvider` |
| ViewModels | `ScheduleViewModel`, `LiveScoresViewModel`, `GroupsViewModel`, `BracketViewModel` |
| Views | `MatchCard`, `FinishedMatchCard`, `LiveScoresView`, `ScheduleView`, `ScheduleViewNew`, `FixturesListView`, `PenaltyShootoutView`, `QuickStatsBar`, `QuickStatsBarLive`, `LiveMatchData`, `SettingsView`, `NotificationSettingsView`, `NotificationPermissionView`, `OnboardingView`, `HeaderView`, `AppView`, `SocialView`, `VenuesView`, `LiveActivityDiagnosticsView` |
| Common | `AppSettings`, `TeamFlagMapper`, `HomeWidgetSnapshotStore`, `GRPCModelExtensions`, `FixtureEventExtensions`, `String+TeamNames` |

### Stays in each target

| Target | Files |
|---|---|
| `AFCON2025` | `AFCONTournamentConfig`, `GroupsView` (6-group layout), `BracketView` (AFCON knockout), `AFCONHomeView`, AFCON assets |
| `FWC2026` | `FWCTournamentConfig`, `GroupsView` (12-group layout), `BracketView` (48-team knockout), `FWCHomeView`, WC assets |

---

## TournamentViewFactory — Plugging In Divergent Views

`AppView` lives in `TournamentKit` and cannot import target-specific view types directly. A factory protocol bridges this without `#if` flags.

```swift
// TournamentKit
public protocol TournamentViewFactory {
    associatedtype GroupsViewType: View
    associatedtype BracketViewType: View
    associatedtype HomeViewType: View

    @ViewBuilder func makeGroupsView() -> GroupsViewType
    @ViewBuilder func makeBracketView() -> BracketViewType
    @ViewBuilder func makeHomeView() -> HomeViewType
}
```

Each target provides a concrete factory and passes it into `AppView`:

```swift
// FWC2026
struct FWCViewFactory: TournamentViewFactory {
    func makeGroupsView() -> some View { FWCGroupsView() }
    func makeBracketView() -> some View { FWCBracketView() }
    func makeHomeView() -> some View { FWCHomeView() }
}

// FWC2026App.swift
WindowGroup {
    AppView(factory: FWCViewFactory())
        .environment(\.tournamentConfig, FWCTournamentConfig())
}
```

---

## Widget Strategy

`LiveScoreWidget` remains a single extension — no duplication. It reads tournament data from the shared `AppGroup` `UserDefaults` that the main app writes at launch.

**Main app writes on launch (in `TournamentKit`):**

```swift
public func writeTournamentConfigToAppGroup(_ config: any TournamentConfig) {
    let defaults = UserDefaults(suiteName: config.appGroupIdentifier)
    defaults?.set(Int(config.leagueId), forKey: "tournamentLeagueId")
    defaults?.set(Int(config.season),   forKey: "tournamentSeason")
    defaults?.set(config.competitionName, forKey: "tournamentName")
    defaults?.set(config.groupCount,    forKey: "tournamentGroupCount")
}
```

**Widget reads on render:**

```swift
let defaults = UserDefaults(suiteName: "group.com.cheulah.afcon2025")
let leagueId = Int32(defaults?.integer(forKey: "tournamentLeagueId") ?? 6)
let season   = Int32(defaults?.integer(forKey: "tournamentSeason")   ?? 2025)
```

No widget code changes required when shipping `FWC2026`.

---

## Backend

Single gRPC server. Reconfigure env vars (`LEAGUE_ID`, `SEASON`) and redeploy before each tournament. The `AFCONServiceWrapper` already accepts `leagueId` and `season` as call-site parameters — no backend API changes needed. The iOS app reads the active `TournamentConfig` and passes the correct values at every call.

---

## Adding Future Tournaments

When a new tournament arrives (e.g. AFCON 2027):

1. Add a new Xcode target
2. Create a new `XxxTournamentConfig` struct with the correct league ID and season
3. Create a `XxxViewFactory` with the appropriate group/bracket views
4. Add an assets catalog with that tournament's colors and team flags
5. Archive and submit

No changes to `TournamentKit` required.
