# Bundled Fixtures - Offline Tournament Schedule

This app includes pre-loaded AFCON 2025 tournament fixtures that are available **immediately offline** without requiring any server connection.

## How It Works

### 1. Bundled JSON Files (Multilingual)
- **Files**:
  - `InitialFixtures_en.json` (English)
  - `InitialFixtures_fr.json` (French)
  - `InitialFixtures_ar.json` (Arabic)
- Contains all tournament fixtures in JSON format for each language
- Team names, venue names, and cities are localized
- Automatically loads the correct file based on user's device language
- Included in the app bundle at build time
- No internet required to access

### 2. Automatic Loading
On **first app launch**:
1. App checks if SwiftData has any fixtures
2. If empty, loads fixtures from `InitialFixtures.json`
3. Populates SwiftData with tournament schedule
4. Shows brief loading overlay (< 1 second)
5. App is ready with full offline schedule

### 3. Fallback Mechanism
If bundled JSON fails to load:
- App automatically falls back to server fetch
- Ensures fixtures are always available
- Graceful degradation

## File Structure

### InitialFixtures.json Format
```json
[
  {
    "id": 1,
    "referee": "TBD",
    "timezone": "Africa/Casablanca",
    "timestamp": 1737918000,
    "venueId": 1,
    "venueName": "Stade Mohammed V",
    "venueCity": "Casablanca",
    "statusLong": "Not Started",
    "statusShort": "NS",
    "statusElapsed": 0,
    "homeTeamId": 1,
    "homeTeamName": "Morocco",
    "homeTeamLogo": "",
    "homeTeamWinner": false,
    "awayTeamId": 2,
    "awayTeamName": "Zambia",
    "awayTeamLogo": "",
    "awayTeamWinner": false,
    "homeGoals": 0,
    "awayGoals": 0,
    "halftimeHome": 0,
    "halftimeAway": 0,
    "fulltimeHome": 0,
    "fulltimeAway": 0,
    "competition": "AFCON 2025"
  }
]
```

## Updating Bundled Fixtures

### Option 1: Manual Update (Recommended Before Release)

1. **Get Tournament Schedule**:
   - Obtain official AFCON 2025 schedule
   - Collect all match details (teams, venues, dates)

2. **Update JSON Files** (All Three Languages):
   - Open `AFCON2025/Resources/InitialFixtures_en.json`
   - Open `AFCON2025/Resources/InitialFixtures_fr.json`
   - Open `AFCON2025/Resources/InitialFixtures_ar.json`
   - Add/edit fixture entries in each file
   - Ensure team names, venues, and cities are translated appropriately
   - Keep IDs, timestamps, and numeric data identical across all files
   - Ensure timestamps are correct (Unix timestamp format)

3. **Timestamp Conversion**:
   ```swift
   // Swift: Date to Unix timestamp
   let timestamp = Int(date.timeIntervalSince1970)

   // JavaScript/Online tool
   new Date('2025-01-26 20:00:00').getTime() / 1000
   ```

4. **Venue Information**:
   - Use actual venue IDs, names, and cities
   - Match format from API Football data

5. **Test**:
   - Delete app from simulator/device
   - Rebuild and run
   - Verify all fixtures load correctly

### Option 2: Export from Server (Automated)

Create a script to fetch and export fixtures:

```swift
// In Settings or admin panel
func exportFixturesToJSON() async {
    let service = AFCONServiceWrapper.shared
    let fixtures = try await service.getFixtures()

    // Convert to FixtureData models
    let fixtureData = fixtures.map { /* convert */ }

    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(fixtureData)

    // Save to file
    let documentsURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    let fileURL = documentsURL.appendingPathComponent("ExportedFixtures.json")
    try data.write(to: fileURL)

    print("Exported to: \(fileURL.path)")
}
```

Then copy the exported file to `Resources/InitialFixtures.json`

## Localization Strategy

### What Gets Translated

Each language file contains localized versions of:
- **Team Names**: "Morocco" → "Maroc" (FR) → "المغرب" (AR)
- **Venue Names**: "Stade Mohammed V" → "ملعب محمد الخامس" (AR)
- **City Names**: "Casablanca" → "الدار البيضاء" (AR)
- **Referee**: "TBD" → "À déterminer" (FR) → "لم يحدد بعد" (AR)
- **Status**: "Not Started" → "Pas commencé" (FR) → "لم تبدأ" (AR)
- **Competition**: "AFCON 2025" → "CAN 2025" (FR) → "كأس الأمم الأفريقية 2025" (AR)

### What Stays Identical

The following fields remain the same across all language files:
- **IDs**: `id`, `venueId`, `homeTeamId`, `awayTeamId`
- **Timestamps**: `timestamp` (Unix timestamp)
- **Timezone**: `timezone`
- **Status Code**: `statusShort` (e.g., "NS", "LIVE", "FT")
- **Scores**: All goal and score fields
- **Flags**: `homeTeamWinner`, `awayTeamWinner`

### Automatic Selection

The app automatically detects the device language and loads:
- English speakers → `InitialFixtures_en.json`
- French speakers → `InitialFixtures_fr.json`
- Arabic speakers → `InitialFixtures_ar.json`
- All other languages → Default to English

## Current Fixtures

The current fixture files contain:
- **12 sample fixtures** representing group stage matches
- Realistic AFCON 2025 teams and venues
- Placeholder data (TBD referees, 0-0 scores)
- Timestamps starting from January 26, 2025

### Included Teams
- Morocco, Zambia, Gabon, Lesotho
- Mali, Mozambique, South Africa, Tunisia
- Egypt, Zimbabwe, Ghana, Angola
- Algeria, Burkina Faso, Senegal, DR Congo
- Nigeria, Benin, Ivory Coast, Cameroon

### Included Venues
1. Stade Mohammed V (Casablanca)
2. Grand Stade d'Agadir (Agadir)
3. Stade Prince Moulay Abdellah (Rabat)
4. Stade de Marrakech (Marrakech)

## Benefits

✅ **Instant Availability**: No waiting for server on first launch
✅ **Offline First**: Works without internet connection
✅ **Fast Loading**: Local JSON loads in milliseconds
✅ **Reliable**: No network errors or timeouts
✅ **Testable**: Easy to test with known data
✅ **Predictable**: Same data for all users initially

## Sync Strategy

### First Launch
- Loads bundled fixtures (offline)
- User can view schedule immediately

### During Tournament
- User can tap "Sync Live Matches" in Settings
- Updates scores and status for ongoing matches
- Preserves offline capability

### Manual Refresh
- "Initialize Fixtures" in Settings
- Fetches latest from server
- Overwrites bundled data with fresh tournament info

## File Checklist for Release

Before submitting to App Store:

- [ ] Update all three JSON files with complete tournament schedule:
  - [ ] `InitialFixtures_en.json` (English)
  - [ ] `InitialFixtures_fr.json` (French)
  - [ ] `InitialFixtures_ar.json` (Arabic)
- [ ] Verify all timestamps are correct and identical across all files
- [ ] Confirm all team names are properly translated in each language
- [ ] Validate all venue names and cities are localized correctly
- [ ] Test loading on fresh install with each language
- [ ] Verify all JSON files are valid (use JSONLint.com)
- [ ] Ensure all three files are included in Xcode target
- [ ] Test with airplane mode enabled for all three languages
- [ ] Verify locale switching works correctly (change device language)

## Implementation Files

1. **JSON Data (Multilingual)**:
   - `Resources/InitialFixtures_en.json` (English)
   - `Resources/InitialFixtures_fr.json` (French)
   - `Resources/InitialFixtures_ar.json` (Arabic)
2. **Loader Service**: `Services/BundledFixturesLoader.swift` (includes locale detection)
3. **Initialization Logic**: `Views/AFCONHomeView.swift` (checkAndInitializeFixtures)
4. **Data Model**: `Models/FixtureModel.swift`

## Troubleshooting

### Fixtures not loading?
1. Check all three files are in Xcode project navigator
2. Verify all files are in Target Membership (AFCON2025)
3. Clean build folder (⇧⌘K)
4. Rebuild project
5. Check console output for which locale/file is being loaded

### JSON parsing error?
1. Validate JSON syntax for all three files at JSONLint.com
2. Check all field names match `FixtureData` struct
3. Ensure no trailing commas
4. Verify UTF-8 encoding for Arabic text

### Wrong language showing?
1. Check device language settings (Settings > General > Language & Region)
2. Verify correct JSON file is being loaded (check console logs)
3. Confirm locale mapping in `BundledFixturesLoader.swift`
4. Delete app and reinstall to test fresh launch

### Wrong data showing?
1. Delete app from simulator/device
2. Clean SwiftData container
3. Rebuild and reinstall
4. Verify correct language file is loading

## Future Enhancements

- [ ] Add team logos to bundled data
- [ ] Include group information
- [ ] Pre-load knockout bracket structure
- [ ] Bundle team statistics
- [ ] Add venue images/coordinates
