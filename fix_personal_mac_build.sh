#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="${PROJECT_DIR}/Sinced2.xcodeproj"
SCHEME="Sinced2"

echo "=========================================="
echo "  Sinced2 Personal Mac Build Fix Script"
echo "=========================================="
echo ""

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo -e "${RED}This script must be run on macOS.${NC}"
  exit 1
fi

if [[ ! -d "/Applications/Xcode.app" ]]; then
  echo -e "${RED}Xcode.app not found in /Applications.${NC}"
  echo "Install Xcode from the App Store first."
  exit 1
fi

echo -e "${YELLOW}1) Ensure Xcode toolchain is selected...${NC}"
if ! xcode-select -p | /usr/bin/grep -q "/Applications/Xcode.app/Contents/Developer"; then
  echo "Switching active developer directory to Xcode.app..."
  if ! sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer; then
    echo -e "${RED}Failed to switch developer directory.${NC}"
    echo "Run this manually:"
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
  fi
fi
echo -e "${GREEN}OK: $(xcode-select -p)${NC}"
echo ""

echo -e "${YELLOW}2) Run first-launch setup (license/components)...${NC}"
if ! sudo xcodebuild -runFirstLaunch; then
  echo -e "${RED}xcodebuild -runFirstLaunch failed.${NC}"
  echo "Open Xcode once manually and accept prompts, then re-run this script."
  exit 1
fi
echo -e "${GREEN}First-launch setup complete.${NC}"
echo ""

echo -e "${YELLOW}3) Verify swift toolchain discovery...${NC}"
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo -e "${RED}swiftc still not discoverable by xcrun.${NC}"
  echo "Try rebooting macOS, then run:"
  echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  echo "  sudo xcodebuild -runFirstLaunch"
  exit 1
fi
echo -e "${GREEN}swiftc path: $(xcrun --find swiftc)${NC}"
echo -e "${GREEN}$(xcodebuild -version | tr '\n' ' ')${NC}"
echo ""

echo -e "${YELLOW}4) Clean DerivedData and package caches...${NC}"
rm -rf "${HOME}/Library/Developer/Xcode/DerivedData/Sinced2-"*
rm -rf "${HOME}/Library/Caches/org.swift.swiftpm"
echo -e "${GREEN}Caches cleaned.${NC}"
echo ""

echo -e "${YELLOW}5) Resolve Swift packages...${NC}"
xcodebuild -project "${PROJECT_FILE}" -scheme "${SCHEME}" -resolvePackageDependencies
echo -e "${GREEN}Package resolution complete.${NC}"
echo ""

echo -e "${YELLOW}6) Build for iOS Simulator (no signing)...${NC}"
xcodebuild \
  -project "${PROJECT_FILE}" \
  -scheme "${SCHEME}" \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  build
echo -e "${GREEN}Simulator build succeeded.${NC}"
echo ""

echo -e "${YELLOW}7) Required Xcode steps for physical iPhone build...${NC}"
echo "Open Xcode -> Settings -> Accounts and add your Apple ID."
echo "Then for both targets (Sinced2 and WidgetSinced2Extension):"
echo "  - Signing & Capabilities -> Automatically manage signing = ON"
echo "  - Team = your personal Apple ID"
echo "  - Bundle IDs should be:"
echo "      Sinced2: Kolte.Sinced2"
echo "      Widget:  Kolte.Sinced2.Widget"
echo ""
echo -e "${GREEN}Done.${NC}"
