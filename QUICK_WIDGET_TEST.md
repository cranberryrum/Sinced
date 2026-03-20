# Quick Widget Test Guide

## ✅ What Was Fixed
Your widget wasn't displaying data because it didn't have access to the `SinceEvent` model and `StorageManager` files. I've copied these essential files into the widget target, and the project now builds successfully.

## 🚀 How to Test

### Step 1: Run the App
```bash
# Open Xcode and run the app
open Sinced2.xcodeproj
# Then press Cmd+R to run
```

### Step 2: Create an Event
1. Open the app in the simulator
2. Tap the "+" button to create a new event
3. Choose an emoji (e.g., ☕️)
4. Enter a title (e.g., "Coffee")
5. Optionally add a 1:1 square image
6. Set a start date (or use default)
7. Save the event

### Step 3: Add the Widget
1. **Go to home screen**: Swipe up or press Cmd+Shift+H
2. **Long press** on empty space on home screen
3. **Tap "+"** button (top left corner)
4. **Search for "Since"** or scroll to find your app
5. **Select the widget** and tap "Add Widget"
6. **Place it** on your home screen

### Step 4: Verify Data Display
The widget should now show:
- ✅ Time elapsed (e.g., "0 days" for new events)
- ✅ Event title (e.g., "since Coffee")
- ✅ Background image (if you added one)
- ✅ Gradient overlay for text readability

## 🔄 Widget Updates
The widget automatically refreshes:
- Every **1 minute** for the first hour
- Every **5 minutes** for the first day
- Every **15 minutes** after that

## 🎯 Expected Behavior

### If You Have Events:
```
┌─────────────────┐
│   [IMAGE BG]    │  ← Your photo (if added)
│                 │
│   0 days        │  ← Time counter
│   since Coffee  │  ← Your event title
└─────────────────┘
```

### If No Events Exist:
```
┌─────────────────┐
│                 │
│       ⏱️        │
│   No events     │
│                 │
└─────────────────┘
```

## 🐛 Troubleshooting

### Widget shows skeleton/placeholder
- **Solution**: Make sure you created at least one event in the app
- **Force refresh**: Remove widget and add it again

### Widget shows "No events"
- **Solution**: Open the app and verify you have active (non-archived) events
- **Wait**: Widget may take up to 15 minutes to auto-refresh
- **Force refresh**: Remove and re-add widget for immediate update

### Image not displaying
- **Check**: Make sure image is square (1:1 ratio)
- **Verify**: Edit the event to confirm image was saved
- **Tip**: Use images with clear subjects for best results

## 📊 Console Logs
When running in Xcode, you'll see helpful logs:
```
Widget: Loading events for configuration
Widget: Found 1 active events
Widget: Using first event: Coffee
Widget: Timeline created, next update: [date]
```

## 🔍 Verify Setup
Run this command to check everything is configured:
```bash
cd /Users/adityakolte/Desktop/Sinced2
./verify_widget_setup.sh
```

## 📝 Key Files Fixed
- ✅ `WidgetSinced2/SinceEvent.swift` - Event data model
- ✅ `WidgetSinced2/StorageManager.swift` - Data persistence
- ✅ Both files use App Group `group.com.kolte.sinced2`
- ✅ Widget has proper entitlements configured

## 🎉 Success Criteria
Your widget is working correctly if you see:
1. ✅ Real event data (not placeholder)
2. ✅ Correct time calculation
3. ✅ Your event title
4. ✅ Background image (if added)
5. ✅ Updates over time

## 💡 Tips
- **Multiple events**: Long press widget → Edit Widget → Select event
- **Widget sizes**: Currently supports systemSmall only
- **Updates**: Automatic, but can force by removing/re-adding
- **Testing**: Create events with different times to see various displays

---

**Everything is now set up correctly!** Just build, run, create an event, and add the widget. It should display your data immediately. 🚀



