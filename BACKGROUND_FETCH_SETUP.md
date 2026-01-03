# Background Fetch Configuration

## What Changed

### Live Stream Management
The live match stream now continues running even when you switch tabs or put the app in the background. This prevents the "🚀 Starting / 🛑 Stopping" cycle every time you change tabs.

### New UI Features
1. **Pull to Refresh** - Swipe down to manually refresh live scores
2. **Countdown Timer** - Shows seconds until next automatic update (15s intervals)
3. **Removed Refresh Button** - Replaced with cleaner countdown display

## How It Works

1. **Global Stream Service** - `LiveMatchStreamService.shared` manages the gRPC stream globally
2. **Automatic Management** - Stream starts when there are live matches, stops when they finish
3. **Auto-Reconnection** - If the stream errors out, it automatically reconnects after 5 seconds
4. **Background Support** - Stream continues when app is in background (requires configuration below)

## Configuration Required

### Enable Background Modes in Xcode

1. Open your project in Xcode
2. Select the **AFCON2025** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Background Modes**
6. Check the following boxes:
   - ✅ **Background processing**
   - ✅ **Remote notifications** (if not already checked)

### Info.plist Configuration

The app uses the modern BackgroundTasks framework. The `Info.plist` includes:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.afcon2025.refresh</string>
</array>
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>remote-notification</string>
</array>
```

This configuration is already set up in the project.

## Behavior

### When App is Active
- Stream runs continuously when there are live matches
- Updates arrive in real-time via gRPC stream
- No need to refresh manually

### When Switching Tabs
- **Before**: Stream would stop and restart (causing "🚀 Starting / 🛑 Stopping" logs)
- **After**: Stream continues running in background
- No interruption to live updates

### When App Goes to Background
- iOS allows limited background execution time
- Stream will try to stay connected
- Background refresh tasks (BGAppRefreshTask) trigger periodically to keep stream alive
- Tasks are scheduled every 15 minutes when live matches are active
- When app returns to foreground, stream is already active

### When No Live Matches
- Stream automatically stops to save resources
- **Auto-restart rules:**
  1. **Every 30 seconds**: Background timer checks SwiftData for live matches
  2. **On manual refresh**: When user pulls to refresh or timer triggers fetch
  3. **When match status changes**: If fetch detects new live matches
  4. **From server push**: If push notification indicates live match
- No manual intervention needed - fully automatic!

## Logs to Watch For

### Good Signs ✅
```
🚀 Starting global live updates stream...
📡 Connecting to live updates stream...
📡 Live update for fixture 12345: GOAL
ℹ️ View disappeared but keeping stream active for other views
🔔 Checking for live matches: 2 found
✅ Scheduled background refresh task
📲 Background refresh task triggered
```

### Auto-Recovery ⚠️
```
❌ Stream error: Connection lost
⏳ Waiting 5 seconds before reconnecting...
🔄 Attempting to reconnect...
📡 Connecting to live updates stream...
```

### Normal Stop ✅
```
ℹ️ No more live matches, stopping stream...
🛑 Stopping global live updates stream...
```

### Auto-Restart ✅
```
🔔 Checking for live matches: 0 found
... (30 seconds later) ...
🔔 Checking for live matches: 1 found
🔔 Status check: Live matches detected, starting stream...
🚀 Starting global live updates stream...
📡 Connecting to live updates stream...
```

## Testing

### Testing Background Tasks in Xcode

To test background refresh tasks in the simulator/device:

1. **Run the app** from Xcode
2. **Pause execution** in Xcode debugger (⌘Y)
3. **Open LLDB console** and type:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.afcon2025.refresh"]
   ```
4. **Resume execution** (⌘⌃Y)
5. **Check console** for background task logs

Alternatively, use the **Simulate Background Fetch** option in Xcode's Debug menu while the app is running.

### Stream Persistence Test
1. **Start a live match** (or wait for one)
2. **Check console** - You should see: `🚀 Starting global live updates stream...`
3. **Switch to another tab** (Groups, Bracket, etc.)
4. **Check console** - You should see: `ℹ️ View disappeared but keeping stream active`
5. **Switch back to Live tab** - No "🚀 Starting" log (stream stayed active)
6. **Put app in background** - Stream continues (check background fetch logs)

### Countdown Timer Test
1. **Open Live Scores tab** with active live matches
2. **Look at top-right** - You should see a countdown timer (15s, 14s, 13s...)
3. **Wait for countdown** to reach 0 - Data automatically refreshes
4. **Pull down to refresh** - Manual refresh + countdown resets to 15s

### Auto-Restart Test
1. **Wait for all matches to finish** - Stream stops automatically
2. **Wait 30 seconds** - Status check runs
3. **When next match goes live** - Check console for: `🔔 Status check: Live matches detected`
4. **Stream restarts automatically** - No user action needed!

## Troubleshooting

### Stream Keeps Restarting
- Make sure you enabled **Background Modes** capability
- Check that stream service is properly initialized

### gRPC Errors When Returning to App
- This was the old behavior
- With the new setup, stream stays connected
- If you still see errors, check network connectivity

### High Battery Usage
- Stream only runs when there are live matches
- Stops automatically when matches finish
- Background fetch is minimal (only keeps stream alive)

## Benefits

1. ✅ **No more connection drops** when switching tabs
2. ✅ **Automatic reconnection** if network fails (5 second retry)
3. ✅ **Background updates** during live matches using modern BackgroundTasks framework
4. ✅ **Auto-restart stream** when matches go live (30 second checks)
5. ✅ **Pull to refresh** - Intuitive iOS gesture for manual refresh
6. ✅ **Countdown timer** - Visual feedback on next auto-update (15s)
7. ✅ **Better UX** - Always up to date, no manual intervention
8. ✅ **Resource efficient** - Only runs when actually needed
9. ✅ **Modern API** - Uses BGTaskScheduler instead of deprecated background fetch

## Update Frequency

- **Live matches**:
  - Real-time via gRPC stream (instant updates on goals, cards, etc.)
  - Fallback polling every 15 seconds (shown in countdown)
- **No live matches**:
  - Status check every 30 seconds (searches for new live matches)
  - Manual refresh via pull-to-refresh gesture
- **Background mode**:
  - Stream continues if already active
  - Background refresh tasks scheduled every 15 minutes using BGTaskScheduler
  - iOS determines optimal execution time based on usage patterns
