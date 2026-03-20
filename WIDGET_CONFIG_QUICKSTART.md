# Widget Configuration - Quick Start Guide

## 🚀 Quick Setup (2 minutes)

### Step 1: Add File to Xcode Project
The new `WidgetPreviewCard.swift` file needs to be added to your Xcode project:

1. Open **Sinced2.xcodeproj** in Xcode
2. In the Project Navigator (left sidebar), find the **Sinced2/Views** folder
3. Right-click on the **Views** folder → **Add Files to "Sinced2"...**
4. Navigate to `Sinced2/Views/WidgetPreviewCard.swift`
5. Make sure "Copy items if needed" is **unchecked** (file is already in place)
6. Make sure **"Sinced2" target** is checked
7. Click **Add**

### Step 2: Build and Run
1. Select a simulator (iPhone 16 or any iOS 18+ device)
2. Press **⌘ + B** to build
3. Press **⌘ + R** to run

### Step 3: Test the Feature
1. Create a new event (tap the + button)
2. Select an emoji
3. Enter an event name
4. **Important**: Select an image from your gallery
5. Save the event
6. Tap on the event to open details
7. Scroll down to see the **"Widget Configuration"** card

## ✨ What You'll See

The Widget Configuration card includes:

- **📱 Widget Preview**: Square preview showing exactly how your widget will look
- **🖼️ Your Image**: Fills the entire widget with a dark gradient at the bottom
- **⏱️ Time Display**: Large bold text (e.g., "12 days")
- **📝 Event Name**: Subtitle showing "since [event name]"
- **🎛️ Time Unit Buttons**: Four options - Hours, Days, Months, Years

## 🎯 Expected Behavior

1. **Tap "Days"** → Preview shows "X days"
2. **Tap "Hours"** → Preview shows "X hours" (updates instantly)
3. **Tap "Months"** → Preview shows "X months"
4. **Tap "Years"** → Preview shows "X years"

The selected unit is saved and will be used when you add the widget to your home screen.

## 📋 Files That Were Changed

✅ **New File**:
- `Sinced2/Views/WidgetPreviewCard.swift`

✅ **Modified Files**:
- `Sinced2/Models/SinceEvent.swift` - Added time unit enum and methods
- `Sinced2/Views/EventDetailView.swift` - Added widget preview card
- `WidgetSinced2/WidgetSinced2.swift` - Updated widget to use time unit

## 🐛 If You See Build Errors

### "Cannot find 'WidgetPreviewCard' in scope"
→ Make sure you added the file to the Xcode project (Step 1)

### "Type 'SinceEvent' has no member 'widgetTimeUnit'"
→ Clean build folder: **⌘ + Shift + K**, then rebuild

### Color extension duplicate
→ The Color extension in WidgetPreviewCard.swift might conflict with existing extensions
→ Safe to remove lines 172-198 from WidgetPreviewCard.swift if ColorExtensions.swift exists

## 🎨 Design Details

The widget preview matches the design specification:

- **Image**: 1:1 aspect ratio, fills completely
- **Gradient**: Black gradient covering bottom 40% (opacity 1% → 100%)
- **Main Text**: 56pt bold, white, with shadow
- **Subtitle**: 18pt medium, white 95%, with shadow
- **Buttons**: Green (#00621a) when selected, outlined when not

## 📱 Testing the Real Widget

After testing in the app:

1. Go to your iPhone home screen
2. Long press on empty space
3. Tap **"+"** in top left
4. Search for **"Sinced2"**
5. Add the small widget
6. Long press on widget → **Edit Widget**
7. Select your event
8. Widget should display time in the unit you selected!

## 💡 Tips

- **Image Quality**: Use high-quality square images for best results
- **Text Visibility**: The gradient ensures text is always readable
- **Real-time Preview**: The preview updates every second in the detail view
- **Widget Updates**: Home screen widgets update every 1-15 minutes depending on elapsed time

## ✅ Success Checklist

- [ ] WidgetPreviewCard.swift added to Xcode project
- [ ] App builds without errors
- [ ] Widget Configuration card appears on event detail page
- [ ] Preview shows uploaded image
- [ ] Time unit buttons work (preview updates instantly)
- [ ] Selection is saved (close and reopen to verify)
- [ ] Home screen widget shows selected time unit

---

**Need Help?** Check `WIDGET_CONFIGURATION_GUIDE.md` for detailed documentation.

