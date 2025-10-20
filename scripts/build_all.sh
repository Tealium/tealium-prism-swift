#!/bin/bash
# Custom script to build all targets
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

EXAMPLE_SCHEME='Example_iOS'
IOS_DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro'

errors=()

# Test CocoaPods Example build
cd ../Example && ../scripts/build.sh --scheme "$EXAMPLE_SCHEME" --destination "$IOS_DESTINATION" || errors+=("$EXAMPLE_SCHEME on $IOS_DESTINATION")

declare -a SPM_SCHEMES=( 
    "TealiumPrismCore"
    "TealiumPrismLifecycle"
)

declare -a SPM_DESTINATIONS=(
    "platform=iOS Simulator,name=iPhone 16 Pro"
    "platform=tvOS Simulator,OS=18.5,name=Apple TV"
    "platform=macOS"
    "platform=watchOS Simulator,name=Apple Watch Series 10 (42mm)"
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