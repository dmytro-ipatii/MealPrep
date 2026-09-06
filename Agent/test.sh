#!/bin/bash
# Run MealPrep unit tests on the iOS simulator.
# Pass a filter as the first argument, e.g. ./scripts/test.sh MealPrepTests/CostCalculatorTests

set -uo pipefail

SCHEME="${SCHEME:-MealPrep}"
PROJECT="${PROJECT:-MealPrep.xcodeproj}"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16,OS=latest}"

ARGS=(test -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -quiet)
if [ $# -gt 0 ]; then
  ARGS+=(-only-testing:"$1")
fi

xcodebuild "${ARGS[@]}" CODE_SIGNING_ALLOWED=NO 2>&1 \
  | grep -E "error:|failed|passed|Executed|TEST" | head -60

exit "${PIPESTATUS[0]}"
