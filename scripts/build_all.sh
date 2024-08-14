#!/bin/bash
# Custom script to build all targets
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

SCHEME='Example_iOS'
DESTINATION='platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro'

./build.sh --scheme "$SCHEME" --destination "$DESTINATION"
