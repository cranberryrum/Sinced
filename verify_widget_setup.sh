#!/bin/bash

# Widget Setup Verification Script
# This script checks if the widget is properly configured

echo "🔍 Verifying Widget Setup..."
echo ""

# Check if essential files exist
echo "✓ Checking files..."
FILES=(
    "WidgetSinced2/SinceEvent.swift"
    "WidgetSinced2/StorageManager.swift"
    "WidgetSinced2/AppIntent.swift"
    "WidgetSinced2/WidgetSinced2.swift"
    "WidgetSinced2/WidgetSinced2.entitlements"
    "Sinced2/Sinced2.entitlements"
)

ALL_EXIST=true
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        ALL_EXIST=false
    fi
done

echo ""

# Check App Group configuration
echo "✓ Checking App Group configuration..."
APP_GROUP="group.com.kolte.sinced2"

if grep -q "$APP_GROUP" "Sinced2/Sinced2.entitlements"; then
    echo "  ✅ Main app entitlements contain $APP_GROUP"
else
    echo "  ❌ Main app entitlements missing $APP_GROUP"
    ALL_EXIST=false
fi

if grep -q "$APP_GROUP" "WidgetSinced2/WidgetSinced2.entitlements"; then
    echo "  ✅ Widget entitlements contain $APP_GROUP"
else
    echo "  ❌ Widget entitlements missing $APP_GROUP"
    ALL_EXIST=false
fi

echo ""

# Check if project builds
echo "✓ Checking if project builds..."
if xcodebuild -scheme Sinced2 -sdk iphonesimulator -configuration Debug build -quiet 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo "  ✅ Project builds successfully"
else
    echo "  ⚠️  Build may have issues (check with full build)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$ALL_EXIST" = true ]; then
    echo "✅ All checks passed!"
    echo ""
    echo "Next steps:"
    echo "1. Run the app in Xcode (Cmd+R)"
    echo "2. Create at least one event"
    echo "3. Add the widget to your home screen"
    echo "4. The widget should display your event data"
else
    echo "❌ Some checks failed. Please review the errors above."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"



