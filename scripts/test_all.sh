#!/bin/bash
# Use this script to run all tests for all target locally before opening a PR to make sure they all pass
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }
declare -a SCHEMES=( 
    "CoreTests_iOS"
    "CoreTests_tvOS"
    "CoreTests_macOS"
    "EndToEndTests_iOS"
    "EndToEndTests_tvOS"
    "EndToEndTests_macOS"
    "DelegateProxyTests_iOS"
    "LifecycleTests_iOS" 
)
IOS_DESTINATION='platform=iOS Simulator,OS=17.5,name=iPhone 15 Pro'
TVOS_DESTINATION='platform=tvOS Simulator,name=Apple TV'
MACOS_DESTINATION='platform=macOS'

errors=()

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
        PLATFORM="$2"
        shift # past argument
        shift # past value
        ;;
        --*|-*)
        echo "Unknown option $1"
        exit 1
        ;;
        *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# Initialize an empty array to store filtered elements
declare -a filtered=()

if [ -z "$PLATFORM" ]
then
    filtered=( "${SCHEMES[@]}" )
else
    echo "Testing Schemes ending with $PLATFORM"
    shopt -s nocasematch
    # Iterate over each element in the array
    for item in "${SCHEMES[@]}"; do
    # Check if the element matches the pattern
    if [[ $item == *"_${PLATFORM}" ]]; then
    # If the element matches the pattern, add it to the filtered array
    filtered+=("$item")
    fi
    done
    shopt -u nocasematch
fi

echo "Testing Schemes: ${filtered[*]}"

for SCHEME in "${filtered[@]}"
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