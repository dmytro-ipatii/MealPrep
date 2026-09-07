#!/bin/bash
# Build MealPrep for the iOS simulator.
# Edit SCHEME / PROJECT / DESTINATION to match your Xcode project.

set -uo pipefail

SCHEME="${SCHEME:-MealPrep}"
PROJECT="${PROJECT:-MealPrep.xcodeproj}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16,OS=latest}"

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -quiet \
  CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|warning:|BUILD" | head -50

exit "${PIPESTATUS[0]}"
