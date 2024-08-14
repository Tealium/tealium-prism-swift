#!/bin/bash
# Custom script to build a specific target
cd "$(dirname "$0")" || { echo "cd failure"; exit 1; }

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--scheme)
        SCHEME="$2"
        shift # past argument
        shift # past value
        ;;
        -d|--destination)
        DESTINATION="$2"
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
if [ -z "$SCHEME" ]
then
    echo "--scheme is NULL, make sure to pass it"
    exit 1
fi
if [ -z "$DESTINATION" ]
then
    echo "--destination is NULL, make sure to pass it"
    exit 1
fi
cd ../Example || { echo "cd failure"; exit 1; }
rm -rf build && bundle exec fastlane run xcodebuild scheme:"$SCHEME" destination:"$DESTINATION"