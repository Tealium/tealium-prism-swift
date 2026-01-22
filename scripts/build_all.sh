#!/bin/bash
# Custom script to build all targets
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

EXAMPLE_SCHEME='Example_iOS'
IOS_DESTINATION="generic/platform=iOS"

errors=()

# Test CocoaPods Example build
cd ../Example && ../scripts/build.sh --scheme "$EXAMPLE_SCHEME" --destination "$IOS_DESTINATION" || errors+=("$EXAMPLE_SCHEME on $IOS_DESTINATION")

declare -a SPM_SCHEMES=( 
    "TealiumPrismCore"
    "TealiumPrismLifecycle"
    "TealiumPrismMomentsAPI"
)

declare -a SPM_DESTINATIONS=(
    "generic/platform=iOS"
    "generic/platform=iOS Simulator"
    "generic/platform=tvOS"
    "generic/platform=tvOS Simulator"
    "generic/platform=macOS"
    "generic/platform=watchOS"
    "generic/platform=watchOS Simulator"
)

# Test SPM Schemes build
cd ..
for SCHEME in "${SPM_SCHEMES[@]}"
do
    for DESTINATION in "${SPM_DESTINATIONS[@]}"
    do
        ./scripts/build.sh --scheme "$SCHEME" --destination "$DESTINATION" || errors+=("$SCHEME on $DESTINATION")
    done
done

if [ ${#errors[@]} -eq 0 ]; then
    echo "All builds succeeded"
else
    printf "\nBuild failed for: %s" "${errors[@]}"
    exit 1
fi