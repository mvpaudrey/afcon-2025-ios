# FWC2026 Multi-Tournament Target — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract all shared tournament logic into a local Swift Package (`TournamentKit`) and add a new `FWC2026` Xcode target so the same App Store listing can serve any tournament by archiving a different scheme.

**Architecture:** A `TournamentConfig` protocol injected via `@Environment` drives all tournament-specific values. A `TournamentConfigStore` singleton lets non-SwiftUI singletons (services) read the active config. A `TournamentViewFactory` protocol lets each target plug in its own home/groups/bracket views without `#if` flags. All shared code lives in `TournamentKit`; tournament-specific assets and view implementations stay in each target.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Swift Package Manager, gRPC (`AFCONClient` package), WidgetKit, Swift Testing

## Global Constraints

- Minimum deployment target: iOS 17
- Swift 6 strict concurrency — all mutable state on `@MainActor`; singletons use `@MainActor` or actors
- No `#if` compile-time tournament flags — use protocol dispatch
- Both `AFCON2025` and `FWC2026` share bundle ID `com.cheulah.afcon2025` (same App Store listing)
- Both targets share AppGroup `group.com.cheulah.afcon` (single widget extension)
- SwiftData store invalidation on first launch after migration is acceptable — fixtures are refetched from server
- FWC2026: league ID `1`, season `2026`
- AFCON2025: league ID `6`, season `2025`

---

## File Map

### TournamentKit (new local Swift Package at `AFCONiOSApp/TournamentKit/`)

```
TournamentKit/
├── Package.swift
└── Sources/TournamentKit/
    ├── Config/
    │   ├── TournamentConfig.swift          protocol + DefaultTournamentConfig + EnvironmentKey
    │   ├── TournamentConfigStore.swift     global store for non-SwiftUI code
    │   ├── TournamentViewFactory.swift     makeHomeView() protocol
    │   └── AppGroupWriter.swift            writeTournamentConfigToAppGroup(_:)
    ├── Models/
    │   ├── FixtureModel.swift              moved + public
    │   ├── FixtureEventModel.swift         moved + public
    │   ├── Match.swift                     moved + public
    │   ├── TeamModels.swift                moved + public
    │   └── LiveScoreActivityAttributes.swift  moved + public
    ├── Common/
    │   ├── AppSettings.swift               moved + public
    │   ├── TeamFlagMapper.swift            moved + public (dictionary injected from config)
    │   └── HomeWidgetSnapshotStore.swift   moved + public
    ├── Extensions/
    │   ├── GRPCModelExtensions.swift       moved + public
    │   ├── FixtureEventExtensions.swift    moved + public
    │   └── String+TeamNames.swift          moved + public
    ├── Services/
    │   ├── TournamentServiceWrapper.swift  renamed from AFCONServiceWrapper; uses TournamentConfigStore
    │   ├── FixtureDataManager.swift        moved; reads leagueId/season from TournamentConfigStore
    │   ├── LiveMatchStreamService.swift    moved; reads leagueId/season from TournamentConfigStore
    │   ├── LiveActivityManager.swift       moved + public
    │   ├── NotificationService.swift       moved + public
    │   ├── BundledFixturesLoader.swift     moved + public
    │   ├── LogoCacheManager.swift          moved + public
    │   ├── FavoriteTeamSyncService.swift   moved + public
    │   └── MockDataProvider.swift          moved + public
    ├── ViewModels/
    │   ├── ScheduleViewModel.swift         moved + public
    │   ├── LiveScoresViewModel.swift       moved + public
    │   ├── GroupsViewModel.swift           moved + public
    │   └── BracketViewModel.swift          moved + public
    └── Views/
        ├── AppView.swift                   moved + generic over TournamentViewFactory
        ├── HeaderView.swift                moved + reads config for name/colors
        ├── LaunchScreen.swift              extracted from AppView + reads config
        ├── OnboardingView.swift            moved + public
        ├── LiveScoresView.swift            moved + public
        ├── ScheduleView.swift              moved + public
        ├── ScheduleViewNew.swift           moved + public
        ├── FixturesListView.swift          moved + public
        ├── MatchCard.swift                 moved + public
        ├── FinishedMatchCard.swift         moved + public
        ├── PenaltyShootoutView.swift       moved + public
        ├── QuickStatsBar.swift             moved + public
        ├── QuickStatsBarLive.swift         moved + public
        ├── LiveMatchData.swift             moved + public
        ├── SettingsView.swift              moved + public
        ├── NotificationSettingsView.swift  moved + public
        ├── NotificationPermissionView.swift moved + public
        ├── VenuesView.swift                moved + public
        ├── SocialView.swift                moved + public
        ├── LiveActivityDiagnosticsView.swift moved + public
        └── Environment+TabBarMinimized.swift moved + public
```

### AFCON2025 target (trimmed — keeps only tournament-specific files)

```
AFCON2025/
├── AFCON2025App.swift              updated: injects config + factory; writes AppGroup config
├── Config/
│   ├── AFCONTournamentConfig.swift NEW: concrete TournamentConfig
│   └── AFCONViewFactory.swift      NEW: concrete TournamentViewFactory
├── Common/                         (empty — TeamFlagMapper is now in TournamentKit, reads config)
├── Views/
│   ├── AFCONHomeView.swift         kept (tournament-specific tabbed experience)
│   ├── GroupsView.swift            kept (6-group AFCON layout)
│   └── BracketView.swift           kept (AFCON knockout bracket)
└── Assets.xcassets                 kept (AFCON colors + African team flags)
```

All other files in `AFCON2025/` are deleted after being moved to TournamentKit.

### FWC2026 target (new)

```
FWC2026/
├── FWC2026App.swift
├── Config/
│   ├── FWCTournamentConfig.swift
│   └── FWCViewFactory.swift
├── Common/
│   └── FWCTeamFlagMapper.swift     WC team ID → FIFA code mapping
├── Views/
│   ├── FWCHomeView.swift           12-group tabbed experience
│   ├── FWCGroupsView.swift         placeholder — 12-group layout
│   └── FWCBracketView.swift        placeholder — 48-team bracket
└── Assets.xcassets                 WC colors (fifaBlue, fifaGold) + 48 team flag placeholders
```

### LiveScoreWidget (updated)

```
LiveScoreWidget/LiveScoreScheduleWidget.swift   reads leagueId/season from AppGroup
```

---

## Task 1: Scaffold TournamentKit Swift Package

**Files:**
- Create: `AFCONiOSApp/TournamentKit/Package.swift`
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/.gitkeep`
- Create: `AFCONiOSApp/TournamentKit/Tests/TournamentKitTests/TournamentKitTests.swift`

**Interfaces:**
- Produces: `TournamentKit` library product importable from Xcode targets

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/Models
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/Common
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/Extensions
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/Services
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/ViewModels
mkdir -p AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views
mkdir -p AFCONiOSApp/TournamentKit/Tests/TournamentKitTests
```

- [ ] **Step 2: Write Package.swift**

Create `AFCONiOSApp/TournamentKit/Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TournamentKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TournamentKit", targets: ["TournamentKit"])
    ],
    dependencies: [
        // AFCONClient lives in the AFCONApp package two directories up
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "TournamentKit",
            dependencies: [
                .product(name: "AFCONClient", package: "AFCONApp")
            ]
        ),
        .testTarget(
            name: "TournamentKitTests",
            dependencies: ["TournamentKit"]
        )
    ]
)
```

- [ ] **Step 3: Create placeholder test file**

Create `AFCONiOSApp/TournamentKit/Tests/TournamentKitTests/TournamentKitTests.swift`:

```swift
import Testing
@testable import TournamentKit

@Suite("TournamentKit")
struct TournamentKitTests {}
```

- [ ] **Step 4: Add TournamentKit to the Xcode project**

In Xcode, with `AFCON2025.xcodeproj` open:
1. File → Add Package Dependencies → Add Local…
2. Navigate to `AFCONiOSApp/TournamentKit/` and click Add Package
3. In the target membership sheet, add `TournamentKit` to the `AFCON2025` target
4. Verify the package resolves without errors (Product → Build)

- [ ] **Step 5: Commit**

```bash
git add AFCONiOSApp/TournamentKit/
git commit -m "feat: scaffold TournamentKit Swift Package"
```

---

## Task 2: TournamentConfig Protocol + TournamentConfigStore

**Files:**
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config/TournamentConfig.swift`
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config/TournamentConfigStore.swift`
- Modify: `AFCONiOSApp/TournamentKit/Tests/TournamentKitTests/TournamentKitTests.swift`

**Interfaces:**
- Produces:
  - `TournamentConfig` protocol with `leagueId`, `season`, `competitionName`, `groupCount`, `teamCount`, `accentColorName`, `secondaryColorName`, `appGroupIdentifier`, `teamFlagMap`
  - `TournamentConfigStore.current: any TournamentConfig` static store
  - `EnvironmentValues.tournamentConfig: any TournamentConfig` SwiftUI key

- [ ] **Step 1: Write the failing test**

Add to `TournamentKitTests.swift`:

```swift
import Testing
import SwiftUI
@testable import TournamentKit

@Suite("TournamentConfig")
struct TournamentConfigTests {
    @Test("DefaultTournamentConfig has AFCON defaults")
    func defaultConfigHasAFCONDefaults() {
        let config = DefaultTournamentConfig()
        #expect(config.leagueId == 6)
        #expect(config.season == 2025)
        #expect(config.groupCount == 6)
        #expect(config.teamCount == 24)
        #expect(config.appGroupIdentifier == "group.com.cheulah.afcon")
    }

    @Test("TournamentConfigStore defaults to DefaultTournamentConfig")
    func storeDefaultsToAfcon() {
        #expect(TournamentConfigStore.current.leagueId == 6)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

In Xcode: Product → Test (⌘U), filter to `TournamentKitTests`  
Expected: Compile error — `TournamentConfig`, `DefaultTournamentConfig`, `TournamentConfigStore` not defined

- [ ] **Step 3: Create TournamentConfig.swift**

Create `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config/TournamentConfig.swift`:

```swift
import SwiftUI

public protocol TournamentConfig: Sendable {
    var leagueId: Int32 { get }
    var season: Int32 { get }
    var competitionName: String { get }
    var groupCount: Int { get }
    var teamCount: Int { get }
    var accentColorName: String { get }
    var secondaryColorName: String { get }
    var appGroupIdentifier: String { get }
    /// Maps API-Football team IDs to asset image names (FIFA codes, e.g. "MAR")
    var teamFlagMap: [Int: String] { get }
}

// Internal fallback — every App struct injects a concrete config before any view renders
struct DefaultTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 6
    let season: Int32 = 2025
    let competitionName = "AFCON 2025"
    let groupCount = 6
    let teamCount = 24
    let accentColorName = "moroccoGreen"
    let secondaryColorName = "moroccoRed"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    let teamFlagMap: [Int: String] = [:]
}

// MARK: - SwiftUI Environment

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

- [ ] **Step 4: Create TournamentConfigStore.swift**

Create `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config/TournamentConfigStore.swift`:

```swift
import Foundation

/// Provides the active tournament config to non-SwiftUI code (services, singletons).
/// Set once at app launch before any service is accessed.
public final class TournamentConfigStore: @unchecked Sendable {
    public static var current: any TournamentConfig = DefaultTournamentConfig()
}
```

- [ ] **Step 5: Run tests to verify they pass**

Product → Test (⌘U)  
Expected: both `TournamentConfig` tests pass

- [ ] **Step 6: Commit**

```bash
git add AFCONiOSApp/TournamentKit/
git commit -m "feat: add TournamentConfig protocol and TournamentConfigStore"
```

---

## Task 3: TournamentViewFactory + Update AppView and HeaderView

**Files:**
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config/TournamentViewFactory.swift`
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views/AppView.swift` (new version)
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views/LaunchScreen.swift`
- Create: `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views/HeaderView.swift` (new version)
- Delete: `AFCONiOSApp/AFCON2025/Views/AppView.swift` (after replacing)
- Delete: `AFCONiOSApp/AFCON2025/Views/HeaderView.swift` (after replacing)

**Interfaces:**
- Consumes: `TournamentConfig` (Task 2)
- Produces:
  - `TournamentViewFactory` protocol with `makeHomeView() -> some View`
  - `AppView<Factory: TournamentViewFactory>` generic struct
  - `HeaderView` reads `@Environment(\.tournamentConfig)` for name and accent color
  - `LaunchScreen` reads `@Environment(\.tournamentConfig)` for gradient colors and competition name

- [ ] **Step 1: Create TournamentViewFactory.swift**

Create `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Config/TournamentViewFactory.swift`:

```swift
import SwiftUI

public protocol TournamentViewFactory {
    associatedtype HomeViewType: View
    @ViewBuilder func makeHomeView() -> HomeViewType
}
```

- [ ] **Step 2: Create LaunchScreen.swift in TournamentKit**

Create `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views/LaunchScreen.swift`:

```swift
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
```

- [ ] **Step 3: Create AppView.swift in TournamentKit**

Create `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views/AppView.swift`:

```swift
import SwiftUI
import SwiftData

public struct AppView<Factory: TournamentViewFactory>: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showOnboarding = !AppSettings.shared.hasCompletedOnboarding
    @State private var isLoading = true

    private let factory: Factory
    private let fixturesRefreshInterval: TimeInterval = 6 * 60 * 60

    public init(factory: Factory) {
        self.factory = factory
    }

    public var body: some View {
        ZStack {
            if isLoading {
                LaunchScreen()
            } else if showOnboarding {
                OnboardingView {
                    completeOnboarding()
                }
            } else {
                factory.makeHomeView()
            }
        }
        .onAppear {
            AppSettings.shared.updateLastLaunchVersion()
            Task { await AppNotificationService.shared.clearBadge() }
            loadFavoriteTeams()
            Task { await AppNotificationService.shared.syncIfPossibleOnLaunch() }
            Task { await refreshFixturesOnLaunchIfNeeded() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) { isLoading = false }
            }
        }
    }

    private func completeOnboarding() {
        AppSettings.shared.completeOnboarding()
        withAnimation { showOnboarding = false }
    }

    private func loadFavoriteTeams() {
        let descriptor = FetchDescriptor<FavoriteTeam>()
        do {
            let favorites = try modelContext.fetch(descriptor)
            AppSettings.shared.selectedFavoriteTeamIds = favorites.map { $0.teamId }
        } catch {
            print("❌ Failed to load favorite teams: \(error)")
        }
    }

    private func refreshFixturesOnLaunchIfNeeded() async {
        guard shouldRefreshFixturesOnLaunch() else { return }
        let manager = FixtureDataManager(modelContext: modelContext)
        await manager.syncAllFixtures()
    }

    private func shouldRefreshFixturesOnLaunch() -> Bool {
        guard let lastSync = AppSettings.shared.lastFixturesSyncAt else { return true }
        return Date().timeIntervalSince(lastSync) >= fixturesRefreshInterval
    }
}
```

- [ ] **Step 4: Create HeaderView.swift in TournamentKit**

Create `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Views/HeaderView.swift`:

```swift
import SwiftUI

public struct HeaderView: View {
    @Environment(\.tournamentConfig) private var config
    @State private var showingSettings = false

    public init() {}

    public var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.competitionName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("Live Competition")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(config.accentColorName), Color(config.secondaryColorName)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }
}
```

- [ ] **Step 5: Remove old AppView.swift and HeaderView.swift from AFCON2025 target**

In Xcode:
1. Delete `AFCON2025/Views/AppView.swift` (Move to Trash)
2. Delete `AFCON2025/Views/HeaderView.swift` (Move to Trash)
3. Build (`⌘B`) — expect errors about missing `AppView` and `HeaderView`, resolved in Task 9

- [ ] **Step 6: Commit**

```bash
git add AFCONiOSApp/TournamentKit/
git commit -m "feat: add TournamentViewFactory protocol and config-driven AppView/HeaderView"
```

---

## Task 4: Move Models to TournamentKit

**Files:**
- Move+public: `FixtureModel`, `FixtureEventModel`, `Match`, `TeamModels`, `LiveScoreActivityAttributes`
- Delete originals from `AFCON2025/Models/`

**Interfaces:**
- Produces: public SwiftData models usable from both app targets and TournamentKit services

> **SwiftData Note:** Moving `@Model` classes changes their fully qualified name from `AFCON2025.FixtureModel` to `TournamentKit.FixtureModel`. The existing store will fail to open and be automatically deleted and recreated (see the error-handling code already in `AFCON2025App.swift`). This is acceptable — fixtures are re-fetched from the server on first launch.

- [ ] **Step 1: Copy each model file into TournamentKit, add `public`**

For each file in `AFCON2025/Models/` (`FixtureModel.swift`, `FixtureEventModel.swift`, `Match.swift`, `TeamModels.swift`, `LiveScoreActivityAttributes.swift`):

1. Copy the file to `AFCONiOSApp/TournamentKit/Sources/TournamentKit/Models/`
2. Add `public` to every `class`, `struct`, `enum`, and `init` that was implicitly `internal`
3. Ensure `import SwiftData` is present where needed

Example transformation for a model:
```swift
// Before (in AFCON2025 target)
@Model
class FixtureModel { ... }

// After (in TournamentKit)
import SwiftData
@Model
public class FixtureModel { ... }
// All stored properties and inits must also be public
```

- [ ] **Step 2: Add TournamentKit model files to Xcode project**

In Xcode, drag the `TournamentKit/Sources/TournamentKit/Models/` folder into the Package Navigator — SPM picks them up automatically via the package.

- [ ] **Step 3: Delete originals from AFCON2025 target**

In Xcode, select all 5 files in `AFCON2025/Models/` → Delete → Move to Trash.

- [ ] **Step 4: Build and fix import errors**

`⌘B`. All files in `AFCON2025` that imported these types now get them from TournamentKit (since TournamentKit is already linked). Fix any remaining `import` or access-level errors.

- [ ] **Step 5: Commit**

```bash
git add AFCONiOSApp/TournamentKit/Sources/TournamentKit/Models/
git commit -m "feat: move SwiftData models to TournamentKit"
```

---

## Task 5: Move Common Utilities and Extensions to TournamentKit

**Files:**
- Move+public: `AppSettings`, `HomeWidgetSnapshotStore`
- Move+modify: `TeamFlagMapper` (static, reads map from `TournamentConfigStore.current`)
- Move+public: `GRPCModelExtensions`, `FixtureEventExtensions`, `String+TeamNames`
- Move+public: `LiveActivityDiagnostics`
- Delete all originals from `AFCON2025/Common/` and `AFCON2025/Extensions/`

**Interfaces:**
- Produces:
  - `public final class AppSettings` — unchanged API, moved
  - `public struct TeamFlagMapper` — unchanged static call sites; reads `TournamentConfigStore.current.teamFlagMap`

- [ ] **Step 1: Copy AppSettings, HomeWidgetSnapshotStore to TournamentKit**

Copy `AFCON2025/Common/AppSettings.swift` → `TournamentKit/Sources/TournamentKit/Common/AppSettings.swift`

Add `public` to the class, all `var`s, `func`s, `enum AppLanguage`, and `init`:

```swift
public final class AppSettings { ... }
public enum AppLanguage: String, CaseIterable, Identifiable { ... }
```

Do the same for `HomeWidgetSnapshotStore.swift` and `LiveActivityDiagnostics.swift`.

- [ ] **Step 2: Create TeamFlagMapper.swift in TournamentKit**

Create `TournamentKit/Sources/TournamentKit/Common/TeamFlagMapper.swift`:

```swift
import Foundation

/// Maps API-Football team IDs to asset image names.
/// Reads the active tournament's map from TournamentConfigStore so all existing
/// static call sites (TeamFlagMapper.flagAssetName(for:)) require no changes.
public struct TeamFlagMapper {
    public static func flagAssetName(for teamId: Int) -> String? {
        TournamentConfigStore.current.teamFlagMap[teamId]
    }

    public static func fifaCode(for teamId: Int) -> String? {
        TournamentConfigStore.current.teamFlagMap[teamId]
    }
}
```

- [ ] **Step 3: Copy extension files to TournamentKit**

Copy `GRPCModelExtensions.swift`, `FixtureEventExtensions.swift`, `String+TeamNames.swift` from `AFCON2025/Extensions/` → `TournamentKit/Sources/TournamentKit/Extensions/`

Add `public` to every extension and method.

- [ ] **Step 4: Delete originals from AFCON2025**

Delete `AFCON2025/Common/AppSettings.swift`, `HomeWidgetSnapshotStore.swift`, `LiveActivityDiagnostics.swift`, `TeamFlagMapper.swift`  
Delete `AFCON2025/Extensions/GRPCModelExtensions.swift`, `FixtureEventExtensions.swift`, `String+TeamNames.swift`

Build (`⌘B`) and fix any remaining access errors.

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: move common utilities and extensions to TournamentKit"
```

---

## Task 6: Move Services to TournamentKit

**Files:**
- Create: `TournamentKit/Sources/TournamentKit/Services/TournamentServiceWrapper.swift` (renamed from `AFCONServiceWrapper.swift`)
- Move+update: `FixtureDataManager`, `LiveMatchStreamService` — use `TournamentConfigStore.current`
- Move+public: `LiveActivityManager`, `NotificationService`, `BundledFixturesLoader`, `LogoCacheManager`, `FavoriteTeamSyncService`, `MockDataProvider`
- Create: `TournamentKit/Sources/TournamentKit/Config/AppGroupWriter.swift`
- Delete: all originals from `AFCON2025/Services/`

**Interfaces:**
- Consumes: `TournamentConfigStore.current` for leagueId/season in service calls
- Produces:
  - `public class TournamentServiceWrapper` — same API as `AFCONServiceWrapper`, default params now read from `TournamentConfigStore.current`
  - `public func writeTournamentConfigToAppGroup(_ config: any TournamentConfig)`

- [ ] **Step 1: Create TournamentServiceWrapper.swift**

Create `TournamentKit/Sources/TournamentKit/Services/TournamentServiceWrapper.swift`:

Copy the content of `AFCONServiceWrapper.swift` into this file, then:
1. Rename the class: `class AFCONServiceWrapper` → `public class TournamentServiceWrapper`
2. Update all default parameter values to read from `TournamentConfigStore`:

```swift
import Foundation
import Observation
import AFCONClient

@Observable
public class TournamentServiceWrapper {
    private static let defaultHost = ProcessInfo.processInfo.environment["AFCON_API_HOST"]
        ?? "staging-grpc-nlb-823dd7fe6a5be8b9.elb.eu-north-1.amazonaws.com"
    private static let defaultPort = Int(ProcessInfo.processInfo.environment["AFCON_API_PORT"] ?? "") ?? 50051

    private let service: AFCONService

    public init(host: String = defaultHost, port: Int = defaultPort) {
        self.service = AFCONService(host: host, port: port)
    }

    private var config: any TournamentConfig { TournamentConfigStore.current }

    public func getLeague(
        leagueId: Int32? = nil, season: Int32? = nil
    ) async throws -> Afcon_LeagueResponse {
        try await service.getLeague(
            leagueId: leagueId ?? config.leagueId,
            season: season ?? config.season
        )
    }

    // Repeat this pattern for every method: replace `= 6` / `= 2025` defaults
    // with `leagueId: Int32? = nil` / `season: Int32? = nil` and fall back to
    // `config.leagueId` / `config.season` in the body.

    // Keep the full implementation for all other methods (getTeams, getFixtures,
    // getLiveFixtures, getFixturesByDate, getTeamDetails, getStandings,
    // getLineups, getFixtureEvents, streamLiveMatches, syncFixtures,
    // registerDevice, updateFavoriteTeam, updateFavoriteTeams,
    // getSubscriptions, startLiveActivity, endLiveActivity).
    // The pattern is identical for each: optional params default to config values.
}

extension TournamentServiceWrapper {
    public static let shared = TournamentServiceWrapper()
}
```

> **Important:** Every method that previously had `leagueId: Int32 = 6` or `season: Int32 = 2025` must change its signature to `leagueId: Int32? = nil, season: Int32? = nil` and resolve in the body. This avoids callers needing to know the current config.

- [ ] **Step 2: Update FixtureDataManager**

Copy `AFCON2025/Services/FixtureDataManager.swift` → `TournamentKit/Sources/TournamentKit/Services/FixtureDataManager.swift`

Changes:
1. Add `public` to class, all methods, and `init`
2. Replace `private let service: AFCONServiceWrapper` → `private let service: TournamentServiceWrapper`
3. Replace `AFCONServiceWrapper.shared` → `TournamentServiceWrapper.shared`
4. Change `initializeFixtures(leagueId: Int32 = 6, season: Int32 = 2025)` → `initializeFixtures()` and read from `TournamentConfigStore.current`:

```swift
public func initializeFixtures() async {
    let config = TournamentConfigStore.current
    let leagueId = config.leagueId
    let season = config.season
    // rest of the method unchanged, using local `leagueId` and `season`
}
```

Apply the same pattern to `syncAllFixtures()`, `syncLiveFixtures()`, and any other method with hardcoded IDs.

- [ ] **Step 3: Update LiveMatchStreamService**

Copy `AFCON2025/Services/LiveMatchStreamService.swift` → `TournamentKit/Sources/TournamentKit/Services/LiveMatchStreamService.swift`

Changes:
1. Add `public` to class and all methods
2. Replace `private let service = AFCONServiceWrapper.shared` → `private let service = TournamentServiceWrapper.shared`
3. Any call with `leagueId: 6, season: 2025` → use `TournamentConfigStore.current.leagueId` / `.season`

- [ ] **Step 4: Copy remaining service files**

Copy the following files from `AFCON2025/Services/` → `TournamentKit/Sources/TournamentKit/Services/`, adding `public` to all top-level types and methods:
- `LiveActivityManager.swift`
- `NotificationService.swift`
- `BundledFixturesLoader.swift`
- `LogoCacheManager.swift`
- `FavoriteTeamSyncService.swift`
- `MockDataProvider.swift`

For `AppGroup.swift` — do not move it. Instead replace it with:

```swift
// In TournamentKit, AppGroup is no longer a separate file.
// Use TournamentConfigStore.current.appGroupIdentifier directly.
```

Update all references in the moved files from `AppGroup.identifier` → `TournamentConfigStore.current.appGroupIdentifier`.

- [ ] **Step 5: Create AppGroupWriter.swift**

Create `TournamentKit/Sources/TournamentKit/Config/AppGroupWriter.swift`:

```swift
import Foundation

/// Called at app launch to write the active tournament config into the shared
/// AppGroup UserDefaults, so the widget can read it without knowing the target.
public func writeTournamentConfigToAppGroup(_ config: any TournamentConfig) {
    guard let defaults = UserDefaults(suiteName: config.appGroupIdentifier) else { return }
    defaults.set(Int(config.leagueId),  forKey: "tournamentLeagueId")
    defaults.set(Int(config.season),    forKey: "tournamentSeason")
    defaults.set(config.competitionName, forKey: "tournamentName")
    defaults.set(config.groupCount,     forKey: "tournamentGroupCount")
}
```

- [ ] **Step 6: Delete originals from AFCON2025/Services/**

Delete `AFCONService.swift` (was `AFCONServiceWrapper` — replaced by `TournamentServiceWrapper`), `FixtureDataManager.swift`, `LiveMatchStreamService.swift`, `LiveActivityManager.swift`, `NotificationService.swift`, `BundledFixturesLoader.swift`, `LogoCacheManager.swift`, `FavoriteTeamSyncService.swift`, `MockDataProvider.swift`, `AppGroup.swift`.

Build (`⌘B`) and fix errors.

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "feat: move services to TournamentKit, replace AFCONServiceWrapper with TournamentServiceWrapper"
```

---

## Task 7: Move ViewModels to TournamentKit

**Files:**
- Move+public: `ScheduleViewModel`, `LiveScoresViewModel`, `GroupsViewModel`, `BracketViewModel`
- Delete originals from `AFCON2025/ViewModels/`

**Interfaces:**
- Produces: public `@Observable @MainActor` view models using `TournamentServiceWrapper`

- [ ] **Step 1: Copy ViewModels, add public, update service references**

Copy each file from `AFCON2025/ViewModels/` → `TournamentKit/Sources/TournamentKit/ViewModels/`

For each:
1. Add `public` to class declaration and all `init`s and public methods
2. Replace any `AFCONServiceWrapper` reference with `TournamentServiceWrapper`
3. Replace any `leagueId: 6` / `season: 2025` literals with `TournamentConfigStore.current.leagueId` / `.season`

- [ ] **Step 2: Delete originals from AFCON2025/ViewModels/**

Build (`⌘B`) — verify no references remain in the AFCON2025 target.

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "feat: move view models to TournamentKit"
```

---

## Task 8: Move Shared Views to TournamentKit

**Files:**
- Move+public: all views in `AFCON2025/Views/` that are **not** tournament-specific
- Delete originals from `AFCON2025/Views/`
- Keep in `AFCON2025/Views/`: `AFCONHomeView.swift`, `GroupsView.swift`, `BracketView.swift`

Tournament-specific views to keep in `AFCON2025/Views/`:
- `AFCONHomeView.swift` — references `GroupsView`, `BracketView`, `moroccoRed` tint
- `GroupsView.swift` — 6-group AFCON layout
- `BracketView.swift` — AFCON knockout bracket

Everything else moves to `TournamentKit/Sources/TournamentKit/Views/`.

**Interfaces:**
- Produces: all shared views public, importing TournamentKit from either target

- [ ] **Step 1: Copy shared views to TournamentKit, add public**

Copy these files from `AFCON2025/Views/` → `TournamentKit/Sources/TournamentKit/Views/`, adding `public` to every struct/class/init:

`OnboardingView.swift`, `LiveScoresView.swift`, `ScheduleView.swift`, `ScheduleViewNew.swift`, `FixturesListView.swift`, `MatchCard.swift`, `FinishedMatchCard.swift`, `PenaltyShootoutView.swift`, `QuickStatsBar.swift`, `QuickStatsBarLive.swift`, `LiveMatchData.swift`, `SettingsView.swift`, `NotificationSettingsView.swift`, `NotificationPermissionView.swift`, `VenuesView.swift`, `SocialView.swift`, `LiveActivityDiagnosticsView.swift`, `Environment+TabBarMinimized.swift`

For any view that references a Morocco-specific color by name (e.g. `Color("moroccoRed")`), replace with `Color(config.accentColorName)` using `@Environment(\.tournamentConfig) private var config`.

- [ ] **Step 2: Update AFCONHomeView.swift**

`AFCONHomeView` stays in the `AFCON2025` target but the Morocco-specific tint should reference the asset name directly (it's fine since AFCON2025's own asset catalog has `moroccoRed`). No change needed.

- [ ] **Step 3: Delete moved files from AFCON2025/Views/**

Delete all the files you just moved (keep `AFCONHomeView.swift`, `GroupsView.swift`, `BracketView.swift`).

- [ ] **Step 4: Build and fix**

`⌘B` — fix any missing `public` or missing `import TournamentKit` errors.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: move shared views to TournamentKit"
```

---

## Task 9: Implement AFCON2025 Tournament-Specific Files

After this task, the `AFCON2025` target must build and run end-to-end.

**Files:**
- Create: `AFCON2025/Config/AFCONTournamentConfig.swift`
- Create: `AFCON2025/Config/AFCONViewFactory.swift`
- Modify: `AFCON2025/AFCON2025App.swift`
- Delete: `AFCON2025/Services/AppGroup.swift` (already done in Task 6)

**Interfaces:**
- Consumes: `TournamentConfig`, `TournamentViewFactory`, `TournamentConfigStore`, `writeTournamentConfigToAppGroup` (Tasks 2–6)
- Produces: building, runnable AFCON2025 target

- [ ] **Step 1: Create AFCONTournamentConfig.swift**

Create `AFCON2025/Config/AFCONTournamentConfig.swift`:

```swift
import TournamentKit

struct AFCONTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 6
    let season: Int32 = 2025
    let competitionName = "AFCON 2025"
    let groupCount = 6
    let teamCount = 24
    let accentColorName = "moroccoGreen"
    let secondaryColorName = "moroccoRed"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    let teamFlagMap: [Int: String] = [
        13: "SEN", 19: "NGA", 28: "TUN", 31: "MAR", 32: "EGY",
        1489: "TAN", 1500: "MLI", 1501: "CIV", 1502: "BFA", 1503: "GAB",
        1507: "ZAM", 1508: "COD", 1510: "SDN", 1512: "MOZ", 1516: "BEN",
        1519: "UGA", 1520: "BOT", 1521: "EQG", 1522: "ZIM", 1524: "COM",
        1529: "ANG", 1530: "CMR", 1531: "RSA", 1532: "ALG"
    ]
}
```

- [ ] **Step 2: Create AFCONViewFactory.swift**

Create `AFCON2025/Config/AFCONViewFactory.swift`:

```swift
import SwiftUI
import TournamentKit

struct AFCONViewFactory: TournamentViewFactory {
    func makeHomeView() -> some View {
        AFCONHomeView()
    }
}
```

- [ ] **Step 3: Update AFCON2025App.swift**

Replace the `body` in `AFCON2025App.swift`:

```swift
import SwiftUI
import SwiftData
import BackgroundTasks
import TournamentKit

@main
struct AFCON2025App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationService = AppNotificationService.shared

    private let tournamentConfig = AFCONTournamentConfig()

    var sharedModelContainer: ModelContainer = { /* unchanged */ }()

    var body: some Scene {
        WindowGroup {
            AppView(factory: AFCONViewFactory())
                .environment(\.tournamentConfig, tournamentConfig)
                .environmentObject(notificationService)
                .onAppear {
                    // Write config to AppGroup so the widget can read it
                    writeTournamentConfigToAppGroup(AFCONTournamentConfig())
                    notificationService.setupNotificationCategories()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

Also add at the top of `application(_:didFinishLaunchingWithOptions:)` in `AppDelegate`:

```swift
TournamentConfigStore.current = AFCONTournamentConfig()
```

This ensures `TournamentConfigStore.current` is set before any service singleton initializes.

- [ ] **Step 4: Build and run**

`⌘R` on the `AFCON2025` scheme. Verify:
- App launches (LaunchScreen shows with Morocco colors and "AFCON 2025")
- Onboarding or HomeView appears after 1.5 s
- Header shows "AFCON 2025"
- Fixtures load

- [ ] **Step 5: Write and run a basic integration test**

Add to `AFCON2025Tests/AFCON2025Tests.swift`:

```swift
import Testing
import TournamentKit

@Suite("AFCON2025 Integration")
struct AFCON2025IntegrationTests {
    @Test("AFCONTournamentConfig has correct values")
    func configValues() {
        let config = AFCONTournamentConfig()
        #expect(config.leagueId == 6)
        #expect(config.season == 2025)
        #expect(config.groupCount == 6)
        #expect(config.teamFlagMap[31] == "MAR")
    }
}
```

Run (`⌘U`). Expected: passes.

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: implement AFCON2025 tournament-specific config and factory"
```

---

## Task 10: Update LiveScoreWidget

**Files:**
- Modify: `AFCONiOSApp/LiveScoreWidget/LiveScoreScheduleWidget.swift`
- Modify: `AFCONiOSApp/LiveScoreWidget/LiveScoreHomeWidget.swift` (if it reads league info)
- Delete: `AFCONiOSApp/LiveScoreWidget/TeamFlagMapper.swift` (duplicate — use `TournamentKit` instead)

The widget must not import `TournamentKit` (widget extensions have a separate link unit). It reads config written by the main app via `AppGroup` `UserDefaults`.

**Interfaces:**
- Consumes: `UserDefaults(suiteName: "group.com.cheulah.afcon")` keys written by `writeTournamentConfigToAppGroup`

- [ ] **Step 1: Replace any hardcoded league ID / season in the widget**

In `LiveScoreScheduleWidget.swift` and `LiveScoreHomeWidget.swift`, replace:

```swift
// Before
let leagueId: Int32 = 6
let season: Int32 = 2025
```

With:

```swift
private func loadTournamentConfig() -> (leagueId: Int32, season: Int32, name: String) {
    let defaults = UserDefaults(suiteName: "group.com.cheulah.afcon")
    let leagueId = Int32(defaults?.integer(forKey: "tournamentLeagueId") ?? 6)
    let season   = Int32(defaults?.integer(forKey: "tournamentSeason")   ?? 2025)
    let name     = defaults?.string(forKey: "tournamentName") ?? "AFCON 2025"
    return (leagueId, season, name)
}
```

Call `loadTournamentConfig()` from `getTimeline(in:completion:)` and pass values to your network requests.

- [ ] **Step 2: Delete duplicate TeamFlagMapper in widget**

If `LiveScoreWidget/TeamFlagMapper.swift` exists, delete it. The widget should use its own local copy of the AFCON mapping (since it can't import TournamentKit). Keep a minimal local version:

Create `LiveScoreWidget/AFCONTeamFlags.swift`:

```swift
// Minimal mapping for widget — kept in sync with AFCONTournamentConfig.teamFlagMap
let afconTeamFlagMap: [Int: String] = [
    13: "SEN", 19: "NGA", 28: "TUN", 31: "MAR", 32: "EGY",
    1489: "TAN", 1500: "MLI", 1501: "CIV", 1502: "BFA", 1503: "GAB",
    1507: "ZAM", 1508: "COD", 1510: "SDN", 1512: "MOZ", 1516: "BEN",
    1519: "UGA", 1520: "BOT", 1521: "EQG", 1522: "ZIM", 1524: "COM",
    1529: "ANG", 1530: "CMR", 1531: "RSA", 1532: "ALG"
]

func flagAssetName(for teamId: Int) -> String? {
    afconTeamFlagMap[teamId]
}
```

When WC is active, the widget falls back to showing a generic icon if a team ID isn't in the map — acceptable since WC team flags will be added in Task 11.

- [ ] **Step 3: Build the widget extension**

Select the widget scheme and build (`⌘B`). Fix any errors.

- [ ] **Step 4: Commit**

```bash
git add AFCONiOSApp/LiveScoreWidget/
git commit -m "feat: make widget tournament-aware via AppGroup config"
```

---

## Task 11: Create FWC2026 Xcode Target

**Files:**
- Create: `AFCONiOSApp/FWC2026/FWC2026App.swift`
- Create: `AFCONiOSApp/FWC2026/Config/FWCTournamentConfig.swift`
- Create: `AFCONiOSApp/FWC2026/Config/FWCViewFactory.swift`
- Create: `AFCONiOSApp/FWC2026/Views/FWCHomeView.swift`
- Create: `AFCONiOSApp/FWC2026/Views/FWCGroupsView.swift`
- Create: `AFCONiOSApp/FWC2026/Views/FWCBracketView.swift`
- Create: `AFCONiOSApp/FWC2026/Assets.xcassets` (WC colors + team flag placeholders)

**Interfaces:**
- Consumes: `TournamentKit` (all Tasks above)
- Produces: `FWC2026` target that builds cleanly and launches with WC branding

- [ ] **Step 1: Add FWC2026 target in Xcode**

1. File → New → Target → iOS App
2. Product Name: `FWC2026`, Bundle Identifier: `com.cheulah.afcon2025` (same as AFCON2025)
3. Uncheck "Include Tests" (share the existing test target)
4. After creation, in the target's Build Phases → Link Binary with Libraries, add `TournamentKit`
5. In Signing & Capabilities, add the AppGroup `group.com.cheulah.afcon`
6. Set Minimum Deployment: iOS 17

- [ ] **Step 2: Create FWCTournamentConfig.swift**

Create `FWC2026/Config/FWCTournamentConfig.swift`:

```swift
import TournamentKit

struct FWCTournamentConfig: TournamentConfig {
    let leagueId: Int32 = 1
    let season: Int32 = 2026
    let competitionName = "FIFA World Cup 2026"
    let groupCount = 12
    let teamCount = 48
    let accentColorName = "fifaBlue"
    let secondaryColorName = "fifaGold"
    let appGroupIdentifier = "group.com.cheulah.afcon"
    // Populate once the WC team IDs from API-Football are known
    let teamFlagMap: [Int: String] = [:]
}
```

- [ ] **Step 3: Create placeholder WC views**

Create `FWC2026/Views/FWCGroupsView.swift`:

```swift
import SwiftUI
import TournamentKit

public struct FWCGroupsView: View {
    @Environment(\.tournamentConfig) private var config

    public var body: some View {
        ContentUnavailableView(
            "Groups — Coming Soon",
            systemImage: "trophy.fill",
            description: Text("12 groups for \(config.competitionName)")
        )
    }
}
```

Create `FWC2026/Views/FWCBracketView.swift`:

```swift
import SwiftUI
import TournamentKit

public struct FWCBracketView: View {
    public var body: some View {
        ContentUnavailableView(
            "Bracket — Coming Soon",
            systemImage: "chart.bar.doc.horizontal"
        )
    }
}
```

Create `FWC2026/Views/FWCHomeView.swift` (mirrors `AFCONHomeView` but uses FWC views):

```swift
import SwiftUI
import SwiftData
import TournamentKit

struct FWCHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tournamentConfig) private var config
    @State private var selectedTab: Int?
    @State private var isInitializingFixtures = false
    @State private var hasCheckedFixtures = false
    @State private var liveScoresViewModel: LiveScoresViewModel?

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            TabView(selection: Binding(
                get: { selectedTab ?? 0 },
                set: { selectedTab = $0 }
            )) {
                if let viewModel = liveScoresViewModel {
                    LiveScoresView(viewModel: viewModel, onOpenSchedule: { selectedTab = 2 })
                        .tabItem { Label("Live", systemImage: "bolt.fill") }
                        .tag(0)
                } else {
                    ProgressView("Initializing...")
                        .tabItem { Label("Live", systemImage: "bolt.fill") }
                        .tag(0)
                }
                FWCGroupsView()
                    .tabItem { Label("Groups", systemImage: "trophy.fill") }
                    .tag(1)
                ScheduleViewNew()
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                    .tag(2)
                FWCBracketView()
                    .tabItem { Label("Bracket", systemImage: "chart.bar.doc.horizontal") }
                    .tag(3)
            }
            .tint(Color(config.accentColorName))
        }
        .onAppear {
            if liveScoresViewModel == nil {
                liveScoresViewModel = LiveScoresViewModel(modelContext: modelContext)
            }
            selectedTab = selectedTab ?? 0
            Task { await checkAndInitializeFixtures() }
        }
    }

    @MainActor
    private func checkAndInitializeFixtures() async {
        guard !hasCheckedFixtures else { return }
        hasCheckedFixtures = true
        let descriptor = FetchDescriptor<FixtureModel>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        let dataManager = FixtureDataManager(modelContext: modelContext)
        if count == 0 {
            isInitializingFixtures = true
            await dataManager.initializeFixtures()
            isInitializingFixtures = false
        }
        await dataManager.syncLiveFixtures()
        if let vm = liveScoresViewModel {
            await vm.fetchLiveMatches()
            vm.startLiveUpdates()
        }
    }
}
```

- [ ] **Step 4: Create FWCViewFactory.swift**

Create `FWC2026/Config/FWCViewFactory.swift`:

```swift
import SwiftUI
import TournamentKit

struct FWCViewFactory: TournamentViewFactory {
    func makeHomeView() -> some View {
        FWCHomeView()
    }
}
```

- [ ] **Step 5: Create FWC2026App.swift**

Create `FWC2026/FWC2026App.swift`:

```swift
import SwiftUI
import SwiftData
import BackgroundTasks
import TournamentKit

@main
struct FWC2026App: App {
    @UIApplicationDelegateAdaptor(FWCAppDelegate.self) var appDelegate
    @StateObject private var notificationService = AppNotificationService.shared

    private let tournamentConfig = FWCTournamentConfig()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FixtureModel.self, FixtureEventModel.self, FavoriteTeam.self])
        guard let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Could not find application support directory")
        }
        let dirURL = appSupportURL.appendingPathComponent("FWC2026", isDirectory: true)
        try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        let storeURL = dirURL.appendingPathComponent("fwc2026.store")
        let config = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            try? FileManager.default.removeItem(at: storeURL)
            return try! ModelContainer(for: schema, configurations: [
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            ])
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView(factory: FWCViewFactory())
                .environment(\.tournamentConfig, tournamentConfig)
                .environmentObject(notificationService)
                .onAppear {
                    writeTournamentConfigToAppGroup(FWCTournamentConfig())
                    notificationService.setupNotificationCategories()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

class FWCAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        TournamentConfigStore.current = FWCTournamentConfig()
        AppNotificationService.shared.setupNotificationCategories()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppNotificationService.shared.setDeviceToken(deviceToken)
    }
}
```

- [ ] **Step 6: Add WC color assets**

In `FWC2026/Assets.xcassets`:
1. Add color set `fifaBlue` — e.g. `#003B8E` (light) / `#002D6E` (dark)
2. Add color set `fifaGold` — e.g. `#B89A2D` (light) / `#A08520` (dark)
3. Add team flag imagesets for WC teams as they become known (use placeholder SVG for now)

- [ ] **Step 7: Build and run FWC2026 scheme**

Select `FWC2026` scheme → `⌘R`

Verify:
- LaunchScreen shows with blue/gold WC gradient and "FIFA World Cup 2026" title
- Header shows "FIFA World Cup 2026"
- Live tab shows (empty, no WC fixtures yet — expected)
- Groups tab shows "Coming Soon" placeholder
- Bracket tab shows "Coming Soon" placeholder

- [ ] **Step 8: Write and run integration test**

Add to `AFCON2025Tests/AFCON2025Tests.swift` (or a new test target for FWC2026):

```swift
@Test("FWCTournamentConfig has correct values")
func fwcConfigValues() {
    let config = FWCTournamentConfig()
    #expect(config.leagueId == 1)
    #expect(config.season == 2026)
    #expect(config.groupCount == 12)
    #expect(config.teamCount == 48)
    #expect(config.appGroupIdentifier == "group.com.cheulah.afcon")
}
```

Run (`⌘U`). Expected: passes.

- [ ] **Step 9: Commit**

```bash
git add AFCONiOSApp/FWC2026/
git commit -m "feat: add FWC2026 target with placeholder WC views and FWCTournamentConfig"
```

---

## Verification Checklist

After all tasks are complete:

- [ ] `AFCON2025` scheme builds and runs — LaunchScreen green/red, Header "AFCON 2025", fixtures load
- [ ] `FWC2026` scheme builds and runs — LaunchScreen blue/gold, Header "FIFA World Cup 2026"
- [ ] Both schemes share the same bundle ID `com.cheulah.afcon2025`
- [ ] Widget builds for both schemes (reads from AppGroup — no changes needed per scheme)
- [ ] `TournamentKitTests` suite passes
- [ ] No `#if` compile-time tournament flags in any file
- [ ] `AFCONServiceWrapper` no longer exists anywhere — replaced by `TournamentServiceWrapper`
- [ ] Archive `AFCON2025` scheme → can upload to App Store Connect
- [ ] Archive `FWC2026` scheme → can upload as update to same App Store listing
