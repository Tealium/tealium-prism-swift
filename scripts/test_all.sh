#!/bin/bash
# Use this script to run all tests for all target locally before opening a PR to make sure they all pass
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }
declare -a SCHEMES=( "CoreTests_iOS" "CoreTests_tvOS" "CoreTests_macOS" "DelegateProxyTests_iOS" "LifecycleTests_iOS")
IOS_DESTINATION='platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro'
TVOS_DESTINATION='platform=tvOS Simulator,name=Apple TV'
MACOS_DESTINATION='platform=macOS'

errors=()
for SCHEME in "${SCHEMES[@]}"
do
    if [[ $SCHEME == *'iOS'* ]]; then
        ./run_tests.sh --scheme "$SCHEME" --destination "$IOS_DESTINATION" || errors+=("$SCHEME")
    elif [[ $SCHEME == *'tvOS'* ]]; then
        ./run_tests.sh --scheme "$SCHEME" --destination "$TVOS_DESTINATION" || errors+=("$SCHEME")
    elif [[ $SCHEME == *'macOS'* ]]; then
        ./run_tests.sh --scheme "$SCHEME" --destination "$MACOS_DESTINATION" || errors+=("$SCHEME")
    fi
done

if [ ${#errors[@]} -eq 0 ]; then
    echo "All tests succeeded"
else
    echo "Some tests failed for schemes:" "${errors[@]}"
    exit 1
fi