# Personal Mac Build Fix (CodeSign + swiftc Errors)

If you imported this project from another machine and see errors like:

- `No Accounts: Add a new account in Accounts settings.`
- `No profiles for 'Kolte.Sinced2' were found`
- `Unable to discover 'swiftc' command line tool info`
- `Command ExecuteExternalTool failed with a nonzero exit code`
- `failed to save attachment ... DerivedData ...`

use this sequence.

## 1) Run the repair script on your Mac

From the project folder:

```bash
chmod +x ./fix_personal_mac_build.sh
./fix_personal_mac_build.sh
```

This script:
- re-selects Xcode toolchain
- runs first-launch setup
- verifies `swiftc` discovery
- clears DerivedData/caches
- resolves Swift packages
- verifies simulator build

## 2) Add your Apple ID in Xcode

In Xcode:
- `Xcode -> Settings -> Accounts -> + -> Apple Account`

Without an account, physical-device signing cannot work.

## 3) Configure signing for both targets

For **Sinced2** and **WidgetSinced2Extension**:
- Signing & Capabilities -> **Automatically manage signing** = ON
- Team = your Apple ID

Bundle IDs used by this project:
- App: `Kolte.Sinced2`
- Widget: `Kolte.Sinced2.Widget`

## 4) Clean and run

- `Product -> Clean Build Folder`
- Build on simulator first
- Then run on your iPhone

## Notes

- If your Apple account is a free/personal team, some capabilities may be restricted by Apple.
- If widget signing still blocks install, first run just the app target on device, then enable widget once signing is valid for both targets.
