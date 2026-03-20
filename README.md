# Since - Time Tracking App

A minimal, elegant iOS app built with SwiftUI and WidgetKit for tracking time since meaningful events.

## 📱 Overview

**Since** helps users track time since any event (like last coffee, last cigarette, or last sugar intake). Users choose an emoji, name the event, and see how long it's been — both in the app and on their Home Screen via a 1×1 widget.

The design is minimal, calm, and distinctly iOS-native, with elegant typography, soft spacing, and no clutter.

## ✨ Features

- **Event Tracking**: Track unlimited events with custom emojis and names
- **Real-time Updates**: Live timer that updates automatically
- **Home Screen Widget**: 1×1 widget showing your most recent event
- **Reset & History**: Reset events with optional notes, view complete timeline
- **Share Progress**: Share your achievements with friends
- **Milestones**: Automatic milestone tracking (24h, 7d, 30d, 90d, 365d)
- **Dark Mode**: Full support for light and dark appearances
- **Accessibility**: VoiceOver support, Dynamic Type, and reduced motion friendly

## 🏗️ Architecture

### Frameworks Used
- **SwiftUI**: Modern declarative UI framework
- **WidgetKit**: Home Screen widgets
- **AppIntents**: Widget configuration
- **Foundation**: Core functionality
- **UserNotifications**: Milestone notifications (future)
- **CloudKit**: iCloud sync (future)

### Project Structure

```
Sinced2/
├── Models/
│   └── SinceEvent.swift          # Data models (SinceEvent, Reset)
├── Views/
│   ├── OnboardingView.swift      # First-launch welcome screen
│   ├── CreateEventView.swift     # Event creation with emoji picker
│   ├── EventListView.swift       # Main home screen
│   ├── EventDetailView.swift     # Detailed event view with reset
│   └── ResetSheetView.swift      # Reset flow with notes
├── ViewModels/
│   └── EventViewModel.swift      # State management
├── Services/
│   └── StorageManager.swift      # JSON persistence with AppGroup
├── Utilities/
│   ├── ColorExtensions.swift     # Color utilities
│   ├── HapticManager.swift       # Haptic feedback
│   └── ViewModifiers.swift       # Reusable view modifiers
└── Sinced2App.swift              # App entry point

SinceWidget/
├── SinceWidget.swift             # Widget implementation
├── SinceWidgetBundle.swift       # Widget bundle
├── SelectEventIntent.swift       # Widget configuration intent
└── Info.plist                    # Widget extension configuration
```

## 💾 Data Storage

- **Local Storage**: Events stored as JSON in AppGroup shared container
- **Widget Sharing**: Uses AppGroup identifier `group.com.sinced.app`
- **Format**: JSON with ISO8601 date encoding
- **Location**: `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`

## 🎨 Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Calm UI** | Gentle typography, soft colors, ample spacing |
| **Native Feel** | Follows Apple HIG, uses system fonts and colors |
| **Frictionless** | Create event in 3 taps or less |
| **Private** | No accounts, no analytics, data stays local |
| **Glanceable** | Widget-first design for quick checks |

### Typography
- **SF Pro Display / SF Pro Text** throughout
- Title: `.title2` (semibold)
- Timer: `.title` or `.largeTitle`
- Caption: `.footnote`
- All text supports Dynamic Type

### Colors
- Background: `systemBackground` (adapts to light/dark mode)
- Accent: Auto-generated from emoji
- Cards: `secondarySystemBackground`
- Text: `primary`, `secondary` (system colors)

### Layout
- Padding: 16pt standard
- Spacing: 8/12/16pt
- Corner radius: 12–20pt
- Shadows: Minimal, subtle

## 🔔 Widget Updates

The widget refreshes intelligently based on elapsed time:

| Time Elapsed | Refresh Interval |
|--------------|-----------------|
| 0–60 min | Every 1 minute |
| 1–24 hours | Every 5 minutes |
| > 24 hours | Every 15 minutes |

Widget also updates on:
- `significantTimeChange`
- `timeZoneChange`
- Manual reset

## 📲 Setup & Installation

### Requirements
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Build Steps

1. **Open Project**
   ```bash
   cd /Users/adityakolte/Desktop/Sinced2
   open Sinced2.xcodeproj
   ```

2. **Configure App Group**
   - Select the main app target
   - Go to Signing & Capabilities
   - Add App Group capability
   - Create/select `group.com.sinced.app`
   - Repeat for Widget extension target

3. **Configure Signing**
   - Update Bundle Identifier
   - Select your Development Team
   - Ensure automatic signing is enabled

4. **Build & Run**
   - Select a simulator or device
   - Press `Cmd+R` to build and run

### Widget Setup (On Device)

1. Long-press on Home Screen
2. Tap "+" in top-left corner
3. Search for "Since"
4. Select the small (1×1) widget
5. Tap "Add Widget"

## 🧪 Testing Checklist

- [ ] Create first event (onboarding flow)
- [ ] Create additional events
- [ ] View event details
- [ ] Reset event with note
- [ ] Delete event (swipe action)
- [ ] Archive event
- [ ] Add widget to Home Screen
- [ ] Verify widget updates
- [ ] Test in dark mode
- [ ] Test with Dynamic Type (large text)
- [ ] Test VoiceOver navigation
- [ ] Test in airplane mode (offline)

## 🛠️ Future Enhancements

### v1.1
- [ ] iCloud sync via CloudKit
- [ ] Multiple widget sizes (medium, large)
- [ ] Lock Screen widgets (iOS 16+)
- [ ] Interactive widgets (iOS 17+)

### v1.2
- [ ] Local notifications for milestones
- [ ] Custom milestone goals
- [ ] Export/import events
- [ ] Charts and statistics

### v1.3
- [ ] iPad optimization
- [ ] macOS app (Mac Catalyst)
- [ ] Apple Watch companion
- [ ] Siri Shortcuts integration

## 📄 License

Copyright © 2025. All rights reserved.

## 🙏 Acknowledgments

Built following Apple's Human Interface Guidelines and best practices for SwiftUI development.

---

**Version**: 1.0.0  
**Last Updated**: October 31, 2025  
**Platform**: iOS 17.0+


