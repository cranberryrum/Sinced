# Widget Event Fetch Fix

## Problem
When editing/configuring the widget, events were not being fetched. The widget configuration screen showed no events to select from.

## Root Cause
The entitlements files existed in the project (`Sinced2/Sinced2.entitlements` and `WidgetSinced2/WidgetSinced2.entitlements`) with the correct App Group configuration (`group.Kolte.Sinced2`), but they were **not linked** in the Xcode project build settings.

Without the `CODE_SIGN_ENTITLEMENTS` build setting pointing to these files, both the main app and widget extension were being built without the App Group capability, preventing them from accessing the shared container where events are stored.

## What Was Fixed

### 1. Added Entitlements Configuration to Project
Added `CODE_SIGN_ENTITLEMENTS` build setting to all targets:

- **Main App (Debug & Release)**:
  ```
  CODE_SIGN_ENTITLEMENTS = Sinced2/Sinced2.entitlements;
  ```

- **Widget Extension (Debug & Release)**:
  ```
  CODE_SIGN_ENTITLEMENTS = WidgetSinced2/WidgetSinced2.entitlements;
  ```

### 2. Enhanced Debug Logging
Added comprehensive logging to help diagnose issues:

**StorageManager.swift**:
- Logs when accessing the App Group container
- Shows the file path being used
- Logs file existence and data loading
- Warns if falling back to documents directory (indicates entitlements issue)

**AppIntent.swift**:
- Logs event loading in all query methods
- Shows total events loaded and filtered counts
- Displays event details (emoji + title)

## How to Test

### Step 1: Clean Build
The project has already been cleaned and rebuilt with the new settings.

### Step 2: Install and Run the App
```bash
# Open Xcode
open Sinced2.xcodeproj

# Or build from command line
xcodebuild -project Sinced2.xcodeproj -scheme Sinced2 -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Step 3: Add Some Events
1. Launch the app
2. Create 2-3 test events (e.g., "Coffee Break ☕", "Gym 🏋️", "Study 📚")
3. Make sure they're active (not archived)

### Step 4: Test Widget Configuration
1. Long press on home screen → Add Widget
2. Search for "Sinced2" or "Since"
3. Add the small widget
4. **Edit the widget** (long press → Edit Widget)
5. Tap on "Event" parameter
6. **You should now see your events listed!**

### Step 5: Verify Using Console Logs
Open Console.app and filter for "StorageManager" or "Widget" to see the debug logs:

**Expected logs when everything works:**
```
StorageManager: Using AppGroup container: /path/to/container
StorageManager: Loading events from: /path/to/container/events.json
StorageManager: File exists: true
StorageManager: Loaded X bytes of data
StorageManager: Successfully decoded 3 events
Widget: Loading suggested events
Widget: Total events loaded: 3
Widget: Found 3 active events
Widget: Returning entities: ☕ Coffee Break, 🏋️ Gym, 📚 Study
```

**If entitlements still not working (shouldn't happen):**
```
StorageManager: WARNING - AppGroup not available, falling back to documents directory
```

## Verification Checklist

- ✅ App Group entitlements files exist
- ✅ Entitlements linked in project build settings
- ✅ Project cleaned and rebuilt
- ✅ Debug logging added
- ✅ Build succeeds without errors

## If Events Still Don't Show

If you still can't see events in the widget configuration:

1. **Check Console Logs**: Look for the "WARNING - AppGroup not available" message
2. **Verify Team Settings**: Make sure your development team is set in Xcode project settings
3. **Delete Existing Data**: The app might have old data in the wrong location
   - Delete the app from simulator/device
   - Reinstall and create fresh events
4. **Check Provisioning**: If testing on a physical device, ensure provisioning profiles have App Group capability

## Technical Details

### App Group Identifier
- **Group ID**: `group.Kolte.Sinced2`
- **Purpose**: Allows main app and widget to share data
- **Storage Location**: `/path/to/container/events.json`

### Files Modified
1. `Sinced2.xcodeproj/project.pbxproj` - Added entitlements configuration
2. `Sinced2/Services/StorageManager.swift` - Enhanced logging
3. `WidgetSinced2/AppIntent.swift` - Enhanced logging

### Why This Fixes the Issue
The widget uses `StorageManager.shared.loadEvents()` to fetch events. This requires access to the shared App Group container. Without proper entitlements:
- Widget can't access the container
- `loadEvents()` returns empty array
- No events show in configuration UI

With entitlements properly configured:
- Widget has access to App Group container
- Can read `events.json`
- Events appear in configuration screen ✅



