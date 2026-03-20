# Widget Configuration Feature - Implementation Guide

## Overview
This guide documents the widget configuration feature that allows users to customize how their event widget displays time (hours, days, months, or years) with a real-time preview.

## What Was Implemented

### 1. **Time Unit Selection**
Users can now choose how the widget displays time:
- **Hours** - Shows elapsed time in hours (e.g., "48 hours")
- **Days** - Shows elapsed time in days (e.g., "12 days") - DEFAULT
- **Months** - Shows elapsed time in months (e.g., "3 months")
- **Years** - Shows elapsed time in years (e.g., "2 years")

### 2. **Widget Preview Card**
A new card on the Event Detail page that shows:
- **Real-time Widget Preview** - A 1:1 aspect ratio preview matching exactly how the widget will appear on the home screen
- **Image Display** - Shows the user's uploaded image (1:1 aspect ratio, fills completely with no padding)
- **Gradient Overlay** - Black gradient covering the bottom 40% of the image (opacity from 1% to 100%)
- **Time Display** - Large bold text showing the time value (e.g., "12 days")
- **Event Name** - Smaller text showing "since [event name]"
- **Time Unit Selector** - Four buttons to switch between Hours, Days, Months, and Years
- **Real-time Updates** - Preview updates instantly as you change the time unit

### 3. **Widget Updates**
The actual iOS widget now:
- Uses the selected time unit preference
- Displays the time in the format chosen by the user
- Shows "since [event name]" instead of the date
- Maintains the gradient overlay design for better text readability

## Files Modified

### New Files Created:
1. **`Sinced2/Views/WidgetPreviewCard.swift`** - Widget configuration card with preview

### Modified Files:
1. **`Sinced2/Models/SinceEvent.swift`**
   - Added `WidgetTimeUnit` enum (Hours, Days, Months, Years)
   - Added `widgetTimeUnit` property to `SinceEvent`
   - Added `widgetTimeValue()` method to calculate display time

2. **`Sinced2/Views/EventDetailView.swift`**
   - Added widget preview card to event detail page
   - Added local state management for real-time updates
   - Positioned widget card between timer and milestones

3. **`WidgetSinced2/WidgetSinced2.swift`**
   - Updated to use `widgetTimeValue()` instead of `relativeTimeString`
   - Changed caption to show event name instead of date
   - Improved gradient overlay to match design (bottom 40%)

4. **`Sinced2/ViewModels/EventViewModel.swift`**
   - Already had `updateEvent()` method (no changes needed)

## Design Specifications

### Widget Preview Dimensions
- **Aspect Ratio**: 1:1 (square)
- **Corner Radius**: 24pt
- **Shadow**: Black 15% opacity, radius 12, offset (0, 4)

### Text Styling
- **Main Time Value**: 
  - Font: System Bold, 56pt
  - Color: White
  - Tracking: -2.24
  - Shadow: Black 40% opacity, radius 4, offset (0, 2)

- **Event Name**:
  - Font: System Medium, 18pt
  - Color: White 95% opacity
  - Tracking: -0.72
  - Shadow: Black 40% opacity, radius 4, offset (0, 2)

### Gradient Overlay
- **Coverage**: Bottom 40% of image
- **Colors**: Black 1% → Black 100%
- **Direction**: Top to bottom
- **Blur**: 2pt radius

### Time Unit Buttons
- **Layout**: 4 buttons in a row
- **Selected State**: Green background (#00621a), white text
- **Unselected State**: Transparent background, green text, green border
- **Corner Radius**: 20pt
- **Padding**: 16pt horizontal, 10pt vertical

## How to Test

### In Xcode:
1. Open `Sinced2.xcodeproj` in Xcode
2. Add `WidgetPreviewCard.swift` to the project if not already added:
   - Right-click on `Sinced2/Views` folder
   - Select "Add Files to Sinced2..."
   - Select `WidgetPreviewCard.swift`
   - Ensure it's added to the Sinced2 target

3. Build and run the app (⌘+R)

### Testing the Feature:
1. Launch the app
2. Create a new event with an image
3. Tap on the event to open Event Detail view
4. Scroll to find the "Widget Configuration" card
5. You should see:
   - A square preview of your widget with the image
   - Large text showing time (default: "X days")
   - Text showing "since [your event name]"
   - Four buttons: Hours, Days, Months, Years

6. **Test Time Unit Changes**:
   - Tap "Hours" - Preview should update to show hours
   - Tap "Months" - Preview should update to show months
   - Tap "Years" - Preview should update to show years
   - Notice the preview updates instantly

7. **Test Widget on Home Screen**:
   - Long press on home screen
   - Tap "+" to add widget
   - Search for "Sinced2"
   - Add the widget
   - Edit widget to select your event
   - Widget should show time in the selected unit

## Known Considerations

1. **Image Requirements**: 
   - Images should be 1:1 aspect ratio for best results
   - The app crops to square when selecting from gallery

2. **Time Calculations**:
   - Hours: Total elapsed seconds / 3600
   - Days: Total elapsed seconds / 86400
   - Months: Total elapsed seconds / (86400 * 30) - approximate
   - Years: Total elapsed seconds / (86400 * 365) - approximate

3. **Widget Refresh**:
   - Widgets refresh based on elapsed time
   - First hour: Every 1 minute
   - First 24 hours: Every 5 minutes
   - After 24 hours: Every 15 minutes

## Code Architecture

### Data Flow:
```
User taps time unit button
    ↓
WidgetPreviewCard updates localEvent.widgetTimeUnit
    ↓
viewModel.updateEvent(localEvent) called
    ↓
StorageManager saves updated event
    ↓
Widget reads widgetTimeUnit on next refresh
    ↓
Widget displays time in selected unit
```

### Key Methods:
- `widgetTimeValue()` - Calculates and formats time for display
- `formatTimeValueForWidget()` - Helper for preview formatting
- `updateEvent()` - Saves changes to persistent storage

## Future Enhancements

Potential improvements for future versions:
1. Custom time formats (e.g., "12d 3h 45m")
2. Multiple widget sizes (medium, large)
3. Widget background color customization
4. Font size adjustments
5. Alternative gradient styles
6. Live activities support

## Troubleshooting

### Preview not showing image:
- Ensure the event has an image uploaded
- Check that imageData is not nil
- Verify image is in correct format (JPEG/PNG)

### Time not updating:
- Check that timer is running (updates every second in preview)
- Verify widgetTimeUnit is being saved correctly
- Ensure updateEvent() is being called

### Widget on home screen not updating:
- Force refresh by removing and re-adding widget
- Check widget permissions in Settings
- Verify app has background refresh enabled

## Related Files
- `Sinced2/Views/WidgetPreviewCard.swift` - Main preview component
- `Sinced2/Models/SinceEvent.swift` - Data model with time unit
- `WidgetSinced2/WidgetSinced2.swift` - Actual widget implementation
- `Sinced2/Views/EventDetailView.swift` - Detail page integration

---

**Implementation Date**: November 13, 2025
**Version**: 1.0
**Status**: ✅ Complete

