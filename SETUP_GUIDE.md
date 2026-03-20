# Since App - Setup Guide

Complete step-by-step guide to configure and run the Since app in Xcode.

## Prerequisites

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0 or later
- **Apple Developer Account**: Free or paid (for device testing)

## Project Configuration

### 1. Open the Project

```bash
cd /Users/adityakolte/Desktop/Sinced2
open Sinced2.xcodeproj
```

### 2. Configure Targets

The project has two targets:
1. **Sinced2** - Main app
2. **SinceWidget** - Widget extension (to be created)

### 3. Add Widget Extension Target

Since the widget files are created, you'll need to add the Widget Extension target in Xcode:

1. In Xcode, select the project in the navigator
2. Click the "+" button at the bottom of the targets list
3. Select "Widget Extension" template
4. Name it **SinceWidget**
5. Language: **Swift**
6. Uncheck "Include Configuration Intent"
7. Click "Finish"
8. When prompted, click "Activate" to create the scheme

### 4. Add Files to Targets

#### Main App Target (Sinced2)

Add these files to the Sinced2 target:
- `Models/SinceEvent.swift`
- `Services/StorageManager.swift`
- `ViewModels/EventViewModel.swift`
- `Views/OnboardingView.swift`
- `Views/CreateEventView.swift`
- `Views/EventListView.swift`
- `Views/EventDetailView.swift`
- `Views/ResetSheetView.swift`
- `Utilities/ColorExtensions.swift`
- `Utilities/HapticManager.swift`
- `Utilities/ViewModifiers.swift`
- `Sinced2App.swift`
- `ContentView.swift`

#### Widget Extension Target (SinceWidget)

Add these files to the SinceWidget target:
- `Models/SinceEvent.swift` (⚠️ also include in widget)
- `Services/StorageManager.swift` (⚠️ also include in widget)
- `SinceWidget/SinceWidget.swift`
- `SinceWidget/SinceWidgetBundle.swift`
- `SinceWidget/SelectEventIntent.swift`
- `SinceWidget/Info.plist`
- `SinceWidget/SinceWidget.entitlements`

To add files to a target:
1. Select the file in Xcode navigator
2. Open File Inspector (⌥⌘1)
3. Check the appropriate target membership boxes

### 5. Configure App Groups

Both the main app and widget need to share data via App Groups.

#### For Main App (Sinced2):

1. Select **Sinced2** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** to add a new group
6. Enter: `group.com.sinced.app`
7. Make sure it's checked

#### For Widget Extension (SinceWidget):

1. Select **SinceWidget** target
2. Repeat the same steps above
3. Use the same App Group: `group.com.sinced.app`

### 6. Update Bundle Identifiers

#### Main App:
- Target: **Sinced2**
- Bundle Identifier: `com.sinced.app` (or your preferred identifier)

#### Widget:
- Target: **SinceWidget**
- Bundle Identifier: `com.sinced.app.SinceWidget`
  - ⚠️ Must be a child of the main app identifier

### 7. Configure Signing

For both targets:

1. Select target
2. Go to **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select your **Team** from dropdown
5. Xcode will generate provisioning profiles

### 8. Set Deployment Target

Ensure both targets have iOS 17.0+ as deployment target:

1. Select target
2. Go to **General** tab
3. Set **Minimum Deployments** to **iOS 17.0**

### 9. Link Frameworks

The following frameworks should be automatically linked:

#### Main App:
- SwiftUI
- Foundation
- UIKit
- WidgetKit

#### Widget:
- WidgetKit
- SwiftUI
- AppIntents
- Foundation

### 10. Add Entitlements

Entitlements files are already created. Ensure they're linked:

#### Main App:
- File: `Sinced2/Sinced2.entitlements`
- Target: **Sinced2**
- Location: In Signing & Capabilities, verify App Groups is configured

#### Widget:
- File: `SinceWidget/SinceWidget.entitlements`
- Target: **SinceWidget**
- Location: In Signing & Capabilities, verify App Groups is configured

## Building the Project

### 1. Select Scheme

In the scheme selector (top-left), choose:
- **Sinced2** for running the main app

### 2. Select Destination

Choose either:
- **iPhone 15 Pro** (or any simulator)
- Your physical device (if connected)

### 3. Build & Run

Press **⌘R** or click the Play button

## Testing the Widget

### In Simulator:

1. Run the main app first
2. Create at least one event
3. Stop the app
4. Long-press on Home Screen
5. Tap **+** in top-left
6. Search for "Since"
7. Drag the small widget to Home Screen
8. The widget should display your first event

### On Device:

Same steps as simulator. Make sure your device is running iOS 17.0+.

## Troubleshooting

### Widget Not Appearing

**Problem**: Widget doesn't show in widget gallery

**Solutions**:
1. Ensure SinceWidget target is built successfully
2. Verify App Group is configured for both targets
3. Check Bundle Identifier is correct (widget must be child of app)
4. Clean build folder (⇧⌘K) and rebuild
5. Restart Xcode

### App Group Not Working

**Problem**: Widget shows "No events" even though events exist

**Solutions**:
1. Verify App Group identifier matches in both targets: `group.com.sinced.app`
2. Check entitlements files are properly linked
3. Ensure App Group capability is added in Signing & Capabilities
4. Re-sign both targets
5. Delete app from simulator/device and reinstall

### Build Errors

**Problem**: Compilation errors or missing files

**Solutions**:
1. Verify all files are added to correct targets
2. Check that `SinceEvent.swift` and `StorageManager.swift` are in **both** targets
3. Clean build folder (⇧⌘K)
4. Restart Xcode
5. Delete DerivedData folder:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### Signing Issues

**Problem**: Code signing errors

**Solutions**:
1. Ensure you're logged into Xcode with Apple ID (Preferences → Accounts)
2. Check Bundle Identifiers are unique
3. Try manual signing instead of automatic
4. Create explicit App IDs in Apple Developer Portal
5. Download provisioning profiles manually

## Development Tips

### Live Preview

Use SwiftUI previews for rapid development:
- Press **⌥⌘↩** to show canvas
- Click "Resume" to see live preview
- Edit code and see changes in real-time

### Debugging Widget

To debug the widget:
1. Run the main app first
2. Stop it
3. Select **SinceWidget** scheme
4. Run widget extension
5. Choose "Since" when prompted
6. Xcode will attach debugger to widget

### Testing Timeline Updates

Widget timeline updates can be tested:
1. Create an event in the app
2. Add widget to Home Screen
3. Wait for timeline refresh (check console logs)
4. Or force refresh: Remove and re-add widget

### Hot Reload

For faster iteration:
1. Keep simulator running
2. Make changes to SwiftUI views
3. Build (⌘B) without running
4. Some changes will hot-reload automatically

## Project File Structure

```
Sinced2/
├── Sinced2/                       # Main app
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   ├── Utilities/
│   ├── Assets.xcassets/
│   ├── Sinced2.entitlements
│   └── Sinced2App.swift
├── SinceWidget/                   # Widget extension
│   ├── SinceWidget.swift
│   ├── SinceWidgetBundle.swift
│   ├── SelectEventIntent.swift
│   ├── SinceWidget.entitlements
│   └── Info.plist
├── Sinced2.xcodeproj/
├── README.md
├── CHANGELOG.md
├── SETUP_GUIDE.md
└── .gitignore
```

## Next Steps

After successful setup:

1. ✅ Run the app and create your first event
2. ✅ Test the onboarding flow
3. ✅ Create multiple events
4. ✅ Test reset functionality
5. ✅ Add widget to Home Screen
6. ✅ Verify widget updates
7. ✅ Test in dark mode
8. ✅ Test with different text sizes (Settings → Display & Brightness → Text Size)
9. ✅ Test VoiceOver (Settings → Accessibility → VoiceOver)

## Getting Help

If you encounter issues not covered in this guide:

1. Check build logs in Xcode's Report Navigator (⌘9)
2. Review console output for runtime errors
3. Verify all settings against this guide
4. Clean build folder and rebuild
5. Create a new scheme if widget scheme is missing

## Additional Resources

- [Apple's WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [App Groups Documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

**Last Updated**: October 31, 2025  
**Xcode Version**: 15.0+  
**iOS Version**: 17.0+


