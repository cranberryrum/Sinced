# Widget Configuration Guide

## 🎯 Overview

The **Since** widget is now fully configurable! Users can choose which specific event to display on each widget instance.

## ✨ Features

- **1×1 Small Widget** - Perfect size for Home Screen
- **Configurable** - Choose which event to display
- **Multiple Widgets** - Add multiple widgets, each showing a different event
- **Smart Refresh** - Updates based on elapsed time (1min/5min/15min)
- **Live Updates** - Real-time elapsed time display
- **Beautiful Design** - Matches the app's minimal aesthetic

## 📱 How to Add & Configure Widget

### Step 1: Add Widget to Home Screen

1. **Long press** on your Home Screen
2. Tap the **+** button in the top-left corner
3. Search for **"Since"**
4. Select the **small (1×1) widget**
5. Tap **"Add Widget"**

### Step 2: Configure Event Selection

#### On iOS 17+:

**Option A: During Widget Addition**
- After tapping "Add Widget", you'll see event options
- Tap on the widget preview
- Select "Event" → Choose your desired event
- Tap outside to confirm

**Option B: After Widget is Added**
1. **Long press** on the widget
2. Tap **"Edit Widget"**
3. Tap **"Event"** field
4. Select your desired event from the list
5. Tap outside to save

### Step 3: Add Multiple Widgets (Optional)

Want to track multiple events on your Home Screen?

1. Add another widget (repeat Step 1)
2. Configure it with a different event
3. Each widget can display a different event!

## 🎨 Widget Display

The widget shows:

```
☕️              ← Event emoji (large)

3h 22m          ← Elapsed time (bold)
since 9:24 AM   ← Start time (small caption)
```

### Layout Details:
- **Emoji**: Top-left, 32pt size
- **Time**: Bottom, 18pt semibold
- **Caption**: Below time, 10pt
- **Background**: Adapts to light/dark mode

## 🔄 Refresh Behavior

The widget automatically refreshes based on elapsed time:

| Time Elapsed | Refresh Interval | Reason |
|--------------|------------------|--------|
| 0–60 min | Every 1 minute | High precision needed |
| 1–24 hours | Every 5 minutes | Balance of accuracy & battery |
| > 24 hours | Every 15 minutes | Less frequent updates needed |

### Additional Refresh Triggers:
- ✅ Manual event reset in app
- ✅ Significant time change
- ✅ Time zone change
- ✅ App data update

## 🎯 Usage Examples

### Example 1: Single Event Tracking
**Scenario**: You only track coffee consumption

1. Create "Coffee" event in app with ☕️ emoji
2. Add widget to Home Screen
3. Widget automatically displays "Coffee" (first event)
4. Done! Widget updates automatically

### Example 2: Multiple Event Tracking
**Scenario**: You track coffee, smoking, and sugar

1. Create three events in app:
   - ☕️ Coffee
   - 🚬 Smoking
   - 🍰 Sugar

2. Add first widget:
   - Long press Home Screen → Add Widget
   - Configure to show "☕️ Coffee"
   
3. Add second widget:
   - Long press Home Screen → Add Widget
   - Configure to show "🚬 Smoking"
   
4. Add third widget:
   - Long press Home Screen → Add Widget
   - Configure to show "🍰 Sugar"

Now you have three widgets, each tracking a different event!

### Example 3: Changing Widget Event
**Scenario**: You want to change which event a widget displays

1. Long press the widget
2. Tap "Edit Widget"
3. Tap "Event"
4. Select a different event
5. Tap outside to save
6. Widget now shows the new event!

## 🔧 Widget Configuration Options

### Available Settings:

**Event Selection**
- Shows all non-archived events
- Displays emoji + title for easy identification
- Defaults to first event if not configured

### Widget Picker Display:

When selecting an event, you'll see:
```
☕️ Coffee
🚬 Smoking
🍰 Sugar
💊 Medication
🏃 Running
... (all your events)
```

## 🐛 Troubleshooting

### Widget Shows "No events"

**Cause**: No events created in app
**Fix**: Open the app and create at least one event

### Widget Shows Wrong Event

**Cause**: Widget configuration needs update
**Fix**: 
1. Long press widget
2. Edit Widget
3. Select correct event

### Widget Not Updating

**Cause**: Multiple possible reasons
**Fix**:
1. Check if app has events
2. Try removing and re-adding widget
3. Force refresh: Edit widget → Select same event → Save
4. Restart device if issue persists

### Event List is Empty in Widget Configuration

**Cause**: All events are archived
**Fix**: 
1. Open app
2. Unarchive an event, or
3. Create a new event

### Widget Shows Old Data

**Cause**: Timeline not refreshing
**Fix**:
1. Open the app (triggers data reload)
2. Wait for next scheduled refresh
3. Or remove and re-add widget

## 💡 Tips & Best Practices

### 1. Widget Placement
- **Top row**: Most visible, best for primary event
- **Middle**: Good for secondary tracking
- **Bottom**: Less visible but still accessible

### 2. Event Selection
- Choose events you check most frequently
- Match widget count to your most important habits
- Use emojis that are easily recognizable at small sizes

### 3. Multiple Widgets
- Maximum recommended: 3-4 widgets
- More than 4 may clutter Home Screen
- Consider using app for less critical events

### 4. Organization
**Option A: Grid Layout**
```
[☕️ Coffee]  [🚬 Smoking]
[🍰 Sugar]   [💊 Pills]
```

**Option B: Row Layout**
```
[☕️ Coffee]  [🚬 Smoking]  [🍰 Sugar]
```

### 5. When to Update Configuration
- When you complete a goal (switch to new event)
- When priorities change
- When you archive an old event

## 🎨 Customization Ideas

Since the widget is configurable, you can:

### Daily Focus
- Morning: Show "☕️ Coffee"
- Afternoon: Switch to "🍰 Sugar"
- Evening: Switch to "😴 Sleep"

### Goal Tracking
- Week 1-4: "🚬 Smoking"
- After goal met: Switch to "🍷 Alcohol"

### Multiple Home Screen Pages
- **Page 1**: Work-related (☕️ Coffee, 💻 Screen Time)
- **Page 2**: Health-related (🏃 Exercise, 🍔 Junk Food)
- **Page 3**: Lifestyle (🎮 Gaming, 📱 Social Media)

## 📊 Technical Details

### Widget Identifier
- **Kind**: `SinceWidget`
- **Family**: `systemSmall` (1×1)

### Configuration Intent
- **Type**: `SelectEventIntent`
- **Parameter**: `event` (EventEntity)

### Data Source
- **Storage**: AppGroup shared container
- **Identifier**: `group.com.sinced.app`
- **Format**: JSON with ISO8601 dates

### Timeline Policy
- **Type**: `.after(date)` with calculated interval
- **Reload**: Manual via `WidgetCenter.shared.reloadAllTimelines()`

## 🚀 Advanced Usage

### Widget Stacks (iOS 17+)

Create a Smart Stack with multiple Since widgets:

1. Add first widget normally
2. Long press and drag second widget on top of first
3. Creates a widget stack
4. Swipe to switch between events
5. iOS can auto-rotate based on time of day!

### Focus Modes

Configure widgets to show different events per Focus:

1. **Work Focus**: Hide leisure tracking widgets
2. **Personal Focus**: Hide work-related widgets
3. **Sleep Focus**: Show only sleep-related events

### Shortcuts Integration (Future)

Planned for v1.2:
- "Show widget for Coffee event"
- "Update widget to display next event"
- "Cycle through event widgets"

## 📚 Related Documentation

- **README.md** - Overall project documentation
- **SETUP_GUIDE.md** - Initial app setup
- **QUICKSTART.md** - Get running quickly
- **PROJECT_SUMMARY.md** - Technical deep-dive

## ✅ Checklist: Widget Setup

- [ ] App built and running
- [ ] At least one event created in app
- [ ] Widget added to Home Screen
- [ ] Event selected in widget configuration
- [ ] Widget displays correct event
- [ ] Widget updates are working
- [ ] Multiple widgets configured (optional)

## 🎉 You're All Set!

Your Since widget is now fully configured and will keep you updated on your tracked events right from your Home Screen. The widget will automatically refresh based on the optimal schedule, and you can change which event it displays anytime!

---

**Widget Version**: 1.0  
**Last Updated**: October 31, 2025  
**Supports**: iOS 17.0+  
**Widget Families**: Small (1×1)


