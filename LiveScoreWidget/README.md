# Widget Extension Files

⚠️ **IMPORTANT**: These files belong in a Widget Extension target, not in the main app!

## Files in this folder:

1. **LiveScoreActivityWidget.swift** - The Live Activity widget views
2. **LiveScoreWidgetBundle.swift** - The widget bundle entry point

## Setup Instructions:

### Quick Start:
1. Open the main project: `DesignPlayground.xcodeproj`
2. Follow the guide: `../LIVE_ACTIVITY_SETUP_GUIDE.md`

### Summary:
1. Create a new **Widget Extension** target in Xcode
2. Name it: `LiveScoreWidget`
3. Add these two files to that target
4. Make sure `LiveScoreActivityAttributes.swift` is in **BOTH** targets

## Why These Files Are Separate:

Live Activities require a Widget Extension to display on:
- Lock Screen
- Dynamic Island
- Notification banners

The widget code **must** be in a separate target/extension, not in the main app.

## What Files Go Where:

### Widget Extension (LiveScoreWidget target):
- ✅ `LiveScoreActivityWidget.swift` (this folder)
- ✅ `LiveScoreWidgetBundle.swift` (this folder)
- ✅ `LiveScoreActivityAttributes.swift` (shared - in both targets)

### Main App (AFCON2025 target):
- ✅ `LiveActivityManager.swift` (already correct)
- ✅ `PremierLeagueService.swift` (already correct)
- ✅ `PremierLeagueLiveView.swift` (already correct)
- ✅ `LiveScoreActivityAttributes.swift` (shared - in both targets)

## Current Status:

🔴 Widget Extension NOT YET CREATED - Follow setup guide!

Once you create the Widget Extension in Xcode, drag these files into it!
