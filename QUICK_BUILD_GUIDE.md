# Quick Build Guide for iPhone

## ✅ What I Fixed

Changed App Group identifier to work with automatic signing:
- **Old**: `group.Kolte.Sinced2` ❌
- **New**: `group.com.kolte.sinced2` ✅

## 🚀 Build on Your iPhone (3 Simple Steps)

### 1️⃣ Open Project in Xcode
```bash
open /Users/adityakolte/Desktop/Sinced2/Sinced2.xcodeproj
```

### 2️⃣ Select Your iPhone
- Connect your iPhone to Mac
- Click device menu at top
- Choose "Aditya's iPhone" (or "Vishal's iPhone")

### 3️⃣ Press Run
- Press `Cmd + R` (or click ▶️ Play button)
- Xcode will auto-register the App Group
- App will install on your phone! 🎉

## ⚠️ If You Get an Error

### "App Group not available"
**Fix**: Make sure you're signed into Xcode with your Apple ID
- Xcode → Settings → Accounts
- Your Apple ID should be there with team **4PXC3P5GF3**

### "Personal Team doesn't support App Groups"  
**Fix**: You need a paid Apple Developer account ($99/year)

**OR Quick Test Without Widget**:
1. Open Xcode
2. Select "Sinced2" target → Signing & Capabilities
3. Click the "-" next to "App Groups" to remove it
4. Repeat for "WidgetSinced2Extension" target
5. Build (widget won't work but main app will)

### "Device not trusted"
**Fix**: On your iPhone:
- Settings → General → VPN & Device Management
- Trust the developer certificate
- Try building again

## 📖 Detailed Guide

See `PHYSICAL_DEVICE_BUILD_FIX.md` for complete instructions with all options.

## 🎯 Expected Result

✅ No red errors in Xcode  
✅ App installs on your iPhone  
✅ You can create and track events  
✅ Widget works and shows your events  

---

**TL;DR**: Open Xcode, connect iPhone, select it, press Run. Done! 🚀



