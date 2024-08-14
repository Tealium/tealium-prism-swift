#!/bin/bash
# Use this script to run all tests for all target locally before opening a PR to make sure they all pass
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }
declare -a SCHEMES=( "CoreTests_iOS" "CoreTests_tvOS" "CoreTests_macOS" )
IOS_DESTINATION='platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro'
TVOS_DESTINATION='platform=tvOS Simulator,name=Apple TV'
MACOS_DESTINATION='platform=macOS'
for SCHEME in "${SCHEMES[@]}"
do
    if [[ $SCHEME == *'iOS'* ]]; then
        ./run_tests.sh --scheme "$SCHEME" --destination "$IOS_DESTINATION"
    elif [[ $SCHEME == *'tvOS'* ]]; then
        ./run_tests.sh --scheme "$SCHEME" --destination "$TVOS_DESTINATION"
    elif [[ $SCHEME == *'macOS'* ]]; then
        ./run_tests.sh --scheme "$SCHEME" --destination "$MACOS_DESTINATION"    
    fi
done