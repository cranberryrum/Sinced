#!/bin/bash

echo "🔧 Widget Connection Fix Script"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="${PROJECT_DIR}/Sinced2.xcodeproj"

# Step 1: Clean derived data
echo "${YELLOW}Step 1: Cleaning build artifacts...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/Sinced2-*
echo "${GREEN}✅ Cleaned derived data${NC}"
echo ""

# Step 2: Reset simulator
echo "${YELLOW}Step 2: Resetting simulator...${NC}"
echo "  Shutting down simulators..."
xcrun simctl shutdown all 2>/dev/null
echo "  Erasing simulator data..."
xcrun simctl erase all 2>/dev/null
echo "${GREEN}✅ Simulator reset${NC}"
echo ""

# Step 3: Clean build
echo "${YELLOW}Step 3: Cleaning project...${NC}"
cd "${PROJECT_DIR}"
xcodebuild -scheme Sinced2 -sdk iphonesimulator clean 2>&1 | grep -E "(CLEAN|error)" | tail -5
echo "${GREEN}✅ Project cleaned${NC}"
echo ""

# Step 4: Build
echo "${YELLOW}Step 4: Building project...${NC}"
BUILD_OUTPUT=$(xcodebuild -scheme Sinced2 -sdk iphonesimulator -configuration Debug build 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo "${GREEN}✅ Build succeeded!${NC}"
else
    echo "${RED}❌ Build failed. Check errors above.${NC}"
    exit 1
fi
echo ""

# Step 5: Instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "${GREEN}✅ All cleanup steps completed!${NC}"
echo ""
echo "${YELLOW}📋 Next Steps (IMPORTANT - Follow in Order):${NC}"
echo ""
echo "1️⃣  ${YELLOW}Open Xcode:${NC}"
echo "   open \"${PROJECT_FILE}\""
echo ""
echo "2️⃣  ${YELLOW}Select Scheme:${NC}"
echo "   Make sure 'Sinced2' (not WidgetSinced2Extension) is selected"
echo ""
echo "3️⃣  ${YELLOW}Select Simulator:${NC}"
echo "   Choose: iPhone 15 Pro (or similar)"
echo ""
echo "4️⃣  ${YELLOW}Run the App:${NC}"
echo "   Press: Cmd+R"
echo ""
echo "5️⃣  ${YELLOW}Create an Event:${NC}"
echo "   • Tap '+' button"
echo "   • Choose emoji (e.g., ☕️)"
echo "   • Enter title (e.g., 'Coffee')"
echo "   • Optionally add a square image"
echo "   • Tap 'Save'"
echo ""
echo "6️⃣  ${YELLOW}Check Console:${NC}"
echo "   Look for these messages:"
echo "   ${GREEN}✅ StorageManager: Using AppGroup container: [path]${NC}"
echo "   ${GREEN}✅ StorageManager: Successfully saved 1 events${NC}"
echo ""
echo "7️⃣  ${YELLOW}Stop the App:${NC}"
echo "   Press: Cmd+. (Command + period)"
echo ""
echo "8️⃣  ${YELLOW}Add Widget:${NC}"
echo "   • Go to home screen (Cmd+Shift+H)"
echo "   • Long press empty space"
echo "   • Tap '+' button (top left)"
echo "   • Search for 'Since'"
echo "   • Add the widget"
echo ""
echo "9️⃣  ${YELLOW}Verify Widget:${NC}"
echo "   Widget should display:"
echo "   ${GREEN}✅ Time value (e.g., '0 days')${NC}"
echo "   ${GREEN}✅ Event title (e.g., 'since Coffee')${NC}"
echo "   ${GREEN}✅ Background image (if you added one)${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${YELLOW}⚠️  IMPORTANT:${NC}"
echo "   • Always run the MAIN APP first to create data"
echo "   • Stop the app before adding the widget"
echo "   • If widget shows 'No events', create an event in the app"
echo ""
echo "${YELLOW}🐛 If still having issues:${NC}"
echo "   • Check console for 'Connection invalidated' errors"
echo "   • Run: ./diagnose_widget.sh"
echo "   • Read: FIX_CONNECTION_INVALIDATED.md"
echo ""



