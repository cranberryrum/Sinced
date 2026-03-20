#!/bin/bash

echo "🔍 Widget Diagnostics"
echo "===================="
echo ""

# Check entitlements
echo "✓ Checking App Group Configuration..."
MAIN_APP=$(grep -o "group\.com\.kolte\.sinced2" Sinced2/Sinced2.entitlements | head -1)
WIDGET=$(grep -o "group\.com\.kolte\.sinced2" WidgetSinced2/WidgetSinced2.entitlements | head -1)

if [ "$MAIN_APP" == "group.com.kolte.sinced2" ]; then
    echo "  ✅ Main app: $MAIN_APP"
else
    echo "  ❌ Main app group not found"
fi

if [ "$WIDGET" == "group.com.kolte.sinced2" ]; then
    echo "  ✅ Widget: $WIDGET"
else
    echo "  ❌ Widget group not found"
fi

echo ""
echo "✓ Checking Code References..."
STORAGE_FILES=$(grep -l "group\.com\.kolte\.sinced2" Sinced2/Services/StorageManager.swift WidgetSinced2/StorageManager.swift 2>/dev/null | wc -l)
echo "  Found in $STORAGE_FILES StorageManager files"

echo ""
echo "✓ Checking for Common Issues..."

# Check if files exist
if [ ! -f "WidgetSinced2/SinceEvent.swift" ]; then
    echo "  ❌ Missing: WidgetSinced2/SinceEvent.swift"
else
    echo "  ✅ WidgetSinced2/SinceEvent.swift exists"
fi

if [ ! -f "WidgetSinced2/StorageManager.swift" ]; then
    echo "  ❌ Missing: WidgetSinced2/StorageManager.swift"
else
    echo "  ✅ WidgetSinced2/StorageManager.swift exists"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Recommended Actions:"
echo ""
echo "1. Clean build folder:"
echo "   Product → Clean Build Folder (Cmd+Shift+K)"
echo ""
echo "2. Reset simulator (if testing on simulator):"
echo "   Device → Erase All Content and Settings"
echo ""
echo "3. Build and run the MAIN APP first:"
echo "   Select 'Sinced2' scheme → Run (Cmd+R)"
echo ""
echo "4. Create at least one event in the app"
echo ""
echo "5. Stop the app and add the widget to home screen"
echo ""
echo "6. Check Console for errors:"
echo "   Look for 'StorageManager' or 'Widget' logs"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"



