# Widget Debugging Guide

## Added Comprehensive Logging

I've added detailed logging to help diagnose why the widget is showing empty. The logs will show exactly what's happening when the app saves data and when the widget tries to read it.

## How to Debug

### Step 1: Run the App and Check Logs

1. **Run the app on your device** in Xcode
2. Open **Console.app** or view logs in Xcode's console
3. Look for these log prefixes:
   - 🟢 **Green** = Main app (HomeWidgetSnapshotStore)
   - 🔵 **Blue** = Widget (AppGroupMatchStore)

### Step 2: Verify App is Saving Data

When the app fetches live match data, you should see:

```
🟢 HomeWidgetSnapshotStore - Saving snapshot for fixture 12345: Morocco vs Nigeria
🟢 HomeWidgetSnapshotStore - Container URL: /path/to/group.com.cheulah.afcon
🟢 HomeWidgetSnapshotStore - Encoded 1 snapshots (XXX bytes)
🟢 HomeWidgetSnapshotStore - Successfully wrote to: /path/to/live_match_snapshots.json
🟢 HomeWidgetSnapshotStore - File exists after write: true
🟢 HomeWidgetSnapshotStore - Total snapshots after save: 1
```

**If you see:**
- ❌ Container URL is **nil** → App Group is not configured correctly
- ❌ File write failed → Permission issue or disk space
- 🟢 No saves happening → The app isn't fetching/displaying matches

### Step 3: Check Widget Reading Data

Add the widget to your home screen, then check logs for:

```
🔵 AppGroupMatchStore - Container URL: /path/to/group.com.cheulah.afcon
🔵 AppGroupMatchStore - Snapshots URL: /path/to/live_match_snapshots.json
🔵 AppGroupMatchStore - File exists: true
🔵 AppGroupMatchStore - Data loaded: XXX bytes
🔵 AppGroupMatchStore - Decoded 1 snapshots
🔵 Widget - Found 1 snapshots
🔵 Widget - First match: Morocco vs Nigeria
🔵 Widget Timeline - Match data: Found
```

**If you see:**
- ❌ Container URL is **nil** → Widget doesn't have access to App Group
- ❌ File exists: **false** → Either app didn't save, or different container
- ❌ Failed to decode → Data format mismatch or corruption
- ❌ No snapshots found → File is empty or in wrong location

## Common Issues and Solutions

### Issue 1: Container URL is nil (Widget or App)

**Cause:** App Group not configured properly in provisioning profile

**Solution:**
1. Go to **Apple Developer Portal**
2. Check **Identifiers** → Your App ID
3. Verify **App Groups** capability is enabled
4. Make sure `group.com.cheulah.afcon` is checked
5. Regenerate provisioning profiles
6. In Xcode: **Preferences → Accounts → Download Manual Profiles**

### Issue 2: Different Container URLs

**Symptom:** App saves to one path, widget reads from different path

**Solution:**
- Both should show the SAME container URL
- If different, the App Group identifier doesn't match
- Check both `AFCON2025.entitlements` and `LiveScoreWidgetExtension.entitlements`
- Both should have: `group.com.cheulah.afcon`

### Issue 3: App Not Saving Data

**Symptom:** No green 🟢 logs appear

**Solution:**
1. Make sure you have live/upcoming matches
2. Try pulling to refresh in the Live Scores tab
3. Check that `fetchLiveMatches()` is being called
4. Verify matches are being processed in `LiveScoresViewModel`

### Issue 4: Widget Can't Decode Data

**Symptom:** Widget loads file but can't decode

**Solution:**
- The `LiveMatchWidgetSnapshot` struct must be **identical** in both targets
- Check that `HomeWidgetSnapshotStore.swift` is added to **LiveScoreWidgetExtension** target
- Clean build folder and rebuild

## Testing Checklist

- [ ] App Group capability enabled in both targets
- [ ] Same App Group ID in both entitlements files
- [ ] `AppGroup.swift` added to widget target membership
- [ ] `HomeWidgetSnapshotStore.swift` added to widget target membership
- [ ] App successfully saves data (check logs)
- [ ] Widget can read container URL (check logs)
- [ ] Widget finds and decodes snapshots (check logs)
- [ ] Provisioning profiles regenerated and downloaded

## Quick Test

1. Run app on device
2. Navigate to Live Scores tab
3. Pull to refresh to load matches
4. Check console for 🟢 save logs
5. Add widget to home screen
6. Check console for 🔵 widget logs
7. Widget should display match data

If you still see empty widget after all logs show success, please share the complete console output from both 🟢 and 🔵 logs.
