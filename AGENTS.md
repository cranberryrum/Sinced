# AGENTS.md

## Cursor Cloud specific instructions

### Platform requirement (read first)

This repository is a **native iOS app** ("Since" / Xcode project `Sinced2.xcodeproj`) built with
**SwiftUI + WidgetKit**. It can only be built, run, linted, and tested on **macOS with Xcode**
(Xcode 15+, iOS 18 simulator). The sources depend on Apple-only frameworks — SwiftUI, WidgetKit,
UIKit, AppIntents, PhotosUI, UserNotifications, QuartzCore — none of which exist in the
open-source Swift toolchain for Linux.

Cursor Cloud Agents run on **Linux (Ubuntu x86_64)**, so on this VM you **cannot**:

- build the app (`xcodebuild` / Xcode are macOS-only and cannot be installed on Linux),
- run it in an iOS Simulator (macOS-only),
- run the unit/UI tests (they use `@testable import Sinced2` and `import Testing`, which pull in the
  SwiftUI app module and Xcode's testing frameworks),
- lint it (no lint config exists; there is no Linux-installable toolchain that can parse these sources).

There is **nothing to `pip`/`npm`/`apt` install** on Linux that makes this project buildable. The only
third-party dependency is `lottie-ios`, resolved by Swift Package Manager inside Xcode
(`Sinced2.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`). Do not attempt to
install a Linux Swift toolchain to "fix" builds — it will not provide the Apple SDKs and will not help.

Treat build/run/test work as **requiring a macOS host**. If a task needs the app compiled or exercised,
it must be done on a Mac.

### How to build / run / test (macOS only — for reference)

These commands are for a macOS + Xcode environment, not this Linux VM:

```bash
# Open in Xcode
open Sinced2.xcodeproj

# Build for simulator
xcodebuild -project Sinced2.xcodeproj -scheme Sinced2 \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
xcodebuild test -project Sinced2.xcodeproj -scheme Sinced2 \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

To run the app in Xcode: select the `Sinced2` scheme + a simulator/device and press `⌘R`.

### Repo gotchas (docs drift)

- **Active widget code is `WidgetSinced2/`**, target `WidgetSinced2Extension`. The top-level
  `SinceWidget/` folder is **legacy** and is **not** wired into `Sinced2.xcodeproj` — don't edit it
  expecting build changes.
- **App Group is `group.com.kolte.sinced2`** in the actual project/entitlements. Several `.md` docs and
  `README.md` still reference the old `group.com.sinced.app`; trust the entitlements files and
  `project.pbxproj`, not the prose docs.
- The many `*.md` files at the repo root are historical implementation/fix notes; they are not a build
  system and can be inconsistent with current code.
- The `*.sh` scripts at the root (`verify_widget_setup.sh`, `quick_fix.sh`, `fix_widget_build.sh`,
  `diagnose_widget.sh`) are macOS/Xcode helpers and are not meaningful on Linux.
