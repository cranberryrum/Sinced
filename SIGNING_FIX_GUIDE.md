# Code Signing Fix Guide for iPhone 11

## 🚨 Problem

You're getting these errors when building on your iPhone 11:
- **Embedded binary not signed with same certificate**
- **Maximum App ID limit reached** (10 App IDs per 7 days)
- **No provisioning profiles** for widget

## ✅ Solution

I've already updated the code files. Now you need to configure Xcode settings:

---

## 📝 Step-by-Step Fix (5 minutes)

### **Step 1: Fix Main App Bundle Identifier**

1. Open **Xcode**
2. Select the **project** in navigator (top item)
3. Select **Sinced2** target
4. Go to **Signing & Capabilities** tab
5. Under "Bundle Identifier", change it to:
   ```
   Kolte.Sinced2
   ```
6. Check **"Automatically manage signing"**
7. Select your **Team** (your Apple ID)
8. Deployment Target: **iOS 17.0**

---

### **Step 2: Fix Widget Bundle Identifier**

This is the KEY fix to avoid creating a new App ID!

1. Still in the project, select **WidgetSinced2Extension** target
2. Go to **Signing & Capabilities** tab
3. **IMPORTANT**: Change Bundle Identifier from:
   ```
   ❌ Kolte.Sinced2.WidgetSinced2
   ```
   
   **To**:
   ```
   ✅ Kolte.Sinced2.Widget
   ```
   
   This makes the widget a **child** of your main app, so it uses the SAME App ID!

4. Check **"Automatically manage signing"**
5. Select the **SAME Team** as main app
6. Deployment Target: **iOS 17.0**

---

### **Step 3: Add Entitlements File to Widget Target**

1. In Xcode file navigator, find `WidgetSinced2/WidgetSinced2.entitlements`
2. Select the file
3. Open **File Inspector** (right panel, or press ⌥⌘1)
4. Under **Target Membership**, check **WidgetSinced2Extension**

---

### **Step 4: Configure App Groups (BOTH Targets)**

#### For Main App (Sinced2):

1. Select **Sinced2** target
2. **Signing & Capabilities** tab
3. If "App Groups" is already there:
   - Click on the App Group name
   - Change it to: `group.Kolte.Sinced2`
   - Make sure the checkbox is checked
   
4. If "App Groups" is NOT there:
   - Click **+ Capability**
   - Add **App Groups**
   - Click **+ button** under App Groups
   - Enter: `group.Kolte.Sinced2`
   - Press Enter, then check the box

#### For Widget (WidgetSinced2Extension):

1. Select **WidgetSinced2Extension** target
2. **Signing & Capabilities** tab
3. If "App Groups" is already there:
   - Click on the App Group name
   - Change it to: `group.Kolte.Sinced2` (SAME as main app!)
   - Make sure the checkbox is checked
   
4. If "App Groups" is NOT there:
   - Click **+ Capability**
   - Add **App Groups**
   - Click **+ button** under App Groups
   - Enter: `group.Kolte.Sinced2`
   - Press Enter, then check the box

**⚠️ CRITICAL**: Both targets MUST use the EXACT SAME App Group identifier!

---

### **Step 5: Add Required Files to Widget Target**

The widget needs access to shared model and storage files.

**Files to add** (if not already in target):

1. In Xcode navigator, select `Sinced2/Models/SinceEvent.swift`
2. Open **File Inspector** (⌥⌘1)
3. Under **Target Membership**, check:
   - ✅ Sinced2
   - ✅ WidgetSinced2Extension

4. Repeat for `Sinced2/Services/StorageManager.swift`:
   - ✅ Sinced2
   - ✅ WidgetSinced2Extension

---

### **Step 6: Clean & Rebuild**

1. **Clean Build Folder**: 
   - Menu → Product → Clean Build Folder (or ⌘⇧K)

2. **Select your iPhone 11** in device dropdown

3. **Build** (⌘B)

4. **Run** (⌘R)

---

## ✅ Verification Checklist

Before building, verify:

- [ ] Main app Bundle ID: `Kolte.Sinced2`
- [ ] Widget Bundle ID: `Kolte.Sinced2.Widget` (child of main app)
- [ ] Both targets have SAME Team selected
- [ ] Both targets have App Group: `group.Kolte.Sinced2`
- [ ] Both targets have "Automatically manage signing" checked
- [ ] `SinceEvent.swift` is in both targets
- [ ] `StorageManager.swift` is in both targets
- [ ] `WidgetSinced2.entitlements` is in widget target
- [ ] Both deployment targets are iOS 17.0+

---

## 🎯 Why This Works

### Problem Explanation:
1. You hit Apple's **free account limit** (10 App IDs per 7 days)
2. Widget bundle ID `Kolte.Sinced2.WidgetSinced2` would create a NEW App ID
3. This failed because you're at the limit

### Solution Explanation:
1. Changed widget bundle ID to `Kolte.Sinced2.Widget`
2. This format (parent.child) uses the PARENT's App ID
3. No new App ID created = avoids the limit! ✅
4. Both app and widget now share the same App ID
5. Code files updated to use `group.Kolte.Sinced2`

---

## 🐛 Troubleshooting

### Error: "Failed to register bundle identifier"

**Fix**: The bundle identifier format is correct, but:
1. Clean build folder (⌘⇧K)
2. Quit Xcode
3. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reopen Xcode
5. Try again

---

### Error: "Embedded binary is not signed..."

**Fix**: Both targets must use same Team and signing settings
1. Verify both targets show the SAME Team
2. Both should show "Automatically manage signing" checked
3. Both should show matching provisioning profiles
4. Clean and rebuild

---

### Error: "No provisioning profiles found"

**Fix**: Xcode needs to create them
1. Make sure you're logged into Xcode (Preferences → Accounts)
2. Verify "Automatically manage signing" is checked
3. Wait a few seconds for Xcode to create profiles
4. If still failing, try:
   - Uncheck "Automatically manage signing"
   - Check it again
   - Wait for Xcode to re-generate profiles

---

### Error: "App Groups capability not found"

**Fix**: Manually sync capabilities
1. Select target
2. Signing & Capabilities
3. Remove App Groups capability (- button)
4. Add it back (+ Capability → App Groups)
5. Add group: `group.Kolte.Sinced2`
6. Repeat for other target

---

### Error: Widget still not working after build succeeds

**Fix**: Target membership issue
1. Verify `SinceEvent.swift` is checked in both targets:
   - File Inspector → Target Membership
   - ✅ Sinced2
   - ✅ WidgetSinced2Extension
   
2. Verify `StorageManager.swift` is checked in both targets
3. Clean and rebuild

---

## 💡 Quick Reference

### Bundle Identifiers (Must Match These Exactly):
```
Main App:     Kolte.Sinced2
Widget:       Kolte.Sinced2.Widget
App Group:    group.Kolte.Sinced2
```

### Files in Both Targets:
```
✅ SinceEvent.swift
✅ StorageManager.swift
```

### Widget Target Only:
```
✅ WidgetSinced2.swift
✅ WidgetSinced2Bundle.swift
✅ WidgetSinced2Control.swift
✅ AppIntent.swift
✅ WidgetSinced2.entitlements
```

---

## 🎉 Success!

After following these steps, you should be able to:
1. ✅ Build successfully on your iPhone 11
2. ✅ Run the app
3. ✅ Create events
4. ✅ Add widget to Home Screen
5. ✅ Widget shows your events!

---

## 📞 Still Having Issues?

If you're still getting errors:

1. **Screenshot the exact error** from Xcode
2. **Check Signing & Capabilities** for both targets - take screenshots
3. **Verify all bundle identifiers** match the format above
4. **Try on simulator first** to isolate device-specific issues

The most common issue is bundle identifiers not matching exactly, or App Groups not being identical on both targets.

---

**Last Updated**: October 31, 2025  
**For**: iPhone 11, iOS 18  
**Xcode**: 15.0+  


