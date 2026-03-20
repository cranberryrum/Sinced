#!/bin/bash

echo "🔧 Fixing Widget Build Issues..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

echo "1️⃣ Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Sinced2-*
echo "✅ Derived data cleaned"
echo ""

echo "2️⃣ Checking file existence..."
if [ -f "Sinced2/Services/StorageManager.swift" ]; then
    echo "✅ StorageManager.swift exists"
else
    echo "❌ StorageManager.swift NOT FOUND"
fi

if [ -f "Sinced2/Models/SinceEvent.swift" ]; then
    echo "✅ SinceEvent.swift exists"
else
    echo "❌ SinceEvent.swift NOT FOUND"
fi
echo ""

echo "3️⃣ Verifying Swift syntax..."
echo "Checking StorageManager.swift..."
if xcrun swiftc -parse Sinced2/Services/StorageManager.swift 2>/dev/null; then
    echo "✅ StorageManager.swift syntax is valid"
else
    echo "⚠️  StorageManager.swift has syntax issues"
fi

echo "Checking SinceEvent.swift..."
if xcrun swiftc -parse Sinced2/Models/SinceEvent.swift 2>/dev/null; then
    echo "✅ SinceEvent.swift syntax is valid"
else
    echo "⚠️  SinceEvent.swift has syntax issues"
fi
echo ""

echo "4️⃣ Checking project file..."
if grep -q "Services/StorageManager.swift" Sinced2.xcodeproj/project.pbxproj; then
    # Check if it's in exceptions
    if grep -A 5 "membershipExceptions" Sinced2.xcodeproj/project.pbxproj | grep -q "StorageManager"; then
        echo "❌ StorageManager.swift is EXCLUDED from widget target"
        echo "   This needs to be fixed in the project file!"
    else
        echo "✅ StorageManager.swift is NOT excluded (correct)"
    fi
fi
echo ""

echo "5️⃣ Next steps:"
echo "   1. Open Xcode: open Sinced2.xcodeproj"
echo "   2. Clean: Product → Clean Build Folder (⇧⌘K)"
echo "   3. Build: Product → Build (⌘B)"
echo ""
echo "   If still failing:"
echo "   - Select StorageManager.swift in Project Navigator"
echo "   - Check Target Membership in File Inspector"
echo "   - Ensure WidgetSinced2Extension is checked"
echo ""
echo "Done! 🎉"



