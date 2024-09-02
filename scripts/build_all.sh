#!/bin/bash
# Custom script to build all targets
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

SCHEME='Example_iOS'
DESTINATION='platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro'

errors=()

./build.sh --scheme "$SCHEME" --destination "$DESTINATION" || errors+=("$SCHEME")


if [ ${#errors[@]} -eq 0 ]; then
    echo "All builds succeeded"
else
    echo "Some builds failed for schemes:" "${errors[@]}"
    exit 1
fi