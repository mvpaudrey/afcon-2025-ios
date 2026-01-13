# Fix Widget White Screen on Device - Instructions

## Problem
The widget shows a white screen on real devices because it can't access the `AppGroup` enum which is needed to read shared data.

## Solution
Add the existing `AppGroup.swift` and `HomeWidgetSnapshotStore.swift` files to the **LiveScoreWidgetExtension** target in Xcode.

## Steps to Fix in Xcode

### 1. Add AppGroup.swift to Widget Target

1. In Xcode, navigate to: **AFCON2025/Services/AppGroup.swift**
2. Click on the file to select it
3. Open the **File Inspector** panel (right sidebar, or View → Inspectors → File)
4. Under **Target Membership**, check the box for **LiveScoreWidgetExtension**
5. The file should now have checkmarks for both:
   - ✅ AFCON2025
   - ✅ LiveScoreWidgetExtension

### 2. Add HomeWidgetSnapshotStore.swift to Widget Target

1. Navigate to: **AFCON2025/Common/HomeWidgetSnapshotStore.swift**
2. Click on the file to select it
3. Open the **File Inspector** panel
4. Under **Target Membership**, check the box for **LiveScoreWidgetExtension**
5. The file should now have checkmarks for both:
   - ✅ AFCON2025
   - ✅ LiveScoreWidgetExtension

### 3. Clean and Build

1. Clean the build folder: **Product → Clean Build Folder** (⇧⌘K)
2. Build the project: **Product → Build** (⌘B)
3. The app should now compile successfully

## What This Does

- **AppGroup.swift** provides the shared container identifier that both app and widget use
- **HomeWidgetSnapshotStore.swift** provides the data model (`LiveMatchWidgetSnapshot`) and storage
- By adding these to the widget target, both the main app and widget can access the same code without duplication
- The widget will now be able to read match data from the shared App Group container on real devices

## Verify It Works

1. Run the app on a real device
2. Wait for a live match or create some match data
3. Add the widget to your home screen
4. The widget should now display match data instead of a white screen

---

**Note:** Do NOT copy these files to the LiveScoreWidget folder. Instead, use Xcode's Target Membership feature to share them between targets.
