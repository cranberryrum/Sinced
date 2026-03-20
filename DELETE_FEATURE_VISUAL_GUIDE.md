# Delete Feature - Visual Guide

## Button States & Interactions

### 1. Initial State
```
┌─────────────────────────────────┐
│  Reset Timer                    │ ← Blue, Filled
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  Share Progress                 │ ← Blue, Outlined
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  🗑 Delete Event                │ ← Red, Outlined (NEW)
└─────────────────────────────────┘
```

### 2. Short Tap → Toast Appears
```
User taps button (< 1.5s)
       ↓
┌─────────────────────────────────┐
│  🗑 Delete Event                │
└─────────────────────────────────┘

         ↓ (Animate up from bottom)

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ✋ Long press to delete       ┃ ← Toast
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### 3. Long Press → Progress Animation
```
User holds button for 1.5s
       ↓
┌─────────────────────────────────┐
│█████████░░░░░░░░░░░░░░░░░░░░░░░│ ← Red fills left to right
│  🗑 Hold to Delete...           │
└─────────────────────────────────┘

Progress: 0% ━━━━━━━━━━━━━━━► 100%
Time:     0s ━━━━━━━━━━━━━━━► 1.5s
```

### 4. Delete Complete → Animation Sequence
```
Step 1: Button moves up (-20px) & scales down (0.9x)
        + Fade out (opacity → 0)

┌─────────────────────────────────┐
│  🗑 Delete Event                │
└─────────────────────────────────┘
         ↑ (Moves up & fades)


Step 2: Success toast appears

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  ✓ ☕ Coffee deleted           ┃ ← Success Toast
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


Step 3: Navigate back to home screen
        (Event List View)
```

## Visual Timeline

```
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│  0.0s    │  0.5s    │  1.0s    │  1.5s    │  2.0s    │
├──────────┼──────────┼──────────┼──────────┼──────────┤
│          │          │          │          │          │
│ Press    │ Progress │ Progress │ Delete   │ Navigate │
│ Start    │ 33%      │ 66%      │ Trigger  │ Home     │
│          │          │          │          │          │
│ Scale    │          │          │ Move Up  │          │
│ Down     │          │          │ Fade Out │          │
│ (0.96x)  │          │          │          │          │
│          │          │          │          │          │
│ Haptic:  │          │          │ Haptic:  │          │
│ Light    │          │          │ Warning  │          │
│          │          │          │          │          │
└──────────┴──────────┴──────────┴──────────┴──────────┘
```

## Color & Style Specifications

### Delete Button
- **Background**: Red with 15% opacity (`Color.red.opacity(0.15)`)
- **Progress Fill**: Red with 30% opacity (`Color.red.opacity(0.3)`)
- **Text Color**: Red (`Color.red`)
- **Border**: None (filled background)
- **Corner Radius**: 12pt
- **Height**: 50pt
- **Font**: `.headline`
- **Icon**: `trash` (SF Symbol)

### Toast Notification
- **Background**: Black with 85% opacity (`Color.black.opacity(0.85)`)
- **Text Color**: White
- **Shape**: Capsule
- **Padding**: 20px horizontal, 14px vertical
- **Position**: Bottom of screen, 50pt from bottom
- **Shadow**: 10pt radius, 5pt Y offset, 20% opacity
- **Animation**: Spring (0.4s duration, 0.7 damping)

### Toast Icons
- **Short Press**: `hand.tap.fill` (hand icon)
- **Delete Success**: `checkmark.circle.fill` (checkmark)
- **Icon Size**: 16pt
- **Icon Weight**: Semibold

## Animation Specifications

### Press Animation
```swift
Duration: 0.3s
Type: Spring
Response: 0.3
Damping: 0.6
Scale: 1.0 → 0.96
```

### Progress Fill
```swift
Duration: 1.5s (long press duration)
Type: Linear
Width: 0% → 100% of button width
```

### Delete Animation
```swift
Duration: 0.35s
Type: Spring
Response: 0.35
Damping: 0.8

Properties:
- offsetY: 0 → -20px
- scale: 0.96 → 0.9
- opacity: 1.0 → 0.0
```

### Toast Show/Hide
```swift
Duration: 0.4s
Type: Spring
Response: 0.4
Damping: 0.7
Transition: Move from bottom + Fade
```

## Haptic Feedback Sequence

### Short Press Flow
1. **Press Start**: Light Impact (`UIImpactFeedbackGenerator(.light)`)
2. **Press Release**: Medium Impact (`UIImpactFeedbackGenerator(.medium)`)

### Long Press Flow
1. **Press Start**: Light Impact (`UIImpactFeedbackGenerator(.light)`)
2. **Delete Trigger**: Warning Notification (`UINotificationFeedbackGenerator(.warning)`)

## User Flow Diagram

```
┌─────────────────┐
│ Event Detail    │
│ View            │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ User taps       │◄─────┐
│ Delete button   │      │
└────────┬────────┘      │
         │               │
    ┌────┴────┐          │
    │         │          │
    ▼         ▼          │
  Short     Long         │
  Press     Press        │
    │         │          │
    ▼         ▼          │
  Show     Progress      │
  Toast    Animation     │
    │         │          │
    └─────────┤          │
              ▼          │
          Complete?      │
              │          │
         No   │   Yes    │
         ◄────┴────►     │
         │         │     │
         └─────────┘     │
                   │     │
                   ▼     │
              Delete     │
              Event      │
                   │     │
                   ▼     │
              Show       │
              Success    │
              Toast      │
                   │     │
                   ▼     │
              Navigate   │
              to Home    │
                   │     │
                   └─────┘
```

## Code Structure

```
Sinced2/
├── Utilities/
│   ├── ToastManager.swift          ← NEW: Toast system
│   ├── HapticManager.swift         ← Existing
│   └── ...
├── Views/
│   ├── DeleteButton.swift          ← NEW: Delete button
│   ├── EventDetailView.swift       ← MODIFIED: Added button & toast
│   └── ...
└── ...
```

## Integration Points

### EventDetailView.swift
```swift
// State management for toasts
@State private var showToast = false
@State private var toastMessage = ""
@State private var toastIcon: String? = nil

// Delete button in action buttons section
DeleteButton(
    eventName: localEvent.title,
    onDelete: { handleDelete() },
    onShortPress: { showShortPressToast() }
)

// Toast modifier
.toast(isShowing: $showToast, message: toastMessage, icon: toastIcon)
```

### DeleteButton.swift
```swift
// Main gesture handler
.simultaneousGesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in handlePressStart() }
        .onEnded { _ in handlePressEnd() }
)

// Timer for long press detection
Timer.scheduledTimer(withTimeInterval: 1.5, ...)
```

### ToastManager.swift
```swift
// View extension for easy integration
extension View {
    func toast(isShowing: Binding<Bool>, message: String, icon: String?) -> some View {
        modifier(Toast(isShowing: isShowing, message: message, icon: icon))
    }
}
```

## Accessibility Considerations

The implementation includes:
- Clear visual feedback (progress indicator)
- Haptic feedback for blind/low-vision users
- Descriptive toast messages
- Adequate touch target size (50pt height)
- High contrast colors (red for destructive action)

## Testing Scenarios

1. **Quick Tap Test**: Tap and immediately release → Toast appears
2. **Long Press Test**: Hold for 1.5s → Button animates, event deletes
3. **Cancelled Long Press**: Press for 1s, release → Button resets
4. **Multiple Events**: Delete several events in succession
5. **Last Event**: Delete the only remaining event
6. **Visual Feedback**: Verify progress fills smoothly
7. **Haptic Feedback**: Test on device with haptics enabled
8. **Toast Visibility**: Verify toast appears and dismisses correctly
9. **Navigation**: Confirm return to home screen after delete
10. **Widget Update**: Verify widget updates after deletion



