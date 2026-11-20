#!/bin/bash
# Custom script to build all targets
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

errors=()

declare -a EXAMPLE_SCHEMES=(
    "Example_iOS"
    "Example_tvOS"
    "Example_macOS"
    "Example_watchOS Watch App"
)

# An array of destinations that follow the same order as the Example Schemes.
declare -a EXAMPLE_DESTINATIONS=(
    "generic/platform=iOS Simulator"
    "generic/platform=tvOS Simulator"
    "generic/platform=macOS"
    "generic/platform=watchOS Simulator"
)

# An array of optional xcargs that follow the same order as the Example Schemes.
declare -a EXAMPLE_XCARGS=(
    ""
    ""
    "CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO"
    ""
)

# Test CocoaPods Example builds
cd ../Example || { echo "cd failure"; exit 1; }
for i in "${!EXAMPLE_SCHEMES[@]}"
do
    SCHEME="${EXAMPLE_SCHEMES[$i]}"
    DESTINATION="${EXAMPLE_DESTINATIONS[$i]}"
    XCARGS="${EXAMPLE_XCARGS[$i]}"
    XCARGS_ARG=()
    if [ -n "$XCARGS" ]; then
        XCARGS_ARG=(--xcargs "$XCARGS")
    fi
    ../scripts/build.sh --scheme "$SCHEME" --destination "$DESTINATION" "${XCARGS_ARG[@]}" || errors+=("$SCHEME on $DESTINATION")
done
cd .. || { echo "cd failure"; exit 1; }

declare -a SPM_SCHEMES=(
    "TealiumPrismCore"
    "TealiumPrismLifecycle"
    "TealiumPrismContextAPI"
    "TealiumPrismExtensions"
    "TealiumPrismJavaScriptTransformer"
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