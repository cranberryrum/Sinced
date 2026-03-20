# Fix: Connection Invalidated Error

## Error
```
[S:6] Error received: Connection invalidated.
```

## Root Cause
This error occurs when the widget extension cannot properly access the App Group shared container. Common causes:
1. App Group container not initialized
2. Simulator state issues
3. App hasn't created the shared data yet
4. Build artifacts from previous builds

## Fix Applied

### Code Changes
Updated both `StorageManager.swift` files to ensure the App Group container directory exists:

**Files Modified:**
- `Sinced2/Services/StorageManager.swift`
- `WidgetSinced2/StorageManager.swift`

**Changes:**
```swift
// Added directory creation to ensure container exists
try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
```

## Step-by-Step Fix Instructions

### 1. Clean Build
```bash
# In Xcode:
Product → Clean Build Folder (Cmd+Shift+K)
```

Or via command line:
```bash
cd /Users/adityakolte/Desktop/Sinced2
rm -rf ~/Library/Developer/Xcode/DerivedData/Sinced2-*
```

### 2. Reset Simulator (Important!)
**In Simulator:**
- Device → Erase All Content and Settings
- This clears old app group data

**Or via command line:**
```bash
xcrun simctl shutdown all
xcrun simctl erase all
```

### 3. Fresh Build
```bash
cd /Users/adityakolte/Desktop/Sinced2
xcodebuild -scheme Sinced2 -sdk iphonesimulator -configuration Debug clean build
```

### 4. Run in Correct Order

#### Step A: Run the Main App FIRST
1. Open Xcode
2. Select **Sinced2** scheme (not WidgetSinced2Extension)
3. Select a simulator (iPhone 15 Pro recommended)
4. Run (Cmd+R)

#### Step B: Create Events
1. Wait for app to launch completely
2. Tap "+" to create an event
3. Add emoji: ☕️
4. Add title: "Coffee"
5. Optionally add a square image
6. Save the event
7. **Verify in Console:** Look for:
   ```
   StorageManager: Using AppGroup container: /path/to/group.com.kolte.sinced2
   StorageManager: File URL: /path/to/group.com.kolte.sinced2/events.json
   StorageManager: Successfully saved 1 events
   ```

#### Step C: Stop the App
- Press Stop button in Xcode (Cmd+.)
- This ensures clean state

#### Step D: Add Widget
1. Go to simulator home screen (Cmd+Shift+H)
2. Long press on empty space
3. Tap "+" (top left)
4. Search for "Since"
5. Add the widget
6. Place it on home screen

#### Step E: Verify Widget
The widget should display:
- ✅ Event time (e.g., "0 days")
- ✅ Event title (e.g., "since Coffee")
- ✅ Background image (if added)

### 5. Check Console Logs

In Xcode Console, you should see:
```
// From Main App:
StorageManager: Using AppGroup container: [path]
StorageManager: Successfully saved 1 events
StorageManager: Reloading all widget timelines

// From Widget:
Widget: Loading events for configuration
Widget: Found 1 active events
Widget: Using first event: Coffee
Widget: Timeline created
```

If you see:
```
StorageManager: WARNING - AppGroup not available
```
Then the App Group is not configured properly.

## Troubleshooting

### Issue: Still seeing "Connection invalidated"

**Solution 1: Verify Capabilities**
1. In Xcode, select project
2. Select "Sinced2" target
3. Go to "Signing & Capabilities"
4. Verify "App Groups" capability exists
5. Check `group.com.kolte.sinced2` is enabled
6. Repeat for "WidgetSinced2Extension" target

**Solution 2: Reset Provisioning**
```bash
# Delete provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Clean build
cd /Users/adityakolte/Desktop/Sinced2
xcodebuild clean
```

**Solution 3: Check Entitlements**
```bash
# Verify entitlements
cd /Users/adityakolte/Desktop/Sinced2

# Main app
cat Sinced2/Sinced2.entitlements | grep -A2 "application-groups"

# Widget
cat WidgetSinced2/WidgetSinced2.entitlements | grep -A2 "application-groups"

# Both should show: group.com.kolte.sinced2
```

### Issue: Widget shows "No events"

**Cause:** App data not created yet

**Solution:**
1. Run the main app first
2. Create at least one event
3. Stop the app
4. Then add widget

### Issue: Widget shows placeholder/skeleton

**Cause:** Widget can't read the data file

**Solution:**
1. Check console for "AppGroup not available" warning
2. Verify both targets have App Groups capability
3. Reset simulator and try again

### Issue: Image not showing in widget

**Possible causes:**
1. Image wasn't saved (check in app by editing event)
2. Image is too large (compress it)
3. Image format not supported (use JPG/PNG)

**Solution:**
1. Edit the event in the app
2. Remove and re-add the image
3. Save
4. Remove and re-add widget

## Verification Script

Run this to check setup:
```bash
cd /Users/adityakolte/Desktop/Sinced2
./diagnose_widget.sh
```

## Expected Flow

### First Time Setup:
```
1. Main App Starts
   ↓
2. StorageManager initializes
   ↓
3. App Group container created
   ↓
4. User creates event
   ↓
5. Data saved to shared container
   ↓
6. WidgetCenter.reloadAllTimelines() called
   ↓
7. Widget can now read data
```

### Widget Refresh:
```
1. Widget timeline provider called
   ↓
2. StorageManager.shared.loadEvents()
   ↓
3. Read from App Group container
   ↓
4. Parse JSON data
   ↓
5. Display in widget UI
```

## Testing Checklist

- [ ] Clean build folder
- [ ] Reset simulator
- [ ] Build app successfully
- [ ] Run MAIN APP first
- [ ] Create at least one event
- [ ] See success message in console
- [ ] Stop the app
- [ ] Add widget to home screen
- [ ] Widget displays event data
- [ ] Console shows no errors

## Quick Fix Command

Run this complete fix sequence:
```bash
#!/bin/bash
cd /Users/adityakolte/Desktop/Sinced2

echo "🧹 Cleaning..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Sinced2-*

echo "🔄 Resetting simulator..."
xcrun simctl shutdown all
xcrun simctl erase all

echo "🔨 Building..."
xcodebuild -scheme Sinced2 -sdk iphonesimulator -configuration Debug clean build

echo "✅ Done! Now:"
echo "1. Run app in Xcode (Cmd+R)"
echo "2. Create an event"
echo "3. Stop app"
echo "4. Add widget"
```

## Additional Debug Logs

If still having issues, add this to `WidgetSinced2.swift` in the `timeline` function:

```swift
func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<SinceWidgetEntry> {
    print("Widget: Timeline function called")
    print("Widget: Context family: \(context.family)")
    
    let events = StorageManager.shared.loadEvents()
    print("Widget: Loaded \(events.count) events")
    
    for event in events {
        print("Widget: Event - \(event.emoji) \(event.title), archived: \(event.isArchived)")
    }
    
    // ... rest of function
}
```

## Success Indicators

✅ **Console shows:**
```
StorageManager: Using AppGroup container: /Users/.../group.com.kolte.sinced2
Widget: Found 1 active events
Widget: Using first event: Coffee
```

✅ **Widget displays:**
- Event time value
- Event title with "since" prefix
- Background image (if added)
- Gradient overlay

✅ **No errors:**
- No "Connection invalidated"
- No "AppGroup not available"
- No "No events found"

## Still Not Working?

If you've followed all steps and it still doesn't work:

1. **Check bundle identifier:**
   - Main app: `Kolte.Sinced2`
   - Widget: `Kolte.Sinced2.WidgetSinced2Extension`
   - App Group: `group.com.kolte.sinced2`

2. **Verify signing:**
   - Both targets use the same team
   - Both have App Groups capability
   - Provisioning profiles are valid

3. **Try on physical device:**
   - Sometimes simulators have App Group issues
   - Physical device test can isolate the problem

4. **Check Xcode version:**
   - Ensure you're using Xcode 15 or later
   - Some older versions have App Group bugs

## Files Modified
- ✅ `Sinced2/Services/StorageManager.swift`
- ✅ `WidgetSinced2/StorageManager.swift`
- ✅ Both now ensure directory exists

## Next Steps
1. Follow the step-by-step instructions above
2. Clean, reset, and rebuild
3. Run main app FIRST
4. Create events
5. Add widget

The "Connection invalidated" error should be resolved! 🎉



