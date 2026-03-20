# Fix Build Errors - StorageManager Not Found

## The Problem
The widget extension can't find `StorageManager` because Xcode hasn't refreshed its build system after the project file changes.

## Quick Fix Steps

### 1. Close Xcode (if open)
Close Xcode completely.

### 2. Clean Derived Data (Already Done)
I've already cleaned the derived data folder for you.

### 3. Verify Project File
The project file has been correctly updated. Only `Assets.xcassets` is now excluded from the widget target, which means `StorageManager.swift` and `SinceEvent.swift` ARE included.

### 4. Open and Rebuild

```bash
# Open the project
open /Users/adityakolte/Desktop/Sinced2/Sinced2.xcodeproj

# In Xcode:
# 1. Product → Clean Build Folder (⇧⌘K)
# 2. Product → Build (⌘B)
```

## If Still Failing

If the build still fails, try this:

### Option A: Manual Target Membership Check
1. In Xcode, select `StorageManager.swift` in the Project Navigator
2. Open the File Inspector (right panel, first tab)
3. Under "Target Membership", ensure **both** are checked:
   - ✅ Sinced2
   - ✅ WidgetSinced2Extension

4. Do the same for `SinceEvent.swift`

### Option B: Explicit File Addition

If Option A doesn't show the checkboxes, the files need to be explicitly added:

1. Select the `WidgetSinced2Extension` target in Project Navigator
2. Go to "Build Phases" tab
3. Expand "Compile Sources"
4. Click "+" button
5. Add:
   - `Sinced2/Services/StorageManager.swift`
   - `Sinced2/Models/SinceEvent.swift`

## Expected Result

After these steps, you should see:
- ✅ Build Succeeded
- ✅ No "Cannot find 'StorageManager' in scope" errors
- ✅ Widget configuration shows events properly

## Technical Details

### What Changed
The `project.pbxproj` file was updated to remove these files from the widget target's exclusion list:
- ❌ `Models/SinceEvent.swift` (was excluded, now included)
- ❌ `Services/StorageManager.swift` (was excluded, now included)

### Current Exception List
```
membershipExceptions = (
    Assets.xcassets,  // Only this is excluded
);
```

### Why This Fixes Widget Configuration
The widget needs access to:
1. `StorageManager` - to load events from shared storage
2. `SinceEvent` - to know the data structure

Without these, the widget's `AppIntent.swift` can't:
- Query available events
- Show events in configuration UI
- Display selected event

## Still Having Issues?

If you still see errors after all these steps:

### Check Console Output
Look for specific error messages that might indicate a different issue.

### Verify App Group
Make sure the App Group is configured:
1. Select main target "Sinced2"
2. Go to "Signing & Capabilities"
3. Verify "App Groups" capability exists
4. Verify `group.Kolte.Sinced2` is listed

5. Do the same for "WidgetSinced2Extension" target

### Last Resort: Manual Compile
Try compiling the files manually to check syntax:

```bash
cd /Users/adityakolte/Desktop/Sinced2
xcrun swiftc -parse Sinced2/Services/StorageManager.swift
xcrun swiftc -parse Sinced2/Models/SinceEvent.swift
```

If these show errors, the issue is with the files themselves, not the project configuration.

---

**Most likely solution**: Just close Xcode, reopen, clean build folder, and rebuild. The project file is correctly configured now!



