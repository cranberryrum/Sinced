# Quick Start Guide - Since App

Get the Since app running in under 5 minutes.

## 🚀 Fastest Path to Running App

### Step 1: Open Xcode (30 seconds)

```bash
cd /Users/adityakolte/Desktop/Sinced2
open Sinced2.xcodeproj
```

### Step 2: Create Widget Extension (2 minutes)

1. In Xcode, click **File** → **New** → **Target**
2. Search for "Widget Extension"
3. Click **Next**
4. Set Name: **SinceWidget**
5. Uncheck "Include Configuration Intent"
6. Click **Finish**, then **Activate**

### Step 3: Add Files to Widget Target (1 minute)

Select these files in the navigator, then in File Inspector (right panel), check **SinceWidget** target:

**Required for Widget:**
- `SinceWidget/SinceWidget.swift`
- `SinceWidget/SinceWidgetBundle.swift`
- `SinceWidget/SelectEventIntent.swift`
- `SinceWidget/Info.plist`
- `SinceWidget/SinceWidget.entitlements`
- `Models/SinceEvent.swift` ⚠️ (must be in both targets)
- `Services/StorageManager.swift` ⚠️ (must be in both targets)

### Step 4: Configure App Groups (1 minute)

**For Sinced2 Target:**
1. Select **Sinced2** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** → Add **App Groups**
4. Click **+** → Enter: `group.com.sinced.app`
5. Check the box

**For SinceWidget Target:**
1. Select **SinceWidget** target
2. Repeat steps 2-5 above

### Step 5: Run! (30 seconds)

1. Select **Sinced2** scheme (top-left dropdown)
2. Select **iPhone 15 Pro** simulator
3. Press **⌘R** or click Play button

## ✅ Expected Result

You should see:
1. Onboarding screen with "Track time since something that matters"
2. Tap "Create Event" → Event creation screen appears
3. Select an emoji (e.g., ☕️)
4. Enter title (e.g., "Coffee")
5. Tap "Save"
6. You're now on the home screen showing your event!

## 🧪 Test the Widget

1. **Add event in app** (if not already)
2. **Go to Home Screen** (⌘H in simulator)
3. **Long press on background**
4. **Tap + button** (top-left)
5. **Search "Since"**
6. **Drag small widget** to Home Screen
7. **Widget shows your event!** 🎉

## 🐛 Common Issues & Fixes

### Issue: "No such module 'WidgetKit'"

**Fix**: Make sure WidgetKit is linked
1. Select SinceWidget target
2. Go to Build Phases
3. Link Binary With Libraries
4. Add WidgetKit.framework

### Issue: Widget shows "No events"

**Fix**: App Group not configured
1. Check both targets have App Group capability
2. Verify identifier: `group.com.sinced.app`
3. Make sure it matches in StorageManager.swift (line 13)
4. Rebuild both targets

### Issue: Build errors in widget files

**Fix**: Files not added to target
1. Select the erroring file
2. File Inspector (⌥⌘1)
3. Check "SinceWidget" under Target Membership
4. For SinceEvent.swift and StorageManager.swift, check BOTH targets

### Issue: "Command CodeSign failed"

**Fix**: Configure signing
1. Select target
2. Signing & Capabilities
3. Select your Team
4. Check "Automatically manage signing"

## 📱 Testing Checklist

Quick things to try:

- [ ] Create event with emoji
- [ ] See timer updating
- [ ] Tap event to see details
- [ ] Reset event
- [ ] Add note to reset
- [ ] Delete event (swipe left)
- [ ] Create multiple events
- [ ] Add widget to Home Screen
- [ ] Toggle dark mode (⌘⇧A in simulator)

## 🎯 Key Files to Know

| File | Purpose |
|------|---------|
| `Sinced2App.swift` | App entry point, routing |
| `EventViewModel.swift` | All app state and logic |
| `StorageManager.swift` | Save/load events |
| `EventListView.swift` | Main home screen |
| `SinceWidget.swift` | Widget implementation |

## 💡 Development Tips

### SwiftUI Previews
- Press **⌥⌘↩** to open Canvas
- Click "Resume" to see live preview
- Edit code, see instant changes

### Simulator Shortcuts
- **⌘H** - Home
- **⌘⇧H** - App Switcher
- **⌘K** - Toggle keyboard
- **⌘⇧A** - Toggle dark mode

### Debugging Widget
1. Run main app first
2. Stop it
3. Select SinceWidget scheme
4. Run (⌘R)
5. Choose app when prompted
6. Debugger attaches to widget

### Hot Reload
- Keep simulator running
- Make SwiftUI changes
- Press **⌘B** (just build)
- Some views hot-reload automatically

## 🔄 Reset Everything

If things get messy, start fresh:

```bash
# Clean build
⌘⇧K in Xcode

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Sinced2-*

# Delete app from simulator
# Long press app icon → Remove App

# Rebuild
⌘B then ⌘R
```

## 📚 Next Steps

Once running:

1. **Read [README.md](README.md)** - Full project overview
2. **Read [SETUP_GUIDE.md](SETUP_GUIDE.md)** - Detailed setup
3. **Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Technical details
4. **Explore the code** - All files are commented
5. **Customize** - Change emojis, colors, copy

## 🎨 Quick Customizations

### Add More Emojis
Edit `CreateEventView.swift` line 21-25:
```swift
private let commonEmojis = [
    "☕️", "🚬", "🍷", // ... add your emojis here
]
```

### Change Accent Color
Edit `ColorExtensions.swift` to map emojis to colors

### Change App Group
1. Update `StorageManager.swift` line 13
2. Update entitlements files
3. Reconfigure in Signing & Capabilities

## ⚡️ Pro Tips

- **Fast iteration**: Keep simulator running, edit views, build only (⌘B)
- **Widget testing**: Use widget timeline simulator in Xcode
- **Data reset**: Delete app from simulator to clear all data
- **Dark mode**: Test both modes (⌘⇧A toggles in simulator)
- **Accessibility**: Enable VoiceOver to test accessibility

## 📞 Getting Stuck?

1. Check build log (⌘9 → Reports)
2. Check console output (⌘⇧C)
3. Clean build folder (⌘⇧K)
4. Restart Xcode
5. Reread [SETUP_GUIDE.md](SETUP_GUIDE.md)

---

**Expected Time**: 5 minutes  
**Difficulty**: Easy  
**Prerequisites**: Xcode 15.0+, macOS 13.0+  

**You're ready to go! 🚀**


